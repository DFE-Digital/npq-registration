%w[
  leadership
  specialist
  support
  ehco
].each do |n|
  CourseGroup.find_or_create_by!(name: n)
end
