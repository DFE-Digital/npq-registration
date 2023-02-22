namespace :courses do
  desc "Update courses"
  task update: :environment do
    Services::Courses::DefinitionLoader.call
  end
end
