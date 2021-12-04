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
            end
            def start()
                @board = []
                @guesses = {} # guess : { guesser : time, ... }
            end
            def score()
                scores = Hash.new(0) # user : score
                @guesses.each {|guess, guessers|
                    if guessers.size == 1 and valid?(guess)
                        scores[guessers.keys.first] += points(guess)
                    end
                }
                sorted = scores.collect {|user, score| [score, user]}.sort {|rowA, rowB| rowB <=> rowA}
                @client.send_message("Scores for this round:")
                sorted.each {|score, user| @client.send_message("#{user}: #{score} points")}
            end
            def board(*configuration)
                if configuration.size == 0
                    @client.send_message("Current board: " + @board)
                else
                    faces = []
                    configuration.each {|section| section.each {|s| s.scan(@faces) {|face| faces << face}}}
                    load_board(faces)
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
            def stop()
                score()
            end

            def command(args)
                case args[0]
                when "board"
                    board(args[1..-1])
                when "score"
                    score()
                when "start"
                    start()
                when "stop"
                    stop()
                end
            end
            def valid?(word)
                return false if word.size < 4
                present?(word) and spelled?(word)
            end
            def present?(word)
                true
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
                @client.send_message("#{user} guessed #{word}")
                guesses = @guesses[word] ||= {}
                guesses[user] ||= Time.now
            end
        end
        Game["anagrammer"] = Anagrammer
    end
end