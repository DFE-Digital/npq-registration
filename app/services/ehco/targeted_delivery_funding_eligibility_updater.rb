# frozen_string_literal: true

module Ehco
  class TargetedDeliveryFundingEligibilityUpdater
    class << self
      delegate :run, to: :new
    end

    def run(logger: Logger.new($stdout))
      logger.info "Updating EHCO NPQ Applications, this may take a couple of minutes..."

      ehco_course = Course.ehco

      arel_table = Application.arel_table
      npq_applications = Application.where(course: ehco_course)
                                    .where(targeted_delivery_funding_eligibility: true)
                                    .where(arel_table[:created_at].gteq(Feature::REGISTRATION_OPEN_DATE))

      updated_count = 0

      npq_applications.find_each do |npq_application|
        logger.info "Updating EHCO NPQ Application ID##{npq_application.id}"
        npq_application.update!(targeted_delivery_funding_eligibility: false)

        updated_count += 1
      rescue StandardError => e
        logger.error "Encountered errors while updating EHCO NPQ Application #{npq_application.id}: #{e.message}"
      end

      logger.info "Updated EHCO NPQ Application count: #{updated_count}"
    end
  end
end
