class CreateFundingChoicesEnum < ActiveRecord::Migration[7.1]
  def change
    create_enum :funding_choices, %w[school trust self another employer]
  end
end
