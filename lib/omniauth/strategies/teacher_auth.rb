module Omniauth
  module Strategies
    class TeacherAuth < OmniAuth::Strategies::OpenIDConnect
      NAME = :teacher_auth
      TOKEN_KEY = "id_token_hint".freeze

      option :name, NAME
      option :pkce, true
      option :discovery, true
      option :send_scope_to_token_endpoint, false

      # TeacherAuth scopes: openid, email, profile, teaching_record
      option :scope, %i[email openid profile teaching_record offline_access].join(" ")

      def encoded_post_logout_redirect_uri
        return unless options.post_logout_redirect_uri

        logout_uri_params = {
          "post_logout_redirect_uri" => options.post_logout_redirect_uri,
        }

        if query_string.present?
          query_params = CGI.parse(query_string[1..])
          logout_uri_params[TOKEN_KEY] = query_params[TOKEN_KEY].first if query_params.key?(TOKEN_KEY)
        end

        URI.encode_www_form(logout_uri_params)
      end
    end
  end
end
