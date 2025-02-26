return if ENV["HOSTING_DOMAIN"].blank? || Rails.env.local?

Dir[Rails.root.join("public/api/docs/**/swagger.yaml")].each do |swagger_file|
  swagger_doc = File.read(swagger_file)
  File.write(swagger_file, swagger_doc.gsub("http://0.0.0.0:3000", ENV["HOSTING_DOMAIN"]))
end
