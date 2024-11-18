# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class TrainingStatusesController < NpqSeparation::AdminController
        before_action :set_application

        def edit
        end

        def update
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
