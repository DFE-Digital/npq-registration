# frozen_string_literal: true

module NpqSeparation::Admin
  module Finance
    module Statements
      class VoidedController < NpqSeparation::AdminController
        def index
          @statement = Statement.includes(declarations: :application).find(params[:id])
          @voided_declarations = @statement.declarations.where(state: "voided")
        end
      end
    end
  end
end
