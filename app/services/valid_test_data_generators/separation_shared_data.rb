# frozen_string_literal: true

require "yaml"

module ValidTestDataGenerators
  class SeparationSharedData < ApplicationsPopulater
    class << self
      def populate(lead_provider:, cohort:)
        new(lead_provider:, cohort:).populate
      end
    end

    def populate
      return unless Rails.env.in?(%w[development review separation sandbox])

      logger.info "SeparationSharedData: Started!"

      ActiveRecord::Base.transaction do
        create_participants!
      end

      logger.info "SeparationSharedData: Finished!"
    end

  private

    def initialize(lead_provider:, cohort:, logger: Rails.logger)
      @lead_provider = lead_provider
      @cohort = cohort
      @logger = logger
      # Ignoring ASO course, is an old course which we shouldn't create data
      @courses = Course.all.reject { |c| c.identifier == "npq-additional-support-offer" }
    end

    def create_participants!
      (shared_users_data[lead_provider.name] || []).each do |user_params|
        school = School.open.order("RANDOM()").first
        user = shared_participant_identity(user_params)

        create_participant(user:, school:)
      end
    end

    def shared_participant_identity(params)
      user = if params[:ecf_id].present?
               User.find_or_initialize_by(ecf_id: params[:ecf_id])
             else
               User.find_or_initialize_by(email: params[:email])
             end

      user.ecf_id = SecureRandom.uuid if user.ecf_id.blank?
      user.update!(
        full_name: params[:name],
        email: params[:email],
        trn: params[:trn],
        date_of_birth: params[:date_of_birth],
      )

      user
    end

    def shared_users_data
      @shared_users_data ||= YAML.load_file(Rails.root.join("db/seeds/separation_shared_data.yml"))
    end
  end
end
