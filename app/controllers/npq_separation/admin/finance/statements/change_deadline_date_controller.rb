# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Finance
      module Statements
        class ChangeDeadlineDateController < NpqSeparation::AdminController
          before_action :set_statement, :set_service

          def create
            if @service.change
              flash[:success] = "Declaration deadline changed"
              redirect_to npq_separation_admin_finance_statement_path(@statement)
            else
              render :show, status: :unprocessable_entity
            end
          end

        private

          def set_statement
            @statement = Statement.find(params[:id])
          end

          def set_service
            @service = ::Statements::ChangeDeadlineDate.new(statement: @statement, deadline_date:)
          end

          def deadline_date
            return unless statement_params["deadline_date(1i)"].present? &&
              statement_params["deadline_date(2i)"].present? &&
              statement_params["deadline_date(3i)"].present?

            Date.new(statement_params["deadline_date(1i)"].to_i, statement_params["deadline_date(2i)"].to_i, statement_params["deadline_date(3i)"].to_i)
          rescue Date::Error
            nil
          end

          def statement_params
            params.fetch(:statements_change_deadline_date, {}).permit(:deadline_date)
          end
        end
      end
    end
  end
end
