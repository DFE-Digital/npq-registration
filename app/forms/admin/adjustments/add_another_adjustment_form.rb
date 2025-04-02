# frozen_string_literal: true

module Admin::Adjustments
  class AddAnotherAdjustmentForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Rails.application.routes.url_helpers

    attribute :statement
    attribute :add_another

    validates_inclusion_of :add_another, in: %w[yes no]

    def redirect_to
      if add_another == "yes"
        new_npq_separation_admin_finance_statement_adjustment_path(statement)
      else
        npq_separation_admin_finance_statement_path(statement)
      end
    end
  end
end
