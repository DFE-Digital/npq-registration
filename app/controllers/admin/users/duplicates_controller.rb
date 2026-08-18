# frozen_string_literal: true

module Admin::Users
  class DuplicatesController < AdminController
    def index
      scope = User
        .where(email: nil)
        .joins(:applications)
        .where.not(applications: { lead_provider_approval_status: "rejected" })
        .distinct
        .order(created_at: :desc, id: :desc)

      @pagy, @users = pagy(scope)
      @potential_matches = User.where(email: @users.map(&:archived_email)).group_by(&:email)
    end
  end
end
