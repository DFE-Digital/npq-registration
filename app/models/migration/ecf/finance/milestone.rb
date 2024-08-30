# frozen_string_literal: true

module Migration::Ecf::Finance
  class Milestone < Migration::Ecf::BaseRecord
    belongs_to :schedule
  end
end
