# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Finance
      module Statements
        class ChangePaymentDateController < NpqSeparation::AdminController
          before_action :set_statement, :set_service

          def create
            if @service.change
              flash[:success] = "Output payment date changed"
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
            @service = ::Statements::ChangePaymentDate.new(statement: @statement, payment_date:)
          end

          def payment_date
            return unless statement_params["payment_date(1i)"].present? &&
              statement_params["payment_date(2i)"].present? &&
              statement_params["payment_date(3i)"].present?

            Date.new(statement_params["payment_date(1i)"].to_i, statement_params["payment_date(2i)"].to_i, statement_params["payment_date(3i)"].to_i)
          rescue Date::Error
            nil
          end

          def statement_params
            params.fetch(:statements_change_payment_date, {}).permit(:payment_date)
          end
        end
      end
    end
  end
end
