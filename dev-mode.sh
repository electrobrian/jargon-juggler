#!/bin/bash
env $(<env.sh) bundle exec ruby -r ./lib/teneggs.rb -e Teneggs::Bot.new.run
