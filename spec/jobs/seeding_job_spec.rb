require "rails_helper"

RSpec.describe SeedingJob do
  load(Rails.root.join("db/seeds/base/add_applications.rb"))
  load(Rails.root.join("db/seeds/base/add_declarations.rb"))

  describe "#perform" do
    let(:add_applications_stub) { instance_double(SeedAddApplications, load: nil) }
    let(:add_declarations_stub) { instance_double(SeedAddDeclarations, load: nil) }
    let(:environment) { "review" }

    before do
      allow(SeedingJob).to receive(:set).and_return(SeedingJob)
      allow(SeedAddApplications).to receive(:new).and_return(add_applications_stub)
      allow(SeedAddDeclarations).to receive(:new).and_return(add_declarations_stub)
      allow(Rails).to receive(:env) { environment.inquiry }
    end

    context "when the repetitions argument is not used" do
      subject(:run_job) { described_class.new.perform }

      it "seeds applications" do
        expect(add_applications_stub).to receive(:load).with(multiplier: 30)
        subject
      end

      it "seeds declarations" do
        expect(add_declarations_stub).to receive(:load).with(multiplier: 30)
        subject
      end
    end

    context "when the environment is production" do
      let(:environment) { "production" }

      subject(:run_job) { described_class.new.perform }

      it "does not perform any seeding" do
        expect(add_applications_stub).not_to receive(:load)
        expect(add_declarations_stub).not_to receive(:load)
        subject
      end
    end
  end
end
