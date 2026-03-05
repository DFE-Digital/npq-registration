require "rails_helper"

RSpec.describe Users::MergeAndArchive do
  let(:user_to_merge) { create(:user, :with_get_an_identity_id) }
  let(:user_to_keep) { create(:user) }

  let!(:user_to_keep_rejected_application) { create(:application, :rejected, user: user_to_keep) }
  let!(:user_to_keep_pending_application) { create(:application, :pending, user: user_to_keep) }
  let!(:user_to_keep_accepted_application) { create(:application, :accepted, user: user_to_keep) }

  let!(:user_to_merge_rejected_application) { create(:application, :rejected, user: user_to_merge) }
  let!(:user_to_merge_pending_application) { create(:application, :pending, user: user_to_merge) }
  let!(:user_to_merge_accepted_application) { create(:application, :accepted, user: user_to_merge) }

  let!(:existing_participant_id_change) { create(:participant_id_change, user: user_to_merge) }

  it "does not expose internal attributes" do
    expect { described_class.new(user_to_merge:, user_to_keep:).user_to_merge }.to raise_error(NameError)
    expect { described_class.new(user_to_merge:, user_to_keep:).user_to_keep }.to raise_error(NameError)
  end

  describe ".call" do
    subject { described_class.new(user_to_merge:, user_to_keep:).call(dry_run:) }

    context "when dry run false" do
      let(:dry_run) { false }

      it "moves all applications from the user to merge to the user to keep" do
        subject
        expect(user_to_keep.applications.to_a).to contain_exactly(user_to_keep_rejected_application,
                                                                  user_to_keep_pending_application,
                                                                  user_to_keep_accepted_application,
                                                                  user_to_merge_rejected_application,
                                                                  user_to_merge_pending_application,
                                                                  user_to_merge_accepted_application)
      end

      it "archives the user to merge" do
        subject
        expect(user_to_merge.reload).to be_archived
      end

      it "keeps the user to keep" do
        subject
        expect(user_to_keep).not_to be_archived
      end

      it "creates a participant id change" do
        subject
        expect(user_to_keep.participant_id_changes.first).to have_attributes(from_participant_id: user_to_merge.ecf_id, to_participant_id: user_to_keep.ecf_id)
      end

      it "moves existing participant id changes" do
        subject
        expect(existing_participant_id_change.reload.user).to eq user_to_keep
      end

      context "when there is already a participant id change" do
        before { create(:participant_id_change, user: user_to_keep, from_participant_id: user_to_merge.ecf_id, to_participant_id: user_to_keep.ecf_id) }

        it "does not create a duplicate participant id change" do
          subject
          expect(user_to_keep.participant_id_changes).to contain_exactly(
            an_object_having_attributes(from_participant_id: user_to_merge.ecf_id, to_participant_id: user_to_keep.ecf_id),
            existing_participant_id_change.reload,
          )
        end
      end

      context "when moving the existing participant id changes would cause a circular reference" do
        let!(:existing_participant_id_change) { create(:participant_id_change, user: user_to_merge, from_participant_id: user_to_keep.ecf_id, to_participant_id: user_to_merge.ecf_id) }

        it "deletes the participant id changes instead of moving them" do
          subject
          expect(ParticipantIdChange.exists?(existing_participant_id_change.id)).to be false
        end
      end

      context "when only the user to merge has a uid" do
        context "when set_uid is false" do
          it "does not update the user to keep uid" do
            expect { subject }.not_to(change { user_to_keep.reload.uid })
          end
        end

        context "when set_uid is true" do
          subject { described_class.new(user_to_merge:, user_to_keep:, set_uid: true).call(dry_run:) }

          it "sets the user to keep uid to the one from the user to merge" do
            expect { subject }.to change { user_to_keep.reload.uid }.to(user_to_merge.uid)
          end
        end
      end
    end

    context "when dry run true" do
      let(:dry_run) { true }

      it "does not change any users" do
        expect { subject }.not_to(change { User.all.pluck(:archived_at) })
      end

      it "does not change any applications" do
        expect { subject }.not_to(change { Application.all.pluck(:user_id) })
      end
    end
  end
end
