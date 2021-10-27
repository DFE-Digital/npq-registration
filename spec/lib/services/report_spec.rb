require "rails_helper"

RSpec.describe Services::Report do
  before do
    create(:application, school: nil)
  end

  describe "#call" do
    context "for international applications without a school" do
      it "does not raise an error" do
        expect { subject.call }.not_to raise_error
      end
    end
  end
end
