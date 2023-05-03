module Email
  class Rules
    def self.call
      new.call
    end

    def call
      fetch_content
    end

  private

    def mapping
      {
        # "Eligible for EHCO scholarship funding"
        ehco_scholarship_funding: "b0eaf5fb-b94b-4846-ac44-105f4a7b1462",

        # "Eligible for scholarship funding - eligible for TSF"
        eligible_scholarship_funding: "3c53e545-a913-49de-8be6-8868fbad76ee",

        # "Eligible for scholarship funding - not eligible for TSF"
        eligible_scholarship_funding_not_tsf: "fffee48d-b32f-4a15-82fc-bde3e57214c6",

        # "ITT lead mentor but does not select leading teacher development NPQ"
        itt_leader_wrong_course: "de18c9ae-ca3b-4fd9-852f-c29ac020d9f0",

        # "Not eligible for EHCO scholarship funding (already been funded)"
        already_funded_not_elgible_ehco_funding: "7553f6b9-9927-479c-a47d-6e1e81bdeb97",

        # "Not eligible for EHCO scholarship funding (not in England/ not in first 5 years of headship/ not headteacher/ not in appropriate setting)"
        not_eligible_ehco_funding: "dd52f13e-8050-4348-929f-6347e96f8d6d",

        # "Not eligible for scholarship funding (already been funded) - eligible for TSF"
        not_eligible_scholarship_funding: "46c69236-de05-417c-a76f-e0dfcff48555",

        # "Not eligible for scholarship funding (already been funded) - not eligible for TSF"
        already_funded_not_eligible_scholarship_funding_not_tsf: "d613a40a-de3e-40b8-9683-50777a4ac4a7",

        # "Not eligible for scholarship funding - not eligible for TSF"
        not_eligible_scholarship_funding_not_tsf: "194bb87f-9416-473b-8b32-12e7de92b219",

        # "Not in England - wrong catchment"
        not_england_wrong_ctachment: "be84eb1e-eb8a-4238-9902-d2f9e03ab453",

        # "Not on ofsted register"
        not_on_ofsted_register: "8b93927b-d6a2-4830-b3dc-8b6c4434aaf5",

        # "On Ofsted register but not NPQEYL"
        not_npqeyl_on_ofsted_register: "ab884951-b418-4771-a9ea-a4f4b03a633a",
      }
    end
  end
end
