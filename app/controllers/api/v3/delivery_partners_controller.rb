module API
  module V3
    class DeliveryPartnersController < BaseController
      include Pagination

      def index
        conditions = { cohort_name:, sort: }
        delivery_partners = query(conditions:).delivery_partners

        render json: to_json(paginate(delivery_partners))
      end

      def show
        render json: to_json(delivery_partner)
      end

    private

      def query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        DeliveryPartners::Query.new(**conditions.compact)
      end

      def delivery_partner
        query.delivery_partner(ecf_id: delivery_partner_params[:ecf_id])
      end

      def cohort_name
        delivery_partner_params.dig(:filter, :cohort)
      end

      def delivery_partner_params
        params.permit(:ecf_id, :sort, filter: %i[cohort])
      end

      def sort
        delivery_partner_params[:sort]
      end

      def to_json(obj)
        DeliveryPartnerSerializer.render(obj, view: :v3, root: "data", lead_provider: current_lead_provider)
      end
    end
  end
end
