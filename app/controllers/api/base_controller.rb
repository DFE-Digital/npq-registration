module API
  class BaseController < ApplicationController
    include API::TokenAuthenticatable
  end
end
