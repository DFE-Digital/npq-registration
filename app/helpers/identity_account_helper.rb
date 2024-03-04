module IdentityAccountHelper
  def link_to_identity_account(redirect_uri, text: "DfE Identity account", classes: "")
    govuk_link_to text, IdentityAccountLink.new(redirect_uri).build, class: classes
  end

  def identity_link_uri(redirect_uri)
    IdentityAccountLink.new(redirect_uri).build
  end

  # rubocop:disable Rails/HelperInstanceVariable
  class IdentityAccountLink
    def initialize(redirect_uri)
      @redirect_uri = redirect_uri
    end

    def build
      uri = URI.join(tra_oidc_domain, "/account")
      uri.query = URI.encode_www_form({
        "client_id" => tra_oidc_client_id,
        "redirect_uri" => @redirect_uri,
        "sign_out_uri" => sign_out_uri,
      })

      uri.to_s
    end

  private

    def tra_oidc_domain
      ENV.fetch("TRA_OIDC_DOMAIN")
    end

    def tra_oidc_client_id
      ENV.fetch("TRA_OIDC_CLIENT_ID")
    end

    def sign_out_uri
      parsed_redirect_uri = URI.parse(@redirect_uri)
      uri_class = parsed_redirect_uri.scheme == "https" ? URI::HTTPS : URI::HTTP
      base_url = uri_class.build(host: parsed_redirect_uri.host, port: parsed_redirect_uri.port).to_s

      "#{base_url}/sign-out"
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
