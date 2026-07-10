class SessionsController < PublicPagesController
  def confirm_sign_out
    return redirect_to(root_path) unless current_user || current_admin

    @cancel_url = cancel_url
  end

  def destroy
    admin = current_admin
    user = current_user
    id_token = session[:id_token]

    sign_out_all_scopes

    if admin
      redirect_to root_path
    elsif user&.teacher_auth_provider?
      redirect_to teacher_auth_sign_out_uri(id_token), allow_other_host: true
    elsif user&.get_an_identity_provider?
      redirect_to get_an_identity_sign_out_uri, allow_other_host: true
    else
      redirect_to root_path
    end
  end

private

  # Only send the user back to the referer if it's in this domain and different to the current page.
  def cancel_url
    referer = URI.parse(request.referer.to_s)

    if referer.host == request.host && referer.path != request.path
      request.referer
    else
      root_path
    end
  rescue URI::InvalidURIError
    root_path
  end

  def get_an_identity_sign_out_uri
    tra_domain_uri = URI.parse(ENV["TRA_OIDC_DOMAIN"])

    URI::Generic.build({
      scheme: tra_domain_uri.scheme,
      host: tra_domain_uri.host,
      port: tra_domain_uri.port,
      path: "/connect/signout",
      query: URI.encode_www_form({
        "client_id" => "register-for-npq",
        "post_logout_redirect_uri" => post_logout_uri.to_s,
      }),
    }).to_s
  end

  def teacher_auth_sign_out_uri(id_token)
    "/users/auth/teacher_auth/logout?id_token_hint=#{id_token}"
  end

  def post_logout_uri
    URI.join(ENV.fetch("HOSTING_DOMAIN"), "/sign-out").to_s
  end
end
