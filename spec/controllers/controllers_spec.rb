require "rails_helper"

RSpec.describe "choosing the correct controller to inherit from" do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin) }

  shared_examples "not allowing an unauthenticated user access" do
    it "does not allow unauthenticated user access" do
      get :index
      expect(response).to redirect_to(sign_in_path)
    end
  end

  shared_examples "allowing an unauthenticated user access" do
    it "allows unauthenticated user access" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  shared_examples "allowing an authenticated user access" do
    it "allows authenticated user access" do
      session[:user_id] = user.id
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  shared_examples "not allowing an authenticated user access" do
    it "does not allow authenticated user access" do
      session[:user_id] = user.id
      get :index
      expect(response).to redirect_to(sign_in_path)
    end
  end

  shared_examples "allowing an admin access" do
    it "allows an admin access" do
      session[:admin_id] = admin_user.id
      session[:admin_sign_in_at] = Time.zone.now
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  shared_examples "not allowing an admin access" do
    it "does not allow an admin access" do
      session[:admin_id] = admin_user.id
      session[:admin_sign_in_at] = Time.zone.now
      get :index
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "when a controller is a subclass of ApplicationController" do
    controller(ApplicationController) do
      def index
        head :ok
      end
    end

    it "raises an error" do
      expect { get :index }.to raise_error(RuntimeError, "ApplicationController should not be used directly. Use a subclass instead.")
    end
  end

  context "when a controller is a subclass of LoggedInController" do
    controller(LoggedInController) do
      def index
        head :ok
      end
    end

    it_behaves_like "not allowing an unauthenticated user access"
    it_behaves_like "allowing an authenticated user access"
    it_behaves_like "not allowing an admin access"
  end

  context "when a controller is a subclass of NpqSeparation::AdminController" do
    controller(NpqSeparation::AdminController) do
      def index
        head :ok
      end
    end

    it_behaves_like "not allowing an unauthenticated user access"
    it_behaves_like "not allowing an authenticated user access"
    it_behaves_like "allowing an admin access"
  end

  context "when a controller is a subclass of PublicPagesController" do
    controller(PublicPagesController) do
      def index
        head :ok
      end
    end

    it_behaves_like "allowing an unauthenticated user access"
    it_behaves_like "allowing an authenticated user access"
    it_behaves_like "allowing an admin access"
  end
end
