return if ENV["DOMAIN"].blank?

Dir[Rails.root.join("public/api/docs/**/swagger.yaml")].each do |swagger_file|
  swagger_doc = File.read(swagger_file)
  File.write(swagger_file, swagger_doc.gsub("http://0.0.0.0:3000", "https://#{ENV["DOMAIN"]}"))
end
