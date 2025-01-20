PaperTrail.serializer = PaperTrail::Serializers::JSON

Rails.application.configure do
  console do
    PaperTrail.request.whodunnit = "Rails Console"
  end
end
