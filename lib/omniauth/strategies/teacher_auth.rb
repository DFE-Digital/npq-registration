module Omniauth
  module Strategies
    class TeacherAuth < OmniAuth::Strategies::OpenIDConnect
      NAME = :teacher_auth

      option :name, NAME
      option :pkce, true
      option :discovery, true
      option :send_scope_to_token_endpoint, false

      # TeacherAuth scopes: openid, email, profile, teaching_record
      option :scope, %i[email openid profile teaching_record].join(" ")
    end
  end
end
