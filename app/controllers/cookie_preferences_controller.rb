class CookiePreferencesController < ApplicationController
  def create
    @form = Questionnaires::CookiePreferences.new(cookie_preferences_params)

    if @form.valid?
      cookies["consented-to-cookies"] = {
        value: cookie_preferences_params[:consent],
        expires: 1.year.from_now,
      }

      respond_to do |format|
        format.json do
          render json: {
            status: "ok",
            message: %(You’ve #{cookie_preferences_params[:consent] == 'accept' ? 'accepted' : 'rejected'} analytics cookies.),
          }
        end

        format.html do
          flash[:success] = "You’ve set your cookie preferences."
          redirect_to "/cookies"
        end
      end

    else
      render :new, status: :unprocessable_entity
    end
  end

private

  def cookie_preferences_params
    params.require(:cookie_preferences).permit(:consent)
  end
end
