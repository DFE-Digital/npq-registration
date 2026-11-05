# frozen_string_literal: true

module Admin::Users
  class HistoricUsersController < AdminController
    def show
      @trn = params[:trn]
      @legacy_outcomes = LegacyPassedParticipantOutcome.where(trn: @trn).for_display

      raise ActiveRecord::RecordNotFound if @legacy_outcomes.empty?
    end
  end
end
