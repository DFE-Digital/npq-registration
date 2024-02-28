module API
  class BaseController < ApplicationController
    before_action :authenticate_request!
    before_action -> { request.format = :json }
  end
end
