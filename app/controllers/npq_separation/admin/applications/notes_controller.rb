# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class NotesController < NpqSeparation::AdminController
        before_action :set_application

        def edit
          @return_path = request.referer || npq_separation_admin_application_path(@application)
        end

        def update
          if @application.update(notes_params)
            flash[:success] = "Notes updated."
            redirect_to return_path_param
          else
            render :edit
          end
        end

      private

        def notes_params
          params.require(:application).permit(:notes)
        end

        def return_path_param
          params.permit(:return_path)[:return_path]
        end

        def set_application
          @application = Application.find(params[:id])
        end
      end
    end
  end
end
