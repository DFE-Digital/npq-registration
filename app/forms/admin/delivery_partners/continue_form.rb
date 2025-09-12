# frozen_string_literal: true

module Admin::DeliveryPartners
  class ContinueForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :continue
    attribute :delivery_partner

    validates_inclusion_of :continue, in: %w[yes no]

    def continue?
      continue == "yes"
    end
  end
end
