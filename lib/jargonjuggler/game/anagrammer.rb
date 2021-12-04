module JargonJuggler
    module Game
        class Anagrammer
            def initialize(client)
                @client = client
            end
            def start()
                @board = []
            end
            def stop()
            end

            def command(args)
                @client.send_message("command #{args.inspect}")
            end
            def guess(user, text)
                word = text[/[^[:space:]]+/]
                @client.send_message("#{user} guessed #{word}")
            end
        end
        Game["anagrammer"] = Anagrammer
    end
end