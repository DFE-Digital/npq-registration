# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Finance
      module Contracts
        class ChangePerParticipantController < NpqSeparation::AdminController
          before_action :require_super_admin
          before_action :set_contract, :set_statement, :set_service

          def create
            if @service.valid?
              render :confirm
            else
              render :show, status: :unprocessable_entity
            end
          end

          def confirmed
            if @service.change
              flash[:success] = "#{@service.contract.course.name} payment per participant changed" \
                " for all #{@service.contract.statement.lead_provider.name} contracts" \
                " in the #{@service.contract.statement.cohort.start_year} cohort from #{@service.start_date.to_fs(:govuk_approx)} onwards"
              redirect_to npq_separation_admin_finance_statement_path(@statement)
            else
              render :show, status: :unprocessable_entity
            end
          end

        private

          def set_contract
            @contract = Contract.find(params[:id])
          end

          def set_statement
            @statement = @contract.statement
          end

          def set_service
            @service = ::Contracts::ChangePerParticipant.new(contract: @contract, per_participant:)
          end

          def per_participant
            params.fetch(:contracts_change_per_participant, {})[:per_participant]
          end
        end
      end
    end
  end
end
