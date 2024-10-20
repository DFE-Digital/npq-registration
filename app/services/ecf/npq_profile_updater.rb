module Ecf
  class NpqProfileUpdater
    prepend Base

    attr_reader :application

    def initialize(application:)
      @application = application
    end

    def call
      profile = External::EcfAPI::NpqProfile.find(application.ecf_id).first
      profile.eligible_for_funding = application.eligible_for_funding
      profile.funding_eligiblity_status_code = application.funding_eligiblity_status_code
      profile.teacher_catchment = application.teacher_catchment
      profile.teacher_catchment_country = application.teacher_catchment_country
      profile.save
    end

    def tsf_data_field_update
      return if Feature.ecf_api_disabled?

      profile = External::EcfAPI::NpqProfile.find(application.ecf_id).first
      profile.primary_establishment = application.primary_establishment
      profile.number_of_pupils = application.number_of_pupils
      profile.tsf_primary_plus_eligibility = application.tsf_primary_plus_eligibility
      profile.save
    end
  end
end
