# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::Search do
  subject { described_class.search(q) }

  let(:application)  { create(:application) }
  let(:declarations) { create_list(:declaration, 2, application:) }

  before do
    a = create(:application, user: create(:user, full_name: "Jane Doe"))
    create_list(:declaration, 2, application: a)
  end

  shared_examples "a search returning matching applications" do
    it { is_expected.to contain_exactly(application) }
  end

  context "when name matches" do
    let(:q) { application.user.full_name }

    it_behaves_like "a search returning matching applications"
  end

  context "when name partially matches" do
    let(:q) { application.user.full_name.split(" ").first }

    it_behaves_like "a search returning matching applications"
  end

  context "when application ID matches" do
    let(:q) { application.ecf_id }

    it_behaves_like "a search returning matching applications"
  end

  context "when declaration ID matches" do
    let(:q) { declarations.first.ecf_id }

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
