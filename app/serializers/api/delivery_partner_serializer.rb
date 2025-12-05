module API
  class DeliveryPartnerSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "delivery-partner" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      view :v3 do
        field(:name)
        field(:cohort) do |object, options|
          object.cohorts_for_lead_provider(options[:lead_provider])
                .map(&:start_year)
                .uniq
                .sort
        end
        field(:created_at)
        field(:updated_at)
      end
    end

    view :v3 do
      association :attributes, blueprint: AttributesSerializer, view: :v3 do |delivery_partner|
        delivery_partner
      end
    end
  end
end
