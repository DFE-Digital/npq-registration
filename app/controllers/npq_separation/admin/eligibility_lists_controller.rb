class NpqSeparation::Admin::EligibilityListsController < NpqSeparation::AdminController
  before_action :require_super_admin
  before_action :set_service
  before_action :set_variables

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

  def set_variables
    @pp50_schools_legacy_count = PP50_SCHOOLS_URN_HASH.count
    @pp50_schools_last_updated_at = EligibilityList::Pp50School.last_updated_at || Date.new(2025, 8, 18)
    @pp50_fe_legacy_count = PP50_FE_UKPRN_HASH.count
    @pp50_fe_last_updated_at = EligibilityList::Pp50FurtherEducation.last_updated_at || Date.new(2025, 8, 18)
    @childminders_legacy_count = CHILDMINDERS_OFSTED_URN_HASH.count
    @childminders_last_updated_at = EligibilityList::Childminder.last_updated_at || Date.new(2025, 8, 29)
    @ey_schools_legacy_count = EY_OFSTED_URN_HASH.count
    @ey_schools_last_updated_at = EligibilityList::DisadvantagedEarlyYearsSchool.last_updated_at || Date.new(2025, 8, 18)
    @la_nurseries_legacy_count = LA_DISADVANTAGED_NURSERIES.count
    @la_nurseries_last_updated_at = EligibilityList::LocalAuthorityNursery.last_updated_at || Date.new(2025, 8, 18)
    @rise_schools_legacy_count = FundingEligibilityData.new.rise_urns.count
    @rise_schools_last_updated_at = EligibilityList::RiseSchool.last_updated_at || Date.new(2025, 9, 29)
  end
end
