# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

# Workaround for https://github.com/rswag/rswag/issues/359
if defined? RSpec
  RSpec.configure do |config|
    config.rswag_dry_run = false
  end
end

Rails.application.load_tasks

# these tasks are redefined in lib/tasks/yarn_overrides.rake to allow installing with --ignore-scripts
Rake::Task["yarn:install"].clear
Rake::Task["javascript:install"].clear
Rake::Task["css:install"].clear

load "lib/tasks/yarn_overrides.rake"

task default: ["lint:ruby", "lint:scss", "spec"]

Knapsack.load_tasks if defined?(Knapsack)
