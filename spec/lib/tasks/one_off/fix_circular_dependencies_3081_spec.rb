# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ParticipantIDChange cleanup tasks" do
  describe "one_off:delete_empty_participant_id_changes" do
    subject :run_task do
      Rake::Task["one_off:delete_empty_participant_id_changes"].invoke
    end

    after { Rake::Task["one_off:delete_empty_participant_id_changes"].reenable }

    let(:from_user) { create(:user, trn: "1234", trn_verified: false) }

    context "when second user does not exists" do
      let(:non_existing_user_uuid) { SecureRandom.uuid }

      context "when there is only ParticipantIdChange record" do
        before do
          create(:participant_id_change, user: from_user, from_participant_id: from_user.ecf_id, to_participant_id: non_existing_user_uuid)
        end

        it "deletes the records" do
          expect { run_task }.to change(ParticipantIdChange, :count).from(1).to(0)
        end
      end

      context "when there are 2, circular ParticipantIdChange records" do
        before do
          create(:participant_id_change, user: from_user, from_participant_id: from_user.ecf_id, to_participant_id: non_existing_user_uuid)
          create(:participant_id_change, user: from_user, from_participant_id: non_existing_user_uuid, to_participant_id: from_user.ecf_id)
        end

        it "deletes the records" do
          expect { run_task }.to change(ParticipantIdChange, :count).from(2).to(0)
        end
      end
    end
  end

  describe "one_off:fix_participant_id_changes_circular_dependencies" do
    subject :run_task do
      Rake::Task["one_off:fix_participant_id_changes_circular_dependencies"].invoke
    end

    after { Rake::Task["one_off:fix_participant_id_changes_circular_dependencies"].reenable }

    let(:from_user) { create(:user, trn: "1234", trn_verified: false, significantly_updated_at: 1.week.ago) }
    let(:to_user) { create(:user, trn: "1234", trn_verified: false, significantly_updated_at: 1.day.ago) }

    context "when there is circular dependency" do
      before do
        create(:participant_id_change, user: from_user, from_participant_id: from_user.ecf_id, to_participant_id: to_user.ecf_id)
        create(:participant_id_change, user: from_user, from_participant_id: to_user.ecf_id, to_participant_id: from_user.ecf_id)
      end

      it "archives the user" do
        expect { run_task }.to change { from_user.reload.archived? }.from(false).to(true)
      end

      it "does not archive the to user" do
        expect { run_task }.not_to(change { to_user.reload.archived? })
      end

      it "leaves only one ParticipantIdChange" do
        expect { run_task }.to change(ParticipantIdChange, :count).from(2).to(1)
      end

      context "when checking the ParticipantIdChange record" do
        let(:participant_id_change) { ParticipantIdChange.first }

        before { run_task }

        it "has the proper from_user" do
          expect(participant_id_change.from_participant_id).to eq from_user.ecf_id
        end

        it "has the proper to_user" do
          expect(participant_id_change.to_participant_id).to eq to_user.ecf_id
        end
      end

      context "when from user was changed recently" do
        let(:from_user) { create(:user, trn: "1234", trn_verified: false, significantly_updated_at: 1.hour.ago) }

        it "archives correct user" do
          expect { run_task }.to change { to_user.reload.archived? }.from(false).to(true)
        end
      end

      context "when the circular users trn is different" do
        let(:to_user) { create(:user, trn: "12345", trn_verified: false, significantly_updated_at: 1.day.ago) }

        it "does not archive the from user" do
          expect { run_task }.not_to(change { from_user.reload.archived? })
        end

        it "does not archive the to user" do
          expect { run_task }.not_to(change { to_user.reload.archived? })
        end
      end

      context "when to_user is archived" do
        context "when checking the ParticipantIdChange record" do
          let(:participant_id_change) { ParticipantIdChange.first }
          let(:to_user) { create(:user, trn: "1234", trn_verified: false, significantly_updated_at: 1.day.ago) }

          before do
            Users::Archiver.new(user: to_user).archive!
            run_task
          end

          it "has only one record" do
            expect(ParticipantIdChange.count).to eq 1
          end

          it "has the proper from_user" do
            expect(participant_id_change.from_participant_id).to eq to_user.ecf_id
          end

          it "has the proper to_user" do
            expect(participant_id_change.to_participant_id).to eq from_user.ecf_id
          end
        end
      end
    end
  end
end
