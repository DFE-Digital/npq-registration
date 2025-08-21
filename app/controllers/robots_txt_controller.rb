class RobotsTxtController < PublicPagesController
  def show
    # See https://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file

    respond_to do |format|
      format.text do
        if Rails.env.production?
          render :production_robots
        else
          render :non_production_robots
        end
      end
      format.any { head :not_found }
    end
  end
end
