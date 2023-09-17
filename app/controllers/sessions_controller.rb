class SessionsController < ApplicationController
  def destroy
    sign_out_all_scopes

    root_uri = URI::HTTP.build({
      scheme: request.protocol.chomp("://"), # "http://".chomp("://") -> "http"
      host: request.host,
      port: request.port,
      path: "/"
    })

    tra_domain_uri = URI.parse(ENV["TRA_OIDC_DOMAIN"])

    logout_uri = URI::Generic.build({
      scheme: tra_domain_uri.scheme,
      host: tra_domain_uri.host,
      port: tra_domain_uri.port, # This will be nil if not provided, and the build method will ignore it.
      path: "/connect/signout",
      query: URI.encode_www_form({
        "client_id" => "register-for-npq",
        "post_logout_redirect_uri" => root_uri.to_s
      })
    })

    redirect_to logout_uri.to_s
  end
end
