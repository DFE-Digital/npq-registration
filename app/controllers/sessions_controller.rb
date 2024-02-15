class SessionsController < ApplicationController
  def destroy
    admin = current_admin

    sign_out_all_scopes

    if admin
      redirect_to(root_path)
    else
      redirect_to build_sign_out_uri, allow_other_host: true
    end
  end

private

  def build_sign_out_uri
    tra_domain_uri = URI.parse(ENV["TRA_OIDC_DOMAIN"])

    URI::Generic.build({
      scheme: tra_domain_uri.scheme,
      host: tra_domain_uri.host,
      port: tra_domain_uri.port,
      path: "/connect/signout",
      query: URI.encode_www_form({
        "client_id" => "register-for-npq",
        "post_logout_redirect_uri" => root_uri.to_s,
      }),
    }).to_s
  end

  def root_uri
    return "http://localhost:#{request.port}/" if request.host == "localhost"

    URI::HTTPS.build(host: request.host, path: "/")
  end
end
