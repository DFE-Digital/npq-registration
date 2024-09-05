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
