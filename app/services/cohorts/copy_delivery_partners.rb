module Cohorts
  class CopyDeliveryPartners
    def initialize(cohort)
      @cohort = cohort
    end

    def copy
      return if previous_cohort.nil?

      previous_partnerships.find_each do |partnership|
        @cohort.delivery_partnerships.create!(
          lead_provider_id: partnership.lead_provider_id,
          delivery_partner_id: partnership.delivery_partner_id,
        )
      end
    end

  private

    def previous_cohort
      @previous_cohort ||= Cohort.order_by_latest.prior_to(@cohort).first
    end

    def previous_partnerships
      return DeliveryPartnership.none if previous_cohort.nil?

      DeliveryPartnership.where(cohort_id: previous_cohort.id)
    end
  end
end
