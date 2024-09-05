def create_application_with_declaration(*traits, **fields)
  application = create(:application, :accepted, *traits, **fields)
  declaration_date = application.schedule.applies_from + 1.day
  travel_to(declaration_date) do
    create(:declaration, application:)
  end

  application
end

def create_declaration(*traits, **fields)
  application = fields[:application] || create(:application, :accepted)
  declaration_date = application.schedule.applies_from + 1.day
  travel_to(declaration_date) do
    create(:declaration, *traits, **fields)
  end
end

def create_participant_outcome(*traits, **fields)
  application = create(:application, :accepted)
  declaration_date = application.schedule.applies_from + 1.day
  declaration = travel_to(declaration_date) do
    create(:declaration, application:)
  end

  create(:participant_outcome, *traits, **fields, declaration:)
end

def create_statement_item(*traits, **fields)
  application = create(:application, :accepted)
  declaration_date = application.schedule.applies_from + 1.day
  declaration = travel_to(declaration_date) do
    create(:declaration, application:)
  end

  create(:statement_item, *traits, **fields, declaration:)
end
