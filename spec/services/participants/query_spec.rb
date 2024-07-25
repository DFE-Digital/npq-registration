require "rails_helper"

RSpec.describe Participants::Query do
  let(:lead_provider) { create(:lead_provider) }
  let(:params) { {} }

  subject(:query) { described_class.new(**params) }

  describe "#participants" do
    let(:lead_provider) { create(:lead_provider) }
    let!(:participant1) { create(:user, :with_application, lead_provider:) }
    let!(:participant2) { create(:user, :with_application, lead_provider:) }

    it "returns all participants" do
      expect(query.participants).to contain_exactly(participant1, participant2)
    end

    it "orders participants by created_at in ascending order" do
      participant3 = travel_to(1.minute.ago) { create(:user, :with_application, lead_provider:) }

      expect(query.participants).to eq([participant3, participant1, participant2])
    end

    it "does not fetch participants with pending applications" do
      participant3 = create(:user, :with_application, lead_provider:)
      participant3.applications.update_all(lead_provider_approval_status: :pending)

      expect(query.participants).to eq([participant1, participant2])
    end

    it "does not fetch participants with rejected applications" do
      participant3 = create(:user, :with_application, lead_provider:)
      participant3.applications.update_all(lead_provider_approval_status: :rejected)

      expect(query.participants).to eq([participant1, participant2])
    end

    describe "filtering" do
      describe "lead provider" do
        context "when a lead provider is supplied" do
          let(:params) { { lead_provider: } }

          it "filters by lead provider" do
            create(:user, :with_application, lead_provider: create(:lead_provider))

            expect(query.participants).to contain_exactly(participant1, participant2)
          end
        end

        context "when lead provider is blank" do
          let(:params) { { lead_provider: " " } }

          it "does not filter by lead provider" do
            condition_string = %("lead_provider_id")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end

        context "when a lead provider is not supplied" do
          it "does not filter by lead provider" do
            condition_string = %("lead_provider_id")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end
      end

      describe "updated since" do
        context "when a updated since is supplied" do
          let(:params) { { updated_since: 1.day.ago } }

          it "filters by updated since" do
            create(:user, :with_application, lead_provider:, updated_at: 2.days.ago)

            expect(query.participants).to contain_exactly(participant1, participant2)
          end
        end

        context "when updated since is blank" do
          let(:params) { { updated_since: " " } }

          it "does not filter by updated since" do
            condition_string = %("updated_at")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end

        context "when a updated since is not supplied" do
          it "does not filter by updated since" do
            condition_string = %("updated_at")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end
      end

      describe "training status" do
        context "when a training status is supplied" do
          let(:params) { { training_status: "withdrawn" } }

          before { participant1.applications.first.update!(training_status: ApplicationState.states[:withdrawn]) }

          it "filters by training status" do
            expect(query.participants).to contain_exactly(participant1)
          end
        end

        context "when a training status is not supplied" do
          it "does not filter by training status" do
            condition_string = %("training_status")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end

        context "when training status is blank" do
          let(:params) { { training_status: " " } }

          it "does not filter by from training status" do
            condition_string = %("training_status")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end

        context "when an invalid training status is supplied" do
          let(:params) { { training_status: "any" } }

          it "does not filter by training status" do
            condition_string = %("training_status")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end
      end

      describe "from participant id" do
        let(:participant_id_change) { create(:participant_id_change, user: participant1, to_participant: participant1) }
        let(:from_participant_id) { participant_id_change.from_participant.ecf_id }

        context "when a from participant id is supplied" do
          let(:params) { { from_participant_id: } }

          it "filters by from participant id" do
            expect(query.participants).to contain_exactly(participant1)
          end
        end

        context "when a from participant id is not supplied" do
          it "does not filter by from participant id" do
            condition_string = %("from_participant_id")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end

        context "when a from participant id is blank" do
          let(:params) { { from_participant_id: " " } }

          it "does not filter by from participant id" do
            condition_string = %("from_participant_id")

            expect(query.scope.to_sql).not_to include(condition_string)
          end
        end

        context "when an invalid from participant id is supplied" do
          let(:params) { { from_participant_id: SecureRandom.uuid } }

          it "does not filter by training status" do
            expect(query.participants).to be_empty
          end
        end
      end
    end

    describe "sorting" do
      let(:participant1) { travel_to(1.month.ago) { create(:user, :with_application, lead_provider:) } }
      let(:participant2) { travel_to(1.week.ago) { create(:user, :with_application, lead_provider:) } }
      let(:participant3) { create(:user, :with_application, lead_provider:) }
      let(:sort) { nil }
      let(:params) { { sort: } }

      subject(:participants) { query.participants }

      it { is_expected.to eq([participant1, participant2, participant3]) }

      context "when sorting by created at, descending" do
        let(:sort) { "-created_at" }

        it { is_expected.to eq([participant3, participant2, participant1]) }
      end

      context "when sorting by updated at, ascending" do
        let(:sort) { "+updated_at" }

        before do
          participant1.update!(updated_at: 1.day.from_now)
          participant2.update!(updated_at: 2.days.from_now)
        end

        it { is_expected.to eq([participant3, participant1, participant2]) }
      end

      context "when sorting by multiple attributes" do
        let(:sort) { "+updated_at,-created_at" }

        before do
          participant1.update!(updated_at: 1.day.from_now)
          participant2.update!(updated_at: participant1.updated_at)
          participant3.update!(updated_at: 2.days.from_now)

          participant2.update!(created_at: 1.day.from_now)
          participant1.update!(created_at: 1.day.ago)
        end

        it { expect(participants).to eq([participant2, participant1, participant3]) }
      end
    end
  end

  describe "#participant" do
    let!(:participant) { create(:user, :with_application, lead_provider:) }
    let(:params) { { lead_provider: } }

    it "returns a participant for a Lead Provider" do
      expect(query.participant(ecf_id: participant.ecf_id)).to eq(participant)
      expect(query.participant(id: participant.id)).to eq(participant)
    end

    it "raises an error if the participant does not exist" do
      expect { query.participant(ecf_id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.participant(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the participant is not in the filtered query" do
      other_lead_provider = create(:lead_provider)
      other_participant = create(:user, :with_application, lead_provider: other_lead_provider)

      expect { query.participant(ecf_id: other_participant.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.participant(id: other_participant.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if neither an ecf_id or id is supplied" do
      expect { query.participant }.to raise_error(ArgumentError, "id or ecf_id needed")
    end
  end
end
