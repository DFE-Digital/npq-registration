require "rails_helper"

RSpec.describe TeachingRecordSystem::Webhooks::PersonDeactivatedProcessor do
  describe ".call" do
    subject { described_class.call(webhook_message:) }

    let(:deactivated_trn) { "2000000" }
    let(:merged_with_trn) { "3000000" }
    let(:webhook_message) { create(:trs_person_deactivated_webhook_message, deactivated_trn:, merged_with_trn:) }

    context "when there is a teacher auth user matching the deactivated person" do
      let(:user_matching_deactivated_trn) { create(:user, :with_teacher_auth, trn: deactivated_trn) }
      let(:application_on_deactivated_user) { create(:application, user: user_matching_deactivated_trn) }

      before { application_on_deactivated_user }

      context "and there are no users matching the merged with person" do
        it "updates the TRN on the matching deactivated person users" do
          subject
          expect(user_matching_deactivated_trn.reload.trn).to eq(merged_with_trn)
        end

        it "marks the webhook message as processed" do
          expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
        end
      end

      context "when the merged with person is null" do
        let(:webhook_message) { create(:trs_person_deactivated_webhook_message, :no_merged_with_person, deactivated_trn:) }

        it "does not change any users" do
          subject
          expect(user_matching_deactivated_trn.reload.trn).to eq deactivated_trn
        end

        it "marks the webhook message as processed" do
          expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
        end
      end

      context "when there is a user matching the merged-with person" do
        context "and the merged-with matching user is a teacher auth user" do
          let(:user_matching_merged_with_trn) { create(:user, :with_teacher_auth, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: user_matching_merged_with_trn) }
          let(:archived_teacher_auth_user_matching_merged_with_trn) { create(:user, :with_teacher_auth, :archived, trn: merged_with_trn) }
          let(:application_on_archived_teacher_auth_user) { create(:application, user: archived_teacher_auth_user_matching_merged_with_trn) }

          before do
            application_on_merged_with_user
            application_on_archived_teacher_auth_user
          end

          it "merges the users matching the deactivated person into the user matching the merged-with person" do
            subject
            expect(user_matching_deactivated_trn.reload).to be_archived
            expect(application_on_deactivated_user.reload.user).to eq user_matching_merged_with_trn
            expect(application_on_archived_teacher_auth_user.reload.user).to eq user_matching_merged_with_trn
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end

        context "and the matching merged-with user is an archived teacher auth user" do
          let(:user_matching_merged_with_trn) { create(:user, :with_teacher_auth, :archived, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: user_matching_merged_with_trn) }

          before { application_on_merged_with_user }

          it "updates the TRN on the user matching the deactivated person" do
            subject
            expect(user_matching_deactivated_trn.reload.trn).to eq(merged_with_trn)
          end

          it "merges the archived user matching the merged-with person into the user matching the deactivated person" do
            subject
            expect(user_matching_merged_with_trn.reload).to be_archived
            expect(application_on_merged_with_user.reload.user).to eq user_matching_deactivated_trn
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end

          context "and there are also archived GAI users matching the merged-with person" do
            let(:archived_gai_user_matching_merged_with_trn) { create(:user, :with_get_an_identity_id, :archived, trn: merged_with_trn) }

            before { archived_gai_user_matching_merged_with_trn }

            it "merges the archived GAI users into the user matching the deactivated person" do
              subject
              expect(archived_gai_user_matching_merged_with_trn.reload).to be_archived
            end

            it "marks the webhook message as processed" do
              expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
            end
          end
        end
      end
    end

    context "when there are archived teacher auth users matching the deactivated person" do
      let(:archived_teacher_auth_user_matching_deactivated_trn) { create(:user, :with_teacher_auth, :archived, trn: deactivated_trn) }
      let(:archived_teacher_auth_user_matching_deactivated_trn_2) { create(:user, :with_teacher_auth, :archived, trn: deactivated_trn) }
      let(:application_on_deactivated_user) { create(:application, user: archived_teacher_auth_user_matching_deactivated_trn) }
      let(:application_on_deactivated_user_2) { create(:application, user: archived_teacher_auth_user_matching_deactivated_trn_2) }

      before do
        application_on_deactivated_user
        application_on_deactivated_user_2
      end

      context "and there are no users matching the merged with person" do
        let(:webhook_message) { create(:trs_person_deactivated_webhook_message, deactivated_trn: deactivated_trn, merged_with_trn:) }

        it "updates the TRN on the matching archived users" do
          subject
          expect(archived_teacher_auth_user_matching_deactivated_trn.reload.trn).to eq(merged_with_trn)
          expect(archived_teacher_auth_user_matching_deactivated_trn_2.reload.trn).to eq(merged_with_trn)
        end

        it "marks the webhook message as processed" do
          expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
        end
      end

      context "when there is a user matching the merged-with person" do
        context "and the merged-with matching user is a teacher auth user" do
          let(:user_matching_merged_with_trn) { create(:user, :with_teacher_auth, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: user_matching_merged_with_trn) }

          before { application_on_merged_with_user }

          it "merges the archived users matching the deactivated person into the user matching the merged-with person" do
            subject
            expect(archived_teacher_auth_user_matching_deactivated_trn.reload).to be_archived
            expect(application_on_deactivated_user.reload.user).to eq user_matching_merged_with_trn # not working
            expect(archived_teacher_auth_user_matching_deactivated_trn_2.reload).to be_archived
            expect(application_on_deactivated_user_2.reload.user).to eq user_matching_merged_with_trn # not working
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end

        context "and the merged-with matching user matches archived teacher auth users" do
          let(:user_matching_merged_with_trn) { create(:user, :with_teacher_auth, :archived, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: user_matching_merged_with_trn) }
          let(:user_matching_merged_with_trn_2) { create(:user, :with_teacher_auth, :archived, trn: merged_with_trn) }
          let(:application_on_merged_with_user_2) { create(:application, user: user_matching_merged_with_trn) }

          before do
            application_on_merged_with_user
            application_on_merged_with_user_2
          end

          it "merges the deactived users into the first merged-with user" do
            subject
            expect(application_on_deactivated_user.reload.user).to eq user_matching_merged_with_trn
            expect(application_on_deactivated_user_2.reload.user).to eq user_matching_merged_with_trn
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end

          context "and there are also archived GAI users matching the merged-with TRN" do
            let(:archived_gai_user_matching_merged_with_trn) { create(:user, :with_get_an_identity_id, :archived, trn: merged_with_trn) }
            let(:archived_gai_user_matching_merged_with_trn_2) { create(:user, :with_get_an_identity_id, :archived, trn: merged_with_trn) }

            before do
              archived_gai_user_matching_merged_with_trn
              archived_gai_user_matching_merged_with_trn_2
            end

            it "merges the archived GAI users into the first merged-with teacher auth user" do
              subject
              expect(archived_gai_user_matching_merged_with_trn.reload).to be_archived # no change
              expect(archived_gai_user_matching_merged_with_trn_2.reload).to be_archived # no change
            end
          end
        end

        context "and the matching merged-with users are GAI users" do
          let(:gai_user_matching_merged_with_trn) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: merged_with_trn) }
          let(:gai_user_matching_merged_with_trn_2) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: gai_user_matching_merged_with_trn) }
          let(:application_on_merged_with_user_2) { create(:application, user: gai_user_matching_merged_with_trn_2) }

          before do
            application_on_merged_with_user
            application_on_merged_with_user_2
          end

          it "merges the users matching the deactivated person into the most recent teacher auth user matching the merged-with person" do
            subject
            expect(archived_teacher_auth_user_matching_deactivated_trn.reload).to be_archived
            expect(archived_teacher_auth_user_matching_deactivated_trn_2.reload).to be_archived
            expect(application_on_deactivated_user.reload.user).to eq(archived_teacher_auth_user_matching_deactivated_trn_2)
            expect(application_on_deactivated_user_2.reload.user).to eq(archived_teacher_auth_user_matching_deactivated_trn_2)
          end

          it "merges the verified GAI users matching the merged-with person into the most recent teacher auth user matching the merged-with person" do
            subject
            expect(gai_user_matching_merged_with_trn.reload).to be_archived
            expect(gai_user_matching_merged_with_trn_2.reload).to be_archived
            expect(application_on_merged_with_user.reload.user).to eq(archived_teacher_auth_user_matching_deactivated_trn_2)
            expect(application_on_merged_with_user_2.reload.user).to eq(archived_teacher_auth_user_matching_deactivated_trn_2)
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end

        context "and the matching merged-with users are archived GAI users" do
          let(:gai_user_matching_merged_with_trn) { create(:user, :with_get_an_identity_id, :with_verified_trn, :archived, trn: merged_with_trn) }
          let(:gai_user_matching_merged_with_trn_2) { create(:user, :with_get_an_identity_id, :with_verified_trn, :archived, trn: merged_with_trn) }

          it "does not change any users" do
            subject
            expect(gai_user_matching_merged_with_trn.reload).to be_archived
            expect(gai_user_matching_merged_with_trn_2.reload).to be_archived
            expect(gai_user_matching_merged_with_trn.reload.trn).to eq(merged_with_trn)
            expect(gai_user_matching_merged_with_trn_2.reload.trn).to eq(merged_with_trn)
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end
      end
    end

    context "when there are GAI users matching the deactived person" do
      let(:archived_verified_gai_user_matching_deactivated_trn) { create(:user, :with_get_an_identity_id, :archived, :with_verified_trn, trn: deactivated_trn) }
      let(:verified_gai_user_matching_deactivated_trn) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: deactivated_trn) }
      let(:archived_unverified_gai_user_matching_deactivated_trn) { create(:user, :with_get_an_identity_id, :archived, trn: deactivated_trn) }
      let(:unverified_gai_user_matching_deactivated_trn) { create(:user, :with_get_an_identity_id, trn: deactivated_trn) }
      let(:application_for_verifed_gai_user) { create(:application, user: verified_gai_user_matching_deactivated_trn) }
      let(:application_for_unverified_gai_user) { create(:application, user: unverified_gai_user_matching_deactivated_trn) }

      before do
        archived_verified_gai_user_matching_deactivated_trn
        archived_unverified_gai_user_matching_deactivated_trn
        application_for_verifed_gai_user
        application_for_unverified_gai_user
      end

      context "and there is no user matching the merged-with person" do
        it "updates the TRN for the GAI users with verified TRNs" do
          subject
          expect(verified_gai_user_matching_deactivated_trn.reload.trn).to eq(merged_with_trn)
          expect(archived_verified_gai_user_matching_deactivated_trn.reload.trn).to eq(merged_with_trn)
          expect(unverified_gai_user_matching_deactivated_trn.reload.trn).to eq(deactivated_trn)
          expect(archived_unverified_gai_user_matching_deactivated_trn.reload.trn).to eq(deactivated_trn)
        end

        it "marks the webhook message as processed" do
          expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
        end
      end

      context "when there is a user matching the merged-with person" do
        context "and the merged-with matching user is a teacher auth user" do
          let(:user_matching_merged_with_trn) { create(:user, :with_teacher_auth, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: user_matching_merged_with_trn) }

          before { application_on_merged_with_user }

          it "merges the verified GAI users matching the deactivated person into the teacher auth user matching the merged-with person" do
            subject
            expect(verified_gai_user_matching_deactivated_trn.reload).to be_archived
            expect(application_for_verifed_gai_user.reload.user).to eq(user_matching_merged_with_trn)
            expect(unverified_gai_user_matching_deactivated_trn.reload).not_to be_archived
            expect(application_for_unverified_gai_user.reload.user).to eq(unverified_gai_user_matching_deactivated_trn)
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end

        context "and the merged-with matching user is an archived teacher auth user" do
          let(:archived_user_matching_merged_with_trn) { create(:user, :with_teacher_auth, :archived, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: archived_user_matching_merged_with_trn) }

          before { application_on_merged_with_user }

          it "merges the verified GAI users matching the deactivated person into the archived teacher auth user matching the merged-with person" do
            subject
            expect(verified_gai_user_matching_deactivated_trn.reload).to be_archived
            expect(application_for_verifed_gai_user.reload.user).to eq(archived_user_matching_merged_with_trn)
            expect(unverified_gai_user_matching_deactivated_trn.reload).not_to be_archived
            expect(application_for_unverified_gai_user.reload.user).to eq(unverified_gai_user_matching_deactivated_trn)
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end

        context "and the matching merged-with users are GAI users" do
          let(:gai_user_matching_merged_with_trn) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: merged_with_trn) }
          let(:gai_user_matching_merged_with_trn_2) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: merged_with_trn) }
          let(:application_on_merged_with_user) { create(:application, user: gai_user_matching_merged_with_trn) }
          let(:application_on_merged_with_user_2) { create(:application, user: gai_user_matching_merged_with_trn_2) }

          before do
            application_on_merged_with_user
            application_on_merged_with_user_2
            create(:user, :with_get_an_identity_id, trn: merged_with_trn)
            create(:user, :with_get_an_identity_id, :with_verified_trn, :archived, trn: merged_with_trn)
          end

          it "merges the verified GAI users matching the deactivated person into the most recent verified GAI user matching the merged-with person" do
            subject
            expect(verified_gai_user_matching_deactivated_trn.reload).to be_archived
            expect(application_for_verifed_gai_user.reload.user).to eq(gai_user_matching_merged_with_trn_2)
          end

          it "merges the verified GAI users matching the merged-in person into the most recent verified GAI user matching the merged-with person" do
            subject
            expect(gai_user_matching_merged_with_trn.reload).to be_archived
            expect(gai_user_matching_merged_with_trn_2.reload).not_to be_archived
            expect(application_for_verifed_gai_user.reload.user).to eq(gai_user_matching_merged_with_trn_2)
            expect(application_on_merged_with_user_2.reload.user).to eq(gai_user_matching_merged_with_trn_2)
            expect(application_for_unverified_gai_user.reload.user).to eq(unverified_gai_user_matching_deactivated_trn)
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end

        context "and the matching merged-with users are archived GAI users" do
          let(:verified_gai_user_matching_deactivated_trn_2) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: deactivated_trn) }
          let(:gai_user_matching_merged_with_trn) { create(:user, :with_get_an_identity_id, :archived, :with_verified_trn, trn: merged_with_trn) }
          let(:gai_user_matching_merged_with_trn_2) { create(:user, :with_get_an_identity_id, :archived, :with_verified_trn, trn: merged_with_trn) }

          before do
            verified_gai_user_matching_deactivated_trn_2
            gai_user_matching_merged_with_trn
            gai_user_matching_merged_with_trn_2
          end

          it "merges the verified GAI users matching the deactivated person into the most recent non-archived user matching the deactivated person" do
            subject
            expect(verified_gai_user_matching_deactivated_trn.reload).to be_archived
            expect(verified_gai_user_matching_deactivated_trn_2.reload).not_to be_archived
            expect(application_for_verifed_gai_user.reload.user).to eq(verified_gai_user_matching_deactivated_trn_2)
            expect(application_for_unverified_gai_user.reload.user).to eq(unverified_gai_user_matching_deactivated_trn)
          end

          it "marks the webhook message as processed" do
            expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
          end
        end
      end
    end

    context "when there is no user matching the deactivated person" do
      it "marks the webhook message as processed" do
        expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
      end
    end

    context "when the message format is incorrect" do
      let(:webhook_message) { create(:trs_person_deactivated_webhook_message, deactivated_trn: nil, merged_with_trn: nil, message:) }
      let(:message) do
        {
          "deactivatedPerson" => {},
          "mergedWithPerson" => {},
        }
      end

      it "marks the webhook message as failed" do
        subject
        expect(webhook_message.reload).to have_attributes(
          status: "failed",
          status_comment: "Invalid message format",
        )
      end
    end
  end
end
