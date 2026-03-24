class ErrorsController < PublicPagesController
  layout "application"

  before_action :set_format

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: "Resource not found" }, status: :not_found }
      format.all { render status: :not_found, body: nil }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
      format.all { render status: :internal_server_error, body: nil }
    end
  end

  def unprocessable_content
    respond_to do |format|
      format.html { render status: :unprocessable_content }
      format.json { render json: { error: "Unprocessable content" }, status: :unprocessable_content }
      format.all { render status: :unprocessable_content, body: nil }
    end
  end

private

  def set_format
    request.format = :json if request.original_fullpath =~ %r{^/api/(?!docs|guidance)} && request.format.html?
  end
end
