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
