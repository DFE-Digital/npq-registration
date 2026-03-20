class BulkOperation::UploadEligibilityList::RiseSchool < BulkOperation::UploadEligibilityList
  def eligibility_list_type_class
    EligibilityList::RiseSchool
  end
end
