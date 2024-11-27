# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ChangeFundingEligibilitiesController < NpqSeparation::AdminController
        before_action :set_application

        def new; end

        def create
          redirect_to npq_separation_admin_application_path(@application)
        end

      private

        def set_application
          @application = Application.find(params[:id])
        end
      end
    end
  end
end
