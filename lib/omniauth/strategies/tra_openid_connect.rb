module Omniauth
  module Strategies
    class TraOpenidConnect < OmniAuth::Strategies::OpenIDConnect
      NAME = :tra_openid_connect
      option :name, NAME
      option :pkce, true
      option :discovery, true

      # This is a space separated string, comma separated will fail
      option :scope, %i[email openid profile trn].join(" ")

      def authorize_uri
        force_login_prompt? ? "#{super}&prompt=login" : super
      end

    private

      def force_login_prompt?
        request.session["clear_tra_login"] == true
      end
    end
  end
end
