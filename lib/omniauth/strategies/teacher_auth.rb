module Omniauth
  module Strategies
    class TeacherAuth < OmniAuth::Strategies::OpenIDConnect
      option :name, :teacher_auth
      option :pkce, true
      option :discovery, true
      option :send_scope_to_token_endpoint, false

      # TeacherAuth scopes: openid, email, profile, teaching_record
      option :scope, %i[email openid profile teaching_record].join(" ")
    end
  end
end
