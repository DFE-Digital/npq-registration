class NpqSeparation::Admin::DeliveryPartnersController < NpqSeparation::AdminController
  before_action :set_existing_delivery_partner, only: %i[edit show]
  before_action :set_delivery_partner, only: %i[create continue update]
  before_action :set_similarly_named_delivery_partners, only: %i[create continue update]
  before_action :set_continue_form, only: %i[create continue update]

  def index
    @pagy, @delivery_partners = pagy(scope, limit: 10)
  end

  def new
    @delivery_partner = DeliveryPartner.new
  end

  def continue
    if @continue_form.valid?
      save_delivery_partner if @continue_form.continue?
      redirect_to action: :index
    else
      render :similar, status: :unprocessable_entity
    end
  end

  def create
    if @delivery_partner.name.present? &&
        @delivery_partner.name_changed? &&
        DeliveryPartner.name_similar_to(@delivery_partner.name).any?
      render :similar
    elsif save_delivery_partner
      redirect_to action: :index
    else
      render :new
    end
  end

  def show
    @delivery_partnerships_by_lead_provider =
      @delivery_partner.delivery_partnerships
      .includes(:lead_provider, :cohort)
      .order("cohorts.start_year DESC")
      .group_by(&:lead_provider)
  end

  def edit
    # empty method, because rubocop will complain in the before_action otherwise
  end

  def update
    if @delivery_partner.name.present? &&
        @delivery_partner.name_changed? &&
        DeliveryPartner.name_similar_to(@delivery_partner.name).any?
      render :similar
    elsif save_delivery_partner
      redirect_to action: :index
    else
      render :edit
    end
  end

private

  def save_delivery_partner
    message = @delivery_partner.persisted? ? "Delivery partner updated" : "Delivery partner created"
    @delivery_partner.save.tap do |success| # rubocop:disable Rails/SaveBang - result of save is used by caller
      flash[:success] = message if success
    end
  end

  def delivery_partners_params
    params.require(:delivery_partner).permit(
      :name,
      delivery_partnerships_attributes: %i[
        id
        lead_provider_id
        cohort_id
        _destroy
      ],
    )
  end

  def continue_params
    params.permit(continue_form: [:continue])[:continue_form] || {}
  end

  def scope
    AdminService::DeliveryPartnersSearch.new(q: params[:q]).call
  end

  def set_existing_delivery_partner
    @delivery_partner = DeliveryPartner.find(params[:id])
  end

  def set_delivery_partner
    @delivery_partner = if params[:id]
                          DeliveryPartner.find(params[:id]).tap do |delivery_partner|
                            delivery_partner.assign_attributes(delivery_partners_params)
                          end
                        else
                          DeliveryPartner.new(delivery_partners_params)
                        end
  end

  def set_similarly_named_delivery_partners
    return [] if params.dig(:delivery_partner, :name).blank?

    @similarly_named_delivery_partners = DeliveryPartner.name_similar_to(params.dig(:delivery_partner, :name)).where.not(id: @delivery_partner&.id)
  end

  def set_continue_form
    @continue_form = Admin::DeliveryPartners::ContinueForm.new(continue_params)
  end
end
