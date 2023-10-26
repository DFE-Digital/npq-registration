module Ecf
  class NpqProfileUpdater
    attr_reader :application

    def initialize(application:)
      @application = application
    end

    def call
      profile = External::EcfApi::NpqProfile.find(application.ecf_id).first
      profile.eligible_for_funding = application.eligible_for_funding
      profile.funding_eligiblity_status_code = application.funding_eligiblity_status_code
      profile.teacher_catchment = application.teacher_catchment
      profile.teacher_catchment_country = application.teacher_catchment_country
      profile.save
    end
  end
end
