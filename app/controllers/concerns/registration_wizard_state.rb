module RegistrationWizardState
private

  def state_store
    Registration::StateStore.new(repository:, current_user:)
  end

  def repository
    DfE::Wizard::Repository::Session.new(session:, key: :registration)
  end
end
