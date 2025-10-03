class AddShortCodeToCourses < ActiveRecord::Migration[7.2]
  # Two courses do not have short codes:
  # - npq-early-headship-coaching-offer
  # - npq-additional-support-offer
  SHORT_CODES = {
    "npq-leading-teaching" => "NPQLT",
    "npq-leading-behaviour-culture" => "NPQLBC",
    "npq-leading-teaching-development" => "NPQLTD",
    "npq-leading-literacy" => "NPQLL",
    "npq-senior-leadership" => "NPQSL",
    "npq-headship" => "NPQH",
    "npq-executive-leadership" => "NPQEL",
    "npq-early-years-leadership" => "NPQEYL",
    "npq-leading-primary-mathematics" => "NPQLPM",
    "npq-senco" => "NPQSENCO",
  }.freeze

  def up
    add_column :courses, :short_code, :string

    safety_assured do
      SHORT_CODES.each do |identifier, short_code|
        execute "UPDATE courses SET short_code = '#{short_code}' WHERE identifier = '#{identifier}'"
      end
    end
  end

  def down
    remove_column :courses, :short_code
  end
end
