require "rails_helper"

RSpec.describe ReleaseNotes do
  it "parses release notes" do
    release_notes = ReleaseNotes.new(
      markdown: <<~RELEASE_NOTES,
        # Release notes

        If you have any questions or comments...

        ## 13 August 2024

        First paragraph: [some link](https://example.com/)

        Second paragraph

        ## 10 August 2024

        Second note

      RELEASE_NOTES
    )

    latest = release_notes.latest
    expect(latest.date).to eq("13 August 2024")
    expect(latest.content).to eq("<p class=\"govuk-body-m\">First paragraph: <a href=\"https://example.com/\" class=\"govuk-link\">some link</a></p>")
  end

  it "parses release notes from a file" do
    expect { described_class.new.latest }.not_to raise_error
  end
end
