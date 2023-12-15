#!/bin/sh
. twitch-env.sh
bundle exec ruby -r ./lib/jargonjuggler_twitch.rb -e JargonJuggler::Bot.new.run
