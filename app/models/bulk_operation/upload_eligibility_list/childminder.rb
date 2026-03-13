class BulkOperation::UploadEligibilityList::Childminder < BulkOperation::UploadEligibilityList
  def eligibility_list_type_class
    EligibilityList::Childminder
  end
end
