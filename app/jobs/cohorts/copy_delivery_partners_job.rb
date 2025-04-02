module Cohorts
  class CopyDeliveryPartnersJob < ApplicationJob
    queue_as :default

    def perform(cohort_id)
      cohort = Cohort.find(cohort_id)
      Cohorts::CopyDeliveryPartners.new(cohort).copy
    end
  end
end
