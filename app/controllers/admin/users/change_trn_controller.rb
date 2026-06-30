# frozen_string_literal: true

module Admin::Users
  class ChangeTrnController < AdminController
    before_action :set_user, :set_service

    def create
      if @change_trn.change_trn
        redirect_to admin_user_path(@user)
      else
        render :show, status: :unprocessable_content
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
