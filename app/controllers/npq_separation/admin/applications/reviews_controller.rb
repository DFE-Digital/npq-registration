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
                                    .merge(search_scope).order("applications.created_at DESC")

          @pagy, @applications = pagy(applications, limit: 9)
        end

        def show
          @application = Application.find(params[:id])
        end

      private

        def employment_types
          %w[
            hospital_school
            lead_mentor_for_accredited_itt_provider
            local_authority_supply_teacher
            local_authority_virtual_school
            young_offender_institution
            other
          ]
        end

        def filter_params
          params.permit %i[
            employment_type
            referred_by_return_to_teaching_adviser
            cohort_id
          ]
        end

        def review_scope
          Application.where(employment_type: employment_types)
                     .or(Application.where(referred_by_return_to_teaching_adviser: "yes"))
        end

        def filter_scope
          Application.where(filter_params.compact_blank)
        end

        def search_scope
          AdminService::ApplicationsSearch.new(q: params[:q]).call
        end
      end
    end
  end
end
