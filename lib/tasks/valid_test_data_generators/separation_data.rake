# frozen_string_literal: true

namespace :lead_providers do
  desc "seed good test data for lead providers for API testing"
  task :seed_statements_and_applications, %i[lead_provider_name number_of_participants cohort_start_year] => :environment do |_t, args|
    return unless Rails.env.in?(%w[development review separation])

    lead_provider = LeadProvider.find_by(name: args[:lead_provider_name])
    raise "LeadProvider not found: #{args[:lead_provider_name]}" if args[:lead_provider_name] && !lead_provider

    cohort = Cohort.find_by(start_year: args[:cohort_start_year])
    raise "Cohort not found: #{args[:cohort_start_year]}" if args[:cohort_start_year] && !cohort

    Array.wrap(lead_provider || LeadProvider.all).each do |lp|
      Array.wrap(cohort || Cohort.where(start_year: ..Cohort.current.start_year)).each do |c|
        ValidTestDataGenerators::ApplicationsPopulater.populate(lead_provider: lp, cohort: c, number_of_participants: args[:number_of_participants]&.to_i || 100)
        ValidTestDataGenerators::StatementsPopulater.populate(lead_provider: lp, cohort: c)
      end
    end
  end
end
