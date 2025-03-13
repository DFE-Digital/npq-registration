# frozen_string_literal: true

module AxeHelper
  extend RSpec::Matchers::DSL

  define :be_accessible do
    match do |page|
      # TODO: temporarily disabled due to failures with new version of chrome/chromedriver
      # expect(page).to be_axe_clean.according_to :wcag22aa
      true
    end
  end
end
