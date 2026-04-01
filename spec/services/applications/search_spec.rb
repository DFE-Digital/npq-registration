# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::Search do
  subject { described_class.search(q) }

  let(:user) { build(:user, preferred_name: "Rasmus Lerdorf") }
  let(:application) { create(:application, user:) }
  let(:declaration) { create(:declaration, application:) }

  before do
    other_application = create(:application, user: create(:user, full_name: "Jane Doe"))
    create(:declaration, application: other_application)
  end

  shared_examples "a search returning matching applications" do
    it { is_expected.to contain_exactly(application) }
  end

  context "when name matches" do
    let(:q) { user.full_name }

    it_behaves_like "a search returning matching applications"
  end

  context "when name partially matches" do
    let(:q) { user.full_name.split(" ").first }

    it_behaves_like "a search returning matching applications"
  end

  context "when preferred name matches" do
    let(:q) { user.preferred_name }

    it_behaves_like "a search returning matching applications"
  end

  context "when preferred name partially matches" do
    let(:q) { user.preferred_name.split(" ").first }

    it_behaves_like "a search returning matching applications"
  end

  context "when application ID matches" do
    let(:q) { application.ecf_id }

    it_behaves_like "a search returning matching applications"
  end

  context "when declaration ID matches" do
    let(:q) { declaration.ecf_id }

    it_behaves_like "a search returning matching applications"
  end

  context "when nothing matches" do
    let(:q) { "foobarbaz" }

    it { is_expected.to be_empty }
  end

  context "when query is blank" do
    let(:q) { nil }

    it { is_expected.to eq(Application.all) }
  end
end
