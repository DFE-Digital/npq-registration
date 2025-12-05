# frozen_string_literal: true

namespace :lead_providers do
  desc "seed good test data for lead providers for API testing"
  task :seed_statements_and_applications, %i[lead_provider_name number_of_participants cohort_identifier] => :environment do |_t, args|
    return unless Rails.env.in?(%w[development review sandbox])

    lead_provider = LeadProvider.find_by(name: args[:lead_provider_name])
    raise "LeadProvider not found: #{args[:lead_provider_name]}" if args[:lead_provider_name] && !lead_provider

    cohort = Cohort.find_by(identifier: args[:cohort_identifier])
    raise "Cohort not found: #{args[:cohort_name]}" if args[:cohort_identifier] && !cohort

    Array.wrap(lead_provider || LeadProvider.all).each do |lp|
      Array.wrap(cohort || Cohort.where(start_year: ..Cohort.current.start_year)).each do |c|
        ValidTestDataGenerators::ApplicationsPopulater.populate(lead_provider: lp, cohort: c, number_of_participants: args[:number_of_participants]&.to_i || 100)
        ValidTestDataGenerators::PendingApplicationsPopulater.populate(lead_provider: lp, cohort: c, number_of_participants: args[:number_of_participants]&.to_i || 100)
        ValidTestDataGenerators::StatementsPopulater.populate(lead_provider: lp, cohort: c)
        ValidTestDataGenerators::SandboxSharedData.populate(lead_provider: lp, cohort: c)
      end
    end
  end
end
