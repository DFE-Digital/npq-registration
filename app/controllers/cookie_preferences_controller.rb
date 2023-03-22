class CookiePreferencesController < ApplicationController
  def create
    @form = Forms::CookiePreferences.new(cookie_preferences_params)

    if @form.valid?
      cookies["consented-to-cookies"] = {
        value: cookie_preferences_params[:consent],
        expires: 1.year.from_now,
      }
      cookies["hide-cookies-banner"] = {
        value: "0",
        expires: 1.year.from_now,
      }

      redirect_back(fallback_location: "/")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def hide
    cookies["hide-cookies-banner"] = {
      value: "1",
      expires: 1.year.from_now,
    }

    redirect_back(fallback_location: "/")
  end

private

  def cookie_preferences_params
    params.require(:cookie_preferences).permit(:consent)
  end
end
