# frozen_string_literal: true

# Provides a :versioned_environment task dependency for rake tasks so that track whodunnit for one of tasks

# Usage:
#   task :my_task => :versioned_environment do
#     # Database changes here will have whodunnit set, changes made to other records
#     # That have has_paper_trail enabled will not have whodunnit to the rake task name while the task is running
#     # Instead they will continue to be set to the user who made the change which we want for auditing purposes
#   end

desc "Load Rails environment and set PaperTrail whodunnit for audit trail"
task versioned_environment: :environment do
  next unless defined?(PaperTrail)

  # Get the top-level task that was invoked from the command line
  parent_task = Rake.application.top_level_tasks.first

  next if parent_task.blank?

  PaperTrail.request.whodunnit = parent_task
end
