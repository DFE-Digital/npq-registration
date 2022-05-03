class PrivateChildcareProvidersController < ApplicationController
  def index
    @private_childcare_providers = PrivateChildcareProvider
      .open
      .search_by_urn(params[:name])
      .limit(100)
  end
end
