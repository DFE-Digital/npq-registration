require "rails_helper"

RSpec.describe SchoolsController do
  {
    "/faqs/early-years" => [
      "What do I need to register for the NPQ for Early Years Leadership",
      "I need more support",
    ],
    "/faqs/schools" => [
      "What do I need before registering for an NPQ",
      "I need more support",
    ],
    "/faqs/other-users" => [
      "What do I need before registering for an NPQ?",
      "I need more support",
    ],
  }.each do |path, questions|
    describe path do
      before { get(path) }

      it "renders the table of contents" do
        expect(response.body).to match("Contents")
        expect(response.body).to match("Frequently asked questions")
      end

      it "renders the questions correctly" do
        questions.each { |q| expect(response.body).to match(q) }
      end
    end
  end
end
