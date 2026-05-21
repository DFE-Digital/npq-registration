namespace :courses do
  desc "Update courses"
  task update: :versioned_environment do
    Rails.logger = Logger.new($stdout) unless Rails.env.test?

    %w[
      leadership
      specialist
      support
      ehco
    ].each do |name|
      CourseGroup.find_or_create_by!(name:)
    end

    CourseService::DefinitionLoader.call
  end
end
