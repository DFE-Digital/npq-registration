{
  "Ambition Institute" => "ambition-token",
  "Best Practice Network" => "best-practice-token",
  "Church of England" => "coe-token",
  "Education Development Trust" => "edt-token",
  "School-Led Network" => "school-led-token",
  "University College London (UCL) Institute of Education" => "ucl-token",
  "Teacher Development Trust" => "tdt-token",
  "Teach First" => "teach-first-token",
  "National Institute of Teaching" => "niot-token",
  "LLSE" => "llse-token",
}.each do |name, token|
  lead_provider = LeadProvider.where("name LIKE ?", "#{name}%").first!
  APIToken.create_with_known_token!(token, lead_provider:)
end
