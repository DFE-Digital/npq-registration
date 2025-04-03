# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Root path" do
  subject { response }

  before { get root_path }

  it { is_expected.to have_http_status :success }
  it { expect(response.headers).to include "cache-control" => "no-store" }
end
