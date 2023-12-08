class StatementLineItem < ApplicationRecord
  belongs_to :statement_id
  belongs_to :declaration
end
