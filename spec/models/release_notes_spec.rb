require "rails_helper"

RSpec.describe ReleaseNotes do
  it "parses release notes" do
    release_notes = ReleaseNotes.new(markdown: <<~RELEASE_NOTES,
      # Release notes

      If you have any questions or comments...

      ## 2021-10-10

      First note

      ## 2021-10-09

      Second note

    RELEASE_NOTES

    latest = release_notes.latest
    expect(latest.date).to eq("2021-10-10")
    expect(latest.content).to eq("First note")
  end

  it "parses release notes from a file" do
    expect { ReleaseNotes.new.latest }.not_to raise_error
  end
end
