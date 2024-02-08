require_relative "game"
require_relative "game/anagrammer"

# frozen_string_literal: true

module JargonJuggler
  # This class implements the !plan command.
  class ChannelCommandHandler < Twitch::Bot::EventHandler
    def self.handled_events
      [:user_message]
    end

    def call
      if event.command? && command_aliases.include?(event.command)
        handle_game_command
      else
        handle_potential_guess
      end
    end

    private

    def command_aliases
      %w[game]
    end

    def handle_potential_guess
      curgame.guess(event.user, event.text)
    end

    def handle_game_command
      args = event.command_args
      gametype = args.shift
      if gametype == "mode"
        if update_allowed?
          update_game_type(args)
        else
          client.send_message("Permission denied.")
        end
      elsif gametype and gametype == client.memory.retrieve("game")
        curgame.command(args)
      else
        announce_game_modes
      end
    end

    def update_allowed?
      event.user == client.channel.name
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
      Game.channels[client.channel.name] || NullGame[]
    end

    def curgame=(game)
      Game.channels[client.channel.name] = game
    end

    def update_game_type(args)
      game = args[0]
      c = curgame()
      c && c.stop()
      c = self.curgame = Game[game].new(client)
      client.memory.store("game", game)
      client.send_message("Game set to '#{game}'")
      c.start()
    end

    def announce_game_modes
      game = client.memory.retrieve("game")
      client.send_message("#{client.channel.name}'s game: #{game}; available: #{Game.modes.join(', ')}")
    end
  end
end
