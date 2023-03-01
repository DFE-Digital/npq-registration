def seed_courses!
  Services::Courses::DefinitionLoader.call
end

def seed_lead_providers!
  Services::LeadProviders::Updater.call
end

def seed_itt_providers!
  file_name = "lib/approved_itt_providers/24-11-2022/approved_itt_providers.csv"
  Services::ApprovedIttProviders::Update.call(file_name:)
end

# IDs have been hard coded to be the same across all envs
seed_courses!
seed_lead_providers!
seed_itt_providers!
