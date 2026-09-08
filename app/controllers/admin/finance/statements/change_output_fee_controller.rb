# frozen_string_literal: true

module Admin::Finance
  module Statements
    class ChangeOutputFeeController < AdminController
      before_action :require_super_admin, :set_statement, :set_service

      def create
        if @service.invalid?
          render :show, status: :unprocessable_content
        elsif @service.schedule_change
          flash[:success] = "Payment run statement is being changed and declarations moved - this will take a few minutes"
          redirect_to admin_finance_statement_path(@statement)
        else
          redirect_to admin_finance_statement_path(@statement)
        end
      end

    private

      def set_statement
        @statement = Statement.find(params[:id])
      end

      def set_service
        @service = ::Statements::ChangeOutputFee.new(statement_change_params)
        @service.statement = @statement
      end

      def statement_change_params
        params
          .fetch(:statements_change_output_fee, {})
          .permit(:output_fee, :allow_payable_statement_changes)
      end
    end
  end
end
