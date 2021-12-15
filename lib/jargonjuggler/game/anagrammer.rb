module JargonJuggler
    module Game
        class Anagrammer
            def initialize(client)
                @client = client
                @dictionary = {}
                File.open(File.dirname(__FILE__) + "/web2.txt") {|dict|
                    dict.each_line {|line| @dictionary[line.chomp.downcase] = true}
                }
                @faces = Regexp.new((("a".."p").to_a + ["qu"] + ("r".."z").to_a).join("|"))
                @round_timer = 60.0
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
                    faces = []
                    configuration.each {|s| s.scan(@faces) {|face| faces << face}}
                    load_board(faces)
                end
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
            NEIGHBORS = [[-1, -1], [+0, -1], [+1, -1],
                         [-1, +0],           [+1, +0],
                         [-1, +1], [+0, +1], [+1, +1]]
            def load_board(faces)
                # load the @board and assign neighbors for each cube so we can scan and validate
                width = Math.sqrt(faces.size).to_i
                @board = faces
                i = -1
                @neighbors = faces.collect {|face|
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
            def present?(word)
                chunks = word.scan(@faces)
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
