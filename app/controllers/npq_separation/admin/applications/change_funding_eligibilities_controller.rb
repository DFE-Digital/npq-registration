# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ChangeFundingEligibilitiesController < NpqSeparation::AdminController
        before_action :set_application, :set_change_funding_eligility

        def new; end

        def create
          @funding_eligibility.assign_attributes(funding_eligibility_params)

          if @funding_eligibility.change_funding_eligibility
            redirect_to npq_separation_admin_application_path(@application)
          else
            render :new, status: :unprocessable_entity
          end
        end

      private

        def set_application
          @application = Application.find(params[:id])
        end

        def set_change_funding_eligility
          @funding_eligibility =
            ::Applications::ChangeFundingEligibility.new(application: @application)
        end

        def funding_eligibility_params
          params.fetch(:change_funding_eligibility, {}).permit(:eligible_for_funding)
        end
      end
    end
  end
end
