# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w[ admin.js admin.css ]

# Because these paths are searched in order, we want the assets to come first
# Add the GOVUK Frontend images path
Rails.application.config.assets.paths << Rails.root.join("node_modules/govuk-frontend/dist/govuk/assets/images")

# Add the GOVUK Frontend fonts path
Rails.application.config.assets.paths << Rails.root.join("node_modules/govuk-frontend/dist/govuk/assets/fonts")

# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")
