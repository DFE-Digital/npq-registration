namespace :courses do
  desc "Update courses"
  task update: :environment do
    %w[
      leadership
      specialist
      support
      ehco
    ].each do |name|
      FactoryBot.create(:course_group, name:)
    end

    CourseService::DefinitionLoader.call
  end
end
