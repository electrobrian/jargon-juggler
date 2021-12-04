module JargonJuggler
    module Game
        class Anagrammer
            def initialize(client)
                @client = client
            end
            def start()
                @board = []
                @guesses = {} # guess : { guesser : time, ... }
                @dictionary = {}
                File.open(File.dirname(__FILE__) + "/web2.txt") {|dict|
                    dict.each_line {|line| @dictionary[line.chomp.downcase] = true}
                }
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
            def stop()
                score()
            end

            def command(args)
                case args[0]
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