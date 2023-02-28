RSpec.configure do |config|
  config.before(:suite) do
    Services::Courses::DefinitionLoader.call(silent: true)
    Services::LeadProviders::Updater.call

    file_name = "lib/approved_itt_providers/24-11-2022/approved_itt_providers.csv"
    Services::ApprovedIttProviders::Update.call(file_name:)
  end
end
