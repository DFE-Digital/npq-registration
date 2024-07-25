%w[
  leadership
  specialist
  support
  ehco
].each do |name|
  FactoryBot.create(:course_group, name:)
end
