require "rails_helper"

RSpec.describe Services::Exporters::UsersWithTrn do
  around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = original_stdout
  end

  describe "#call" do
    let(:user) { create(:user, ecf_id: "12345") }
    let(:application) { create(:application, user: user) }

    before do
      application
      create(:user)
    end

    it "outputs headers" do
      subject.call

      expect($stdout.string).to include("participant_id,user_id,trn")
    end

    it "outputs correct number of rows" do
      subject.call

      expect($stdout.string.lines.size).to eql(2)
    end

    it "outputs correct data" do
      subject.call

      expect($stdout.string).to include("#{user.ecf_id},#{user.id},#{user.trn}")
    end
  end
end
