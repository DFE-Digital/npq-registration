# frozen_string_literal: true

module NpqSeparation::Admin
  module Finance
    module Statements
      class PaymentAuthorisationsController < NpqSeparation::AdminController
        before_action :set_statement
        before_action :set_payment_authorisation_form

        def new; end

        def create
          if @payment_authorisation_form.save_form
            redirect_to npq_separation_admin_finance_statement_path(@statement)
          else
            render :new, status: :unprocessable_entity
          end
        end

      private

        def set_payment_authorisation_form
          @payment_authorisation_form = ::Statements::PaymentAuthorisationForm
            .new(@statement, form_params)
        end

        def form_params
          params.fetch(:statements_payment_authorisation_form, {}).permit(:checks_done)
        end

        def set_statement
          @statement = Statement.find(params[:id])
        end
      end
    end
  end
end
