RSpec.configure do |config|
  config.before(:suite) do
    CourseService::DefinitionLoader.call(silent: true)
    LeadProviders::Updater.call

    file_name = "lib/approved_itt_providers/24-11-2022/approved_itt_providers.csv"
    ApprovedIttProviders::Update.call(file_name:)
  end
end
