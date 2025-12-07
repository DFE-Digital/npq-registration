# frozen_string_literal: true

require "rails_helper"

RSpec.describe "versioned_environment rake task", :versioning do
  let(:user) { create(:user) }

  # Helper to invoke a rake task as if it were called from the command line
  def invoke_as_top_level(task_name)
    original_top_level_tasks = Rake.application.top_level_tasks.dup
    Rake.application.instance_variable_set(:@top_level_tasks, [task_name])
    Rake::Task[:versioned_environment].reenable
    Rake::Task[task_name].invoke
  ensure
    Rake.application.instance_variable_set(:@top_level_tasks, original_top_level_tasks)
  end

  describe "tasks depending on :versioned_environment" do
    after { Rake::Task["test:versioned_task"].reenable }

    before do
      Rake::Task.define_task("test:versioned_task" => :versioned_environment) do
        User.first.update!(email: "changed_by_rake@example.com")
      end
    end

    it "sets whodunnit to the camelized task name" do
      user
      invoke_as_top_level("test:versioned_task")

      expect(PaperTrail::Version.last.whodunnit).to eq("Rake test:versioned_task")
    end
  end

  describe "tasks depending on :environment only" do
    after { Rake::Task["test:unversioned_task"].reenable }

    before do
      Rake::Task.define_task("test:unversioned_task" => :environment) do
        User.first.update!(email: "changed_without_versioning@example.com")
      end
    end

    it "does not set whodunnit" do
      user
      Rake::Task["test:unversioned_task"].invoke

      expect(PaperTrail::Version.last.whodunnit).to be_nil
    end
  end

  describe "namespaced tasks" do
    after { Rake::Task["one_off:test_paper_trail_task"].reenable }

    before do
      Rake::Task.define_task("one_off:test_paper_trail_task" => :versioned_environment) do
        User.first.update!(email: "changed_by_one_off@example.com")
      end
    end

    it "sets whodunnit with proper namespace conversion" do
      user
      invoke_as_top_level("one_off:test_paper_trail_task")

      expect(PaperTrail::Version.last.whodunnit).to eq("Rake one_off:test_paper_trail_task")
    end
  end

  describe "whodunnit scoping" do
    after do
      Rake::Task["test:first_versioned_task"].reenable
      Rake::Task["test:second_versioned_task"].reenable
    end

    before do
      Rake::Task.define_task("test:first_versioned_task" => :versioned_environment) do
        User.first.update!(email: "first_task@example.com")
      end

      Rake::Task.define_task("test:second_versioned_task" => :versioned_environment) do
        User.first.update!(email: "second_task@example.com")
      end
    end

    it "sets whodunnit for each task based on top-level task" do
      user
      invoke_as_top_level("test:first_versioned_task")
      invoke_as_top_level("test:second_versioned_task")

      versions = user.versions.last(2)
      expect(versions[0].whodunnit).to eq("Rake test:first_versioned_task")
      expect(versions[1].whodunnit).to eq("Rake test:second_versioned_task")
    end
  end
end
