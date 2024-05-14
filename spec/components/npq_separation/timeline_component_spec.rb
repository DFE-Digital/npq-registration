require "rails_helper"

RSpec.describe NpqSeparation::TimelineComponent, type: :component do
  let(:one_day_ago) { FactoryBot.build(:event, :with_byline, created_at: 1.day.ago) }
  let(:two_days_ago) { FactoryBot.build(:event, :with_byline, created_at: 2.days.ago) }
  let(:three_days_ago) { FactoryBot.build(:event, :with_byline, created_at: 3.days.ago) }
  let(:events) { [two_days_ago, one_day_ago, three_days_ago] }

  subject { NpqSeparation::TimelineComponent.new(events) }

  before { render_inline(subject) }

  context "when the events aren't in choronological order" do
    it "orders the events by created_at on initialization" do
      expect(subject.events).to eql(events.sort_by(&:created_at))
    end
  end

  it "displays all of the events in a timeline" do
    expect(rendered_content).to have_css(".app-timeline__item", count: events.size)
  end

  it "shows a timestamp for each event" do
    events.each do |event|
      expect(rendered_content).to have_css("time", text: event.created_at.to_fs(:govuk_short))
      expect(rendered_content).to have_css("time[datetime='#{event.created_at.to_fs(:iso8601)}']")
    end
  end

  it "shows the title and byline in the header" do
    events.each do |event|
      expect(rendered_content).to have_css(".app-timeline__header > .app-timeline__title", text: event.title)
      expect(rendered_content).to have_css(".app-timeline__header > .app-timeline__byline", text: event.byline)
    end
  end
end
