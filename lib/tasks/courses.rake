namespace :courses do
  desc "Update courses"
  task update: :environment do
    CourseService::DefinitionLoader.call
  end
end
