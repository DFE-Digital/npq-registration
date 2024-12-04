def mock_previous_funding(previously_funded:, previously_received_targeted_funding_support: false)
  allow_any_instance_of(FundingEligibility).to receive_messages(
    funding_eligiblity_status_code: (previously_funded ? :previously_funded : :funded),
    "funded?": !previously_funded,
    "previously_received_targeted_funding_support?": previously_received_targeted_funding_support,
  )
end
