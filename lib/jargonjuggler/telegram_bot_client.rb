require "dotenv/load"
require "telegram/bot"

require_relative "game"
require_relative "game/anagrammer"

# frozen_string_literal: true

module JargonJuggler
  class TelegramBotClient
    def run()
      Telegram::Bot::Client.run(ENV["JARGONJUGGLER_TELEGRAM_BOT_API_TOKEN"]) {|bot|
        @boards = {}
        @bumped_boards = {}
        @bot = bot
        @bot.listen {|message|
          case message
          when Telegram::Bot::Types::CallbackQuery
            if message.message.text.nil?
              # Let's play.
              @bot.api.answer_callback_query(callback_query_id: message.id,
                                             text: "Launching Jargon Juggler...")
            end
          when Telegram::Bot::Types::Message
            @chat_id = message.chat.id
            if message.text and message.text[0] != '/'
              curgame.guess(message.from, message.text)
            elsif message.text
              args = message.text[1..-1].split
              command = args[0]
              case command
              when "hello"
                @bot.api.send_game(chat_id: message.chat.id,
                                   game_short_name: "JargonJuggler",
                                   reply_to_message_id: message.message_id)
              when "mode"
                if update_allowed?
                  update_game_type(args[1])
                else
                  send_message("Permission denied.")
                end
              else
                curgame.command(args)
              end
            end
          end
        }
      }
    end

    def send_message(text)
      @bot.api.send_message(chat_id: @chat_id, text: text, parse_mode: "HTML")
    end

    def send_board(board)
      @boards[@chat_id] = send_message(board)
      @bumped_boards[@chat_id] = nil
    end

    def bump_board()
      board = @boards[@chat_id]
      return unless board
      old_bump = @bumped_boards[@chat_id]
      @bumped_boards[@chat_id] = @bot.api.copy_message(chat_id: @chat_id, from_chat_id: @chat_id, message_id: board['result']['message_id'])
      if old_bump
        @bot.api.delete_message(chat_id: @chat_id, message_id: old_bump['result']['message_id'])
      end
    end

    private

    def update_allowed?
      # event.user == client.channel.name
      true
    end

    class NullGame
      def command(args)
      end
      def guess(user, text)
      end
      def start()
      end
      def stop()
      end

      def self.[]
        @@singleton ||= NullGame.new
      end
    end

    def curgame
      Game.channels[@chat_id] || NullGame[]
    end

    def curgame=(game)
      Game.channels[@chat_id] = game
    end

    def update_game_type(game)
      c = curgame()
      c && c.stop()
      c = self.curgame = Game[game].new(self)
      send_message("Game set to '#{game}'")
      c.start()
    end
  end
end
