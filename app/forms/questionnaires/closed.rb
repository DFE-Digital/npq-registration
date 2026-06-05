module Questionnaires
  class Closed < Base
    def requirements_met?
      Feature.registration_closed?(query_store.current_user) # redirects to root path if registration is open
    end
  end
end
