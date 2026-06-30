# frozen_string_literal: true

module Admin::Finance
  module Statements
    class VoidedController < AdminController
      def index
        @statement = Statement.includes(declarations: :application).find(params[:id])
        @voided_declarations = @statement.declarations.where(state: "voided")
      end
    end
  end
end
