# frozen_string_literal: true

require "twitch/bot"
require "dotenv/load"
require_relative "jargonjuggler/version"
require_relative "jargonjuggler/join_channel_handler"
require_relative "jargonjuggler/channel_command_handler"

module JargonJuggler
  class Error < StandardError; end

  class Bot
    def initialize
      @client = Twitch::Bot::Client.new(
        channel: ENV["TWITCH_CHANNEL"],
        config: configuration,
      ) do
        register_handler(JargonJuggler::JoinChannelHandler)
        register_handler(JargonJuggler::ChannelCommandHandler)
      end
      # Monkey-patch to not reverse output lines.
      def @client.send_message(message)
        messages_queue.unshift(message) if messages_queue.last != message
      end
    end

    def run
      client.run
    end

    private

    attr_reader :client

    def adapter_class
      if development_mode?
        "Twitch::Bot::Adapter::Terminal"
      else
        "Twitch::Bot::Adapter::Irc"
      end
    end

    def configuration
      Twitch::Bot::Config.new(
        settings: {
          botname: ENV["TWITCH_USERNAME"],
          irc: {
            nickname: ENV["TWITCH_USERNAME"],
            password: ENV["TWITCH_PASSWORD"],
          },
          adapter: adapter_class,
          memory: "Twitch::Bot::Memory::Hash",
          log: {
            file: logfile,
            level: loglevel,
          },
        },
      )
    end

    def logfile
      if ENV["BOT_LOGFILE"]
        File.new(ENV["BOT_LOGFILE"], "w")
      else
        STDOUT
      end
    end

    def loglevel
      (ENV["BOT_LOGLEVEL"] || "info").to_sym
    end

    def development_mode?
      ENV["BOT_MODE"] == "development"
    end
  end
end
