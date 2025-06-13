# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ReviewStatusesController < NpqSeparation::AdminController
        before_action :set_application
        helper_method :application_params

        def edit; end

        def update
          if !application_params.key?(:notes)
            render :add_note
          elsif @application.update(application_params)
            flash[:success] = "Review status updated from '#{@application.review_status_before_last_save}' to '#{@application.review_status}'."
            redirect_to npq_separation_admin_application_review_path(@application)
          else
            render :edit, status: :unprocessable_entity
          end
        end

      private

        def application_params
          params.require(:application).permit(:review_status, :notes)
        end

        def set_application
          @application = Application.find(params[:application_review_id])
        end
      end
    end
  end
end
