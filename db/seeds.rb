def seed_courses!
  Services::Courses::DefinitionLoader.call
end

def seed_lead_providers!
  Services::LeadProviders::Updater.call
end

# IDs have been hard coded to be the same across all envs
seed_courses!
seed_lead_providers!
