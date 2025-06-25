class PagesController < PublicPagesController
  def show
    render template: "pages/#{params[:page]}"
  end
end
