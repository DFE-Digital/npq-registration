# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class NotesController < NpqSeparation::AdminController
        before_action :set_application

        def edit
          referrer_path = URI(request.referer).path if request.referer
          @in_review_application = true if referrer_path =~ /review/
          @return_path = return_path(@in_review_application)
        end

        def update
          if @application.update(notes_params)
            flash[:success] = "Notes updated."
            redirect_to return_path(in_review_application_param.present?)
          else
            render :edit
          end
        end

      private

        def notes_params
          params.require(:application).permit(:notes)
        end

        def in_review_application_param
          params.permit(:in_review_application)[:in_review_application]
        end

        def return_path(in_review_application)
          if in_review_application
            npq_separation_admin_application_review_path(@application)
          else
            npq_separation_admin_application_path(@application)
          end
        end

        def set_application
          @application = Application.find(params[:id])
        end
      end
    end
  end
end
