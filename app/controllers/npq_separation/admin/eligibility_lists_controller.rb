class NpqSeparation::Admin::EligibilityListsController < NpqSeparation::AdminController
  before_action :require_super_admin
  before_action :set_service

  def create
    entries_loaded = @service.call

    if @service.errors.any?
      render :show
    else
      flash[:success] = "Eligibility list updated - #{entries_loaded} entries loaded"
      redirect_to npq_separation_admin_eligibility_lists_path
    end
  end

private

  def set_service
    @service = EligibilityLists::Update.new(params.fetch(:eligibility_lists_update, {}).permit(:eligibility_list_type, :file))
  end
end
