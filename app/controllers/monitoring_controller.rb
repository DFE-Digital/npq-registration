class MonitoringController < ActionController::Base
  def healthcheck
    render json: { status: "OK", git_commit_sha: ENV["GIT_COMMIT_SHA"], docker_image_id: ENV["DOCKER_IMAGE_ID"] }
  end
end
