module NpqSeparation
  module Admin
    module Applications
      class DeclarationsController < NpqSeparation::AdminController
        def index
          @application = Application.find(params[:id])

          @declarations = @application.declarations
                                      .includes(:lead_provider, :cohort, :participant_outcomes, :statements, :delivery_partner, :secondary_delivery_partner, :versions)
                                      .order(created_at: :asc, id: :asc)
        end
      end
    end
  end
end
