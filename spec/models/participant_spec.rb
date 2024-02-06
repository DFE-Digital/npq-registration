require "rails_helper"

RSpec.describe Participant, type: :model do
  describe "scopes" do
    describe ".unsynced" do
      expected = %("participants"."ecf_id" IS NULL)

      let(:expected) { expected }

      it "contains #{expected}" do
        expect(Participant.unsynced.to_sql).to match(Regexp.new(expected))
      end
    end

    describe ".synced" do
      expected = %("participants"."ecf_id" IS NOT NULL)

      let(:expected) { expected }

      it "contains #{expected}" do
        expect(Participant.synced.to_sql).to match(Regexp.new(expected))
      end
    end
  end
end
