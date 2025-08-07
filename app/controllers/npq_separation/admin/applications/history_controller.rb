# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class HistoryController < NpqSeparation::AdminController
        before_action :set_application

      private

        def set_application
          @application = Application.eager_load(:application_states).find(params[:id])
        end
      end
    end
  end
end
