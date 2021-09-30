def seed_courses!
  [
    { name: "NPQ Leading Teaching (NPQLT)", ecf_id: "15c52ed8-06b5-426e-81a2-c2664978a0dc" },
    { name: "NPQ Leading Behaviour and Culture (NPQLBC)", ecf_id: "7d47a0a6-fa74-4587-92cc-cd1e4548a2e5" },
    { name: "NPQ Leading Teacher Development (NPQLTD)", ecf_id: "29fee78b-30ce-4b93-ba21-80be2fde286f" },
    { name: "NPQ for Senior Leadership (NPQSL)", ecf_id: "a42736ad-3d0b-401d-aebe-354ef4c193ec" },
    { name: "NPQ for Headship (NPQH)", ecf_id: "0f7d6578-a12c-4498-92a0-2ee0f18e0768" },
    { name: "NPQ for Executive Leadership (NPQEL)", ecf_id: "aef853f2-9b48-4b6a-9d2a-91b295f5ca9a" },
    { name: "Additional Support Offer for new headteachers", ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7", description: "The Additional Support Offer is a targeted support package for new headteachers." },
  ].each do |hash|
    Course.find_or_create_by!(name: hash[:name], ecf_id: hash[:ecf_id], description: hash[:description])
  end
end

def seed_lead_providers!
  [
    { name: "Ambition Institute", ecf_id: "9e35e998-c63b-4136-89c4-e9e18ddde0ea" },
    { name: "Best Practice Network (home of Outstanding Leaders Partnership)", ecf_id: "57ba9e86-559f-4ff4-a6d2-4610c7259b67" },
    { name: "Church of England", ecf_id: "79cb41ca-cb6d-405c-b52c-b6f7c752388d" },
    { name: "Education Development Trust", ecf_id: "21e61f53-9b34-4384-a8f5-d8224dbf946d" },
    { name: "School-Led Network", ecf_id: "bc5e4e37-1d64-4149-a06b-ad10d3c55fd0" },
    { name: "Leadership Learning South East (LLSE)", ecf_id: "230e67c0-071a-4a48-9673-9d043d456281" },
    { name: "Teacher Development Trust", ecf_id: "30fd937e-b93c-4f81-8fff-3c27544193f1" },
    { name: "Teach First", ecf_id: "a02ae582-f939-462f-90bc-cebf20fa8473" },
    { name: "UCL Institute of Education", ecf_id: "ef687b3d-c1c0-4566-a295-16d6fa5d0fa7" },
  ].each do |hash|
    LeadProvider.find_or_create_by!(name: hash[:name], ecf_id: hash[:ecf_id])
  end
end

# IDs have been hard coded to be the same across all envs
seed_courses!
seed_lead_providers!
