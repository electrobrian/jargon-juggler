#!/bin/sh
export BOT_MODE=development \
BOT_LOGLEVEL=debug
. twitch-env.sh
bundle exec ruby -r ./lib/jargonjuggler.rb -e JargonJuggler::Bot.new.run
