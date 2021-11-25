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

    def handle_game_command
      args = event.command_args
      gametype = args.shift
      if gametype == "mode"
        if update_allowed?
          update_game_type(args)
        else
          client.send_message "Permission denied."
        end
      else
        announce_game_modes
      end
    end

    def update_allowed?
      event.user == client.channel.name
    end

    def update_game_type(args)
      game = args[0]
      client.memory.store("game", game)
      client.send_message "Game set to '#{game}'"
    end

    def announce_game_modes
      game = client.memory.retrieve("game")
      client.send_message "#{client.channel.name}'s game: #{game}; available: #{Game.modes.join(', ')}"
    end
  end
end
