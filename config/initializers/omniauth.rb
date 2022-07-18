Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect, {
    name: :get_an_identity,
    issuer: "http://localhost:3001",
    discovery: true,
    scope: [:trn],
    response_type: :code,
    client_options: {
      port: 3001,
      scheme: "http",
      host: "localhost",
      identifier: "boyQB2A0Hp0y_BVY2La5j9lOshSNWte-Pa8XwK9r8bM",
      secret: "FEvTNrUXTypY5x1NWC0dbu6PakiX4wC4lUDkvBaR9EQ",
      redirect_uri: "http://localhost:3000/auth/get_an_identity/callback",
    },
  }
end
