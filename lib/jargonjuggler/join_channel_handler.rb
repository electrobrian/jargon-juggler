require_relative "game"
require_relative "game/anagrammer"

# frozen_string_literal: true

module JargonJuggler
  class JoinChannelHandler < Twitch::Bot::EventHandler
    def call
      client.send_message("JargonJuggler initialized.")
    end

    def self.handled_events
      [:join]
    end
  end
end
