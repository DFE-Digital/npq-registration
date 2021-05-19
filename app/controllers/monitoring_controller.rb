class MonitoringController < ActionController::Base
  def healthcheck
    respond_to do |format|
      format.json do
        render json: { status: "OK" }
      end
    end
  end
end
