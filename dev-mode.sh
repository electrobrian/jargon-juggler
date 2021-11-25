#!/bin/bash
env $(<env.sh) bundle exec ruby -r ./lib/jargonjuggler.rb -e JargonJuggler::Bot.new.run
