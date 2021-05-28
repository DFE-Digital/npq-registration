module Forms
  class CookiePreferences
    include ActiveModel::Model

    attr_accessor :consent, :return_path
  end
end
