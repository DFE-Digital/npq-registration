class PrivateChildcareProvidersController < ApplicationController
  def index
    private_childcare_providers = PrivateChildcareProvider
      .search_by_urn(params[:name])
      .limit(100)

    render(json: PrivateChildcareProviderSerializer.render(private_childcare_providers))
  end
end
