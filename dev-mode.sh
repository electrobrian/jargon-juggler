#!/bin/bash
bundle exec env $(cat env.sh) ruby -r ./lib/jargonjuggler.rb -e JargonJuggler::Bot.new.run
