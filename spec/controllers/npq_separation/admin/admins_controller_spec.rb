require "rails_helper"

RSpec.describe NpqSeparation::Admin::AdminsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let!(:admin) { create :admin }
  let!(:super_admin) { create :super_admin }

  shared_examples "unauthorised" do
    specify "index is inaccessible" do
      get npq_separation_admin_admins_path
      expect(response).to redirect_to(sign_in_path)
    end

    specify "new is inaccessible" do
      get new_npq_separation_admin_admin_path
      expect(response).to redirect_to(sign_in_path)
    end

    specify "create is inaccessible" do
      post npq_separation_admin_admins_path
      expect(response).to redirect_to(sign_in_path)
    end

    specify "update is inaccessible" do
      patch npq_separation_admin_admin_path(0)
      expect(response).to redirect_to(sign_in_path)
    end

    it "is inaccessible" do
      delete npq_separation_admin_admin_path(0)
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "when not signed in" do
    include_examples "unauthorised"
  end

  context "when signed in as a normal admin" do
    before { sign_in_as_admin }

    include_examples "unauthorised"
  end

  context "when signed in as a super admin" do
    before { sign_in_as_admin super_admin: true }

    specify "index is successful" do
      get npq_separation_admin_admins_path
      expect(response).to have_http_status(:success)
    end

    specify "new is successful" do
      get new_npq_separation_admin_admin_path
      expect(response).to have_http_status(:success)
    end

    specify "create is successful" do
      expect {
        post npq_separation_admin_admins_path, params: { admin: { email: "foo@example.org", full_name: "Name" } }
      }.to change(Admin, :count).by(1)

      expect(response).to redirect_to(npq_separation_admin_admins_path)
      expect(flash[:success]).to be_present
    end

    specify "update updates regular admin to super admin" do
      expect {
        patch npq_separation_admin_admin_path(admin)
      }.to change { admin.reload.super_admin? }.from(false).to(true)

      expect(response).to redirect_to(npq_separation_admin_admins_path)
      expect(flash[:success]).to be_present
    end

    specify "update does not change super admins" do
      expect {
        patch npq_separation_admin_admin_path(super_admin)
      }.not_to(change { super_admin.reload.super_admin? })

      expect(response).to redirect_to(npq_separation_admin_admins_path)
      expect(flash[:error]).to be_present
    end

    specify "destroy deletes regular admins" do
      expect {
        delete npq_separation_admin_admin_path(admin)
      }.to change(Admin, :count).by(-1)

      expect(response).to redirect_to(npq_separation_admin_admins_path)
      expect(flash[:success]).to be_present
    end

    specify "destroy does nothing for super admins" do
      expect {
        delete npq_separation_admin_admin_path(super_admin)
      }.not_to change(Admin, :count)

      expect(response).to redirect_to(npq_separation_admin_admins_path)
      expect(flash[:error]).to be_present
    end
  end
end
