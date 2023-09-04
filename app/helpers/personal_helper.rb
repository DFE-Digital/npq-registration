module PersonalHelper
  def tra_oidc_domain
    ENV.fetch("TRA_OIDC_DOMAIN")
  end

  def tra_oidc_client_id
    ENV.fetch("TRA_OIDC_CLIENT_ID")
  end

  def tra_oidc_redirect_uri
    ENV.fetch("TRA_OIDC_REDIRECT_URI")
  end
end
