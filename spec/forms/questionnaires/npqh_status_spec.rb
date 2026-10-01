require "rails_helper"

RSpec.describe Questionnaires::NpqhStatus, type: :model do
  subject(:instance) { described_class.new(npqh_status:) }

  let(:npqh_status) { nil }

  it { is_expected.to validate_inclusion_of(:npqh_status).in_array(Questionnaires::NpqhStatus::VALID_NPQH_STATUS_OPTIONS) }
end
