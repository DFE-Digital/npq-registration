require "rails_helper"

RSpec.describe Migration::Ecf::NpqApplication, type: :model do
  describe "migration convenience methods" do
    subject(:instance) { create(:ecf_npq_application) }

    it { expect(instance.ecf_id).to eq(instance.id) }
    it { expect(instance.course).to eq(instance.npq_course) }
  end
end
