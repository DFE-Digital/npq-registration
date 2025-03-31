class NpqSeparation::Admin::DeliveryPartnersController < NpqSeparation::AdminController
  def index
    scope = DeliveryPartner.all.order(name: :asc)
    @pagy, @delivery_partners = pagy(scope, limit: 10)
  end

  def new
    @delivery_partner = DeliveryPartner.new
  end

  def create
    @delivery_partner = DeliveryPartner.new(delivery_partners_params)

    if @delivery_partner.save
      flash[:success] = "Delivery partner created"
      redirect_to action: :index
    else
      render :new
    end
  end

  def edit
    @delivery_partner = DeliveryPartner.find(params[:id])
  end

  def update
    @delivery_partner = DeliveryPartner.find(params[:id])

    if @delivery_partner.update(delivery_partners_params)
      flash[:success] = "Delivery partner updated"
      redirect_to action: :index
    else
      render :edit
    end
  end

private

  def delivery_partners_params
    params.require(:delivery_partner).permit(:name)
  end
end
