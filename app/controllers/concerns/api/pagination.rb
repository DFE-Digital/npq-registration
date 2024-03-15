module API
  module Pagination
    extend ActiveSupport::Concern
    include Pagy::Backend

    included do
      rescue_from Pagy::VariableError, with: :invalid_pagination_response
    end

  private

    def paginate(scope)
      _pagy, paginated_records = pagy(scope, items: per_page, page:)

      paginated_records
    end

    def per_page
      [(page_params.dig(:page, :per_page) || default_per_page).to_i, max_per_page].min
    end

    def default_per_page
      100
    end

    def max_per_page
      3000
    end

    def page
      (page_params.dig(:page, :page) || 1).to_i
    end

    def page_params
      params.permit(page: %i[per_page page])
    end

    def invalid_pagination_response(_exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:bad_request), params: I18n.t(:invalid_page_parameters)).call }, status: :bad_request
    end
  end
end
