# frozen_string_literal: true

require "active_support/testing/time_helpers"

module ValidTestDataGenerators
  class PendingApplicationsPopulater < ApplicationsPopulater
    include ActiveSupport::Testing::TimeHelpers

    def populate
      return unless Rails.env.in?(%w[development review separation])

      logger.info "PendingApplicationsPopulater: Started!"

      ActiveRecord::Base.transaction do
        create_participants!
      end

      logger.info "PendingApplicationsPopulater: Finished!"
    end

  private

    def create_participant(school:, user:)
      course = courses.sample
      schedule = Schedule.where(cohort:, course_group: course.course_group).sample
      create_application(user, school, course, schedule)
    end
  end
end
