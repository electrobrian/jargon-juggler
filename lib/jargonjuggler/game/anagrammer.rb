# Borrowing from my old https://people.freebsd.org/~green/bonkle-0.10.tar.gz
module JargonJuggler
    module Game
        class Anagrammer
            DICE_SETS = {
                # DICE_SETS[bonkle][4 or 5] = reference test material
                "bonkle" => {
                    4 => [ %w(A A E E G N), %w(A B B J O O), %w(A C H O P S), %w(A F F K P S),
                           %w(A O O T T W), %w(C I M O T U), %w(D E I L R X), %w(D E L R V Y),
                           %w(D I S T T Y), %w(E I O S S T), %w(E E I N S U), %w(E E G H N W),
                           %w(E H R T V W), %w(E L R T T Y), %w(H I M N Qu U),%w(H L N N R Z) ],
                    5 => [ %w(Qu B J K Z X),%w(L P C E T I), %w(H O L D R N), %w(C P T E I S), %w(L R D H H O),
                           %w(E E M E E A), %w(P I R Y R R), %w(T E N C C S), %w(Y I S A F R), %w(N S S U S E),
                           %w(F I S P R Y), %w(A R F S A I), %w(N O W O U T), %w(I T E I I I), %w(H O L D R N),
                           %w(E E A E E A), %w(T O O O U T), %w(M E T O T T), %w(G R O W R V), %w(A E U G M E),
                           %w(R A A F A S), %w(E N D N N A), %w(D O N D H T), %w(T I E C L I), %w(G E N A N M) ]
                }
            }

            def initialize(client)
                @client = client
                @dictionary = {}
                File.open(File.dirname(__FILE__) + "/web2.txt") {|dict|
                    dict.each_line {|line| @dictionary[line.chomp.downcase] = true}
                }
                @grapheme_corpus = Regexp.new((("a".."p").to_a + ["qu"] + ("r".."z").to_a).join("|"))
                @dice = [] # get these from the user, generate them, pre-stored, saved and evolved, etc.
                @round_timer = 60.0
            end

            NEIGHBORS = [[-1, -1], [+0, -1], [+1, -1],
                         [-1, +0],           [+1, +0],
                         [-1, +1], [+0, +1], [+1, +1]]
            def setup_neighbors(width)
                i = -1
                @neighbors = @board.collect {|face|
                    i += 1
                    here = [i / width, i % width]
                    NEIGHBORS.collect {|offset|
                        there = [here[0] + offset[0], here[1] + offset[1]]
                        if there[0] >= 0 and there[0] < width and there[1] >= 0 and there[1] < width
                            there[1] * width + there[0]
                        else
                            nil
                        end
                    }.compact()
                }
            end

            def send(msg)
                @client.send_message(msg)
            end

            def start()
                @guesses = {} # guess : { guesser : time, ... }
                @start = Time.now
                send("Round started at #{@start}")
            end

            def score()
                scores = Hash.new(0) # user : score
                counted = {} # user : [ match, ... ] 
                @guesses.each {|guess, guessers|
                    guessers = guessers.find_all {|u, t| t >= @start and t <= @start + @round_timer}
                    if guessers.size == 1 and valid?(guess)
                        scores[guessers.first.first] += points(guess)
                        (counted[guessers.first.first] ||= []) << guess
                    end
                }
                sorted = scores.collect {|user, score| [score, user]}.sort {|rowA, rowB| rowB <=> rowA}
                left = @start + @round_timer - Time.now
                time_status = if left <= 0
                    ""
                else
                    " (#{left}s remaining)"
                end
                send("Scores for this round#{time_status}:")
                sorted.each {|score, user| send("#{user} got #{score} points for: #{counted[user].join(', ')}")}
            end

            def board(*configuration)
                if configuration.empty?
                    send("Current board: " + @board.inspect)
                else
                    dice = []
                    configuration.each {|s| s.scan(@grapheme_corpus) {|face| grapheme_corpus << face}}
                    load_board(dice)
                end
            end

            require_relative "dev_random"
            # Pull random dice (on random sides) from a defined set of dice
            class RandomDice
                # Get a set of dice.  This will raise an exception if DevRandom cannot be initialized.
                def initialize(width)
                    @dr = DevRandom.new
                    @width = width
                    reset
                end
                # Reinitialize to a full set of dice for the given board size.
                def reset
                    @dice = DICE_SETS["bonkle"][@width]
                end
                # Take random dice from the set.  With no arguments or passed 1,
                # return the single string from one die, else an Array of strings
                # of the number of dice asked for.
                def grab(count = 1)
                    if @dice.empty?
                        raise EOFError, 'selection of dice empty'
                    end
                    case count
                    when 2 .. @dice.size
                        ret = []
                        count.downto(1) {
                            pos = @dr.read(2) % @dice.size
                            die = @dice.delete_at(pos)
                            ret.push die[@dr.read(2) % 6]
                        }
                        return ret
                    when 1
                        pos = @dr.read(2) % @dice.size
                        die = @dice.delete_at(pos)
                        return die[@dr.read(2) % 6]
                    else
                        raise ArgumentError, 'bad die count'
                    end
                end
                # Are there dice left?
                def empty?
                    @dice.empty?
                end
                # Are there all the dice left?
                def full?
                    @dice.size == @width * @width
                end
            end

            def shake(width, *rest)
                width = width.to_i
                @board = RandomDice.new(width).grab(width * width)
                setup_neighbors(width)
            end

            def timer(*configuration)
              if configuration.empty?
                  send("Round timer: #{@round_timer} seconds.")
                else
                    begin
                        new_value = configuration.first.to_f
                        raise("Invalid timer.") if new_value <= 0.0
                        @round_timer = new_value
                    rescue Exception => e
                        send(e.message)
                    end
                end
            end

            def load_board(dice)
                # load the @board and assign neighbors for each cube so we can scan and validate
                width = Math.sqrt(dice.size).to_i
                @board = dice
                setup_neighbors(width)
            end

            def present?(word)
                chunks = word.scan(@grapheme_corpus)
                start_chunk = chunks.shift()
                @board.each_with_index {|face, cubeno|
                    if face == start_chunk
                        if search(chunks, cubeno, {cubeno: true})
                            return true
                        end
                    end
                }
            end
            def search(chunks, location, usemap)
                @neighbors[location].each {|neighbor|
                    unless usemap[neighbor]
                        if @board[neighbor] == chunks.first
                            rest = chunks[1..-1]
                            if rest.empty?
                                return true
                            end
                            usemap[neighbor] = true
                            if search(rest, neighbor, usemap)
                                return true
                            end
                            usemap[neighbor] = false
                        end
                    end
                }
            end
            def stop()
                score()
            end

            def command(args)
                case args.shift
                when "board"
                    board(*args)
                when "shake"
                    shake(*args)
                when /^(score|points)$/
                    score()
                when "start"
                    start()
                when "stop"
                    stop()
                when "timer"
                    timer(*args)
                end
            end
            def valid?(word)
                return false if word.size < 4
                present?(word) and spelled?(word)
            end
            def spelled?(word)
                @dictionary[word]
            end

            def points(guess)
                case guess.size
                when 4
                    1
                when 5
                    2
                when 6
                    3
                when 7
                    5
                else
                    11
                end
            end
            def guess(user, text)
                word = text[/[^[:space:]]+/].downcase
                # send("#{user} guessed #{word}")
                guesses = @guesses[word] ||= {}
                guesses[user] ||= Time.now
            end
        end
        Game["anagrammer"] = Anagrammer
    end
end
