# Logging the information provided as part of the completed
# declaration
#
# If they pass we pass the info over to the DQT via the API
#
# Outcomes can be updates if the situation changes
class Outcome < ApplicationRecord
  belongs_to :declaration

  # "completion_date" normally the same date as the final
  # declaration but can be subsequently updated via the API (via POST to
  # npq/{id}/outcomes)
  #
  # There's an additional table called outcome_api_requests that logs
  # the status of API requests sent to DQT, it's used for debugging
  # and logging. Do we need it?
end
