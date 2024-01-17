module Api
  class BaseController < ApplicationController

    private

    def current_lead_provider
      current_lead_provider ||= LeadProvider.where(ecf_id: request.authorization.to_s.split("Bearer ").last).first!
    end

  end
end
