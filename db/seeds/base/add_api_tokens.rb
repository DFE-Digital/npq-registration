{
  "Ambition Institute" => "ambition-token",
  "Best Practice Network" => "best-practice-token",
  "Church of England" => "coe-token",
  "School-Led Network" => "school-led-token",
  "UCL Institute of Education" => "ucl-token",
  "Teach First" => "teach-first-token",
  "National Institute of Teaching" => "niot-token",
  "LLSE" => "llse-token",
}.each do |name, token|
  lead_provider = LeadProvider.where("name LIKE ?", "#{name}%").first!
  APIToken.create_with_known_token!(token, lead_provider:)
end

APIToken.create_with_known_token!("trs-token", scope: "teacher_record_service")
