require "rspec/core/rake_task"

task default: :spec
task test: %i[rubocop spec]
task(:ctags) { system("exctags -R --languages=ruby --exclude=.git --exclude=log --exclude=tmp . `bundle list --paths`") }

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
RuboCop::RakeTask.new
