#!/bin/sh
. telegram-env.sh
bundle exec ruby -r ./lib/jargonjuggler/telegram_bot_client.rb -e JargonJuggler::TelegramBotClient.new.run
