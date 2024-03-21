class TsfPrimaryAttributsSynchronizationJob < ApplicationJob
  queue_as :default
  def perform
    applications = Application.where.not(number_of_pupils: 0)
                          .or(Application.where.not(primary_establishment: false))
                          .or(Application.where.not(tsf_primary_plus_eligibility: false))
                          .limit(2000)
    Ecf::TsfMassDataFieldUpdater.new(applications:).call
  end
end
