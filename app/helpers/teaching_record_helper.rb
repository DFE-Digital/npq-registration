module TeachingRecordHelper
  def trs_person_url(trn)
    return nil if trn.blank?

    %(#{ENV.fetch("TRS_URL")}/persons?Search=#{trn})
  end

  def trs_search_url
    %(#{ENV.fetch("TRS_URL")}/persons)
  end
end
