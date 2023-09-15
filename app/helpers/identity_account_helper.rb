module IdentityAccountHelper
  def tra_oidc_domain
    ENV.fetch("TRA_OIDC_DOMAIN")
  end

  def tra_oidc_client_id
    ENV.fetch("TRA_OIDC_CLIENT_ID")
  end

  def link_to_identity_account(redirect_uri)
    encoded_redirect_uri = CGI.escape(redirect_uri)

    sign_out_uri = "http://localhost:3000/sign-out"
    encoded_sign_out_uri = CGI.escape(sign_out_uri)

    "#{tra_oidc_domain}/account?client_id=#{tra_oidc_client_id}&redirect_uri=#{encoded_redirect_uri}&sign_out_uri=#{encoded_sign_out_uri}"
  end
end
