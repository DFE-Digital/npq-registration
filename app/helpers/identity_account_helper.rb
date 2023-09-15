module IdentityAccountHelper
  def tra_oidc_domain
    ENV.fetch("TRA_OIDC_DOMAIN")
  end

  def tra_oidc_client_id
    ENV.fetch("TRA_OIDC_CLIENT_ID")
  end

  def link_to_identity_account(redirect_uri)

    parsed_redirect_uri = URI.parse(redirect_uri)
    base_url = if parsed_redirect_uri.scheme == 'https'
                 URI::HTTPS.build(host: parsed_redirect_uri.host, port: parsed_redirect_uri.port).to_s
               else
                 URI::HTTP.build(host: parsed_redirect_uri.host, port: parsed_redirect_uri.port).to_s
               end

    sign_out_uri = "#{base_url}/sign-out"

    uri = URI.join(tra_oidc_domain, "/account")
    uri.query = URI.encode_www_form({
      'client_id' => tra_oidc_client_id,
      'redirect_uri' => redirect_uri,
      'sign_out_uri' => sign_out_uri
    })

    uri.to_s
  end
end
