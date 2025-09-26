class NpqSeparation::Admin::EligibilityListsController < NpqSeparation::AdminController
  before_action :require_super_admin
  before_action :set_service
  before_action :set_variables

  def create
    @service.call

    flash[:success] = "Eligibility list updated successfully" unless @service.errors.any?
    render :show
  end

private

  def set_service
    @service = EligibilityLists::Update.new(params.fetch(:eligibility_lists_update, {}).permit(:eligibility_list_type, :file))
  end

  def set_variables
    @pp50_schools = PP50_SCHOOLS_URN_HASH.keys
    @pp50_schools_last_updated_at = Date.new(2025, 8, 18)

    @pp50_fe = PP50_FE_UKPRN_HASH.keys
    @pp50_fe_last_updated_at = Date.new(2025, 8, 18)

    @childminders = CHILDMINDERS_OFSTED_URN_HASH.keys
    @childminders_last_updated_at = Date.new(2025, 8, 29)

    @ey_schools = EY_OFSTED_URN_HASH.keys
    @ey_schools_last_updated_at = Date.new(2025, 8, 18)

    @la_nurseries = LA_DISADVANTAGED_NURSERIES.keys
    @la_nurseries_last_updated_at = Date.new(2025, 8, 18)

    @rise_schools = FundingEligibilityData.new.rise_urns
    @rise_schools_last_updated_at = Date.new(2025, 9, 26)
  end
end
