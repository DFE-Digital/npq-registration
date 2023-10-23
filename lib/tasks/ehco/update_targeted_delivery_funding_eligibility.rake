# frozen_string_literal: true

require "rake"

namespace :ehco do
  namespace :update_targeted_delivery_funding_eligibility do
    desc "DRY RUN: Marks targeted_delivery_funding_eligibility on all EHCO NPQ applications as false"
    task dry_run: :environment do
      Application.transaction do
        Ehco::TargetedDeliveryFundingEligibilityUpdater.run

        raise ActiveRecord::Rollback
      end
    end

    desc "Marks targeted_delivery_funding_eligibility on all EHCO NPQ applications as false"
    task run: :environment do
      Ehco::TargetedDeliveryFundingEligibilityUpdater.run
    end
  end
end
