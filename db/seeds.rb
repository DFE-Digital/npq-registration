[
  "NPQ Leading Teaching (NPQLT)",
  "NPQ Leading Behaviour and Culture (NPQLBC)",
  "NPQ Leading Teacher Development (NPQLTD)",
  "NPQ for Senior Leadership (NPQSL)",
  "NPQ for Headship (NPQH)",
  "NPQ for Executive Leadership (NPQEL)",
].each do |course_name|
  Course.find_or_create_by!(name: course_name)
end

[
  "Ambition Institute",
  "Best Practice Network",
  "Church of England",
  "Education Development Trust",
  "Harris Federation",
  "Leadership Learning South East",
  "Teacher Development Trust",
  "Teach First",
  "UCL Institute of Education",
].each do |lead_provider_name|
  LeadProvider.find_or_create_by!(name: lead_provider_name)
end
