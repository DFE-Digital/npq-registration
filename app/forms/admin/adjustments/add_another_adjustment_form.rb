# frozen_string_literal: true

module Admin::Adjustments
  class AddAnotherAdjustmentForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement
    attribute :add_another

    validates_inclusion_of :add_another, in: %w[yes no]

    delegate :new_npq_separation_admin_finance_statement_adjustment_path,
             :npq_separation_admin_finance_statement_path,
             to: :"Rails.application.routes.url_helpers"

    def adding_another_adjustment?
      add_another == "yes"
    end
  end
end
