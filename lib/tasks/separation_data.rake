# frozen_string_literal: true

require "tasks/valid_test_data_generator"

namespace :lead_providers do
  desc "seed good test data for lead providers for API testing"
  task seed_statements_and_applications: :environment do
    return unless Rails.env.in?(%w[development separation])

    logger = Logger.new($stdout)
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end

    LeadProvider.all.map(&:name).each do |provider|
      ValidTestDataGenerator::LeadProviderPopulater.call(name: provider, total_schools: 10, participants_per_school: 100)
    end
  end
end
