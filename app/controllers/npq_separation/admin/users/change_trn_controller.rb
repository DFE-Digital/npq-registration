# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Users
      class ChangeTrnController < NpqSeparation::AdminController
        before_action :set_user, :set_service

        def create
          if @change_trn.call
            redirect_to npq_separation_admin_user_path(@user)
          else
            render :show, status: :unprocessable_entity
          end
        end

      private

        def set_user
          @user = User.find(params[:id])
        end

        def set_service
          @change_trn = Participants::ChangeTrn.new(user: @user, trn:)
        end

        def trn
          params.fetch(:participants_change_trn, {})[:trn]
        end
      end
    end
  end
end
