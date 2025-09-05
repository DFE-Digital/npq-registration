# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ReviewsController < NpqSeparation::AdminController
        helper_method :employment_types

        def index
          applications = Application.includes(:private_childcare_provider, :school, :user)
                                    .merge(review_scope)
                                    .merge(filter_scope)
                                    .merge(search_scope)
                                    .merge(funding_decision_scope)
                                    .order("applications.created_at DESC")

          @pagy, @applications = pagy(applications, limit: 9)
        end

        def show
          @application = Application.find(params[:id])
        end

      private

        def employment_types
          Application.employment_types.keys
        end

        def filter_params
          params.permit %i[
            employment_type
            eligible_for_funding
            referred_by_return_to_teaching_adviser
            cohort_id
          ]
        end

        def review_scope
          if Application.review_statuses.keys.include?(params[:review_status])
            Application.where(review_status: params[:review_status])
          else
            Application.for_manual_review
          end
        end

        def filter_scope
          Application.where(filter_params.compact_blank)
        end

        def funding_decision_scope
          return {} unless params[:has_funding_decision] == "true"

          Application.where("funded_place is not null")
        end

        def search_scope
          AdminService::ApplicationsSearch.new(q: params[:q]).call
        end
      end
    end
  end
end
