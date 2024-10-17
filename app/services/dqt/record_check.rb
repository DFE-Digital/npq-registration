# frozen_string_literal: true

module Dqt
  class RecordCheck
    TITLES = %w[mr mrs miss ms dr prof rev].freeze

    CheckResult = Struct.new(
      :dqt_record,
      :trn_matches,
      :name_matches,
      :dob_matches,
      :nino_matches,
      :total_matched,
      :failure_reason,
    )

    def call
      check_record
    end

  private

    attr_reader :trn, :nino, :full_name, :date_of_birth, :check_first_name_only

    def initialize(trn:, full_name:, date_of_birth:, nino: nil, check_first_name_only: true)
      @trn = trn
      @full_name = full_name&.strip
      @date_of_birth = date_of_birth
      @nino = nino
      @check_first_name_only = check_first_name_only
    end

    def dqt_record(padded_trn)
      V1::Teacher.find(trn: padded_trn, nino:, birthdate: date_of_birth)
    end

    def check_record
      return check_failure(:trn_and_nino_blank) if trn.blank? && nino.blank?

      @trn = "0000001" if trn.blank?

      padded_trn = TeacherReferenceNumber.new(trn).formatted_trn
      dqt_record = TeacherRecord.new(dqt_record(padded_trn))

      return check_failure(:no_match_found) if dqt_record.blank?
      return check_failure(:found_but_not_active) unless dqt_record.active?

      trn_matches = dqt_record.trn == padded_trn
      name_matches = name_matches?(dqt_name: dqt_record.name)
      dob_matches = dqt_record.dob == date_of_birth
      nino_matches = nino.present? && nino.downcase == dqt_record.ni_number&.downcase

      matches = [trn_matches, name_matches, dob_matches, nino_matches].count(true)

      if matches >= 3
        CheckResult.new(dqt_record, trn_matches, name_matches, dob_matches, nino_matches, matches)
      elsif matches < 3 && (trn_matches && trn != "1")
        if matches == 2 && !name_matches && check_first_name_only
          CheckResult.new(dqt_record, trn_matches, name_matches, dob_matches, nino_matches, matches)
        else
          # If a participant mistypes their TRN and enters someone else's, we should search by NINO instead
          # The API first matches by (mandatory) TRN, then by NINO if it finds no results. This works around that.
          @trn = "0000001"
          check_record
        end
      else
        # we found a record but not enough matched
        check_failure(:no_match_found)
      end
    end

    def name_matches?(dqt_name:)
      return false if full_name.blank?
      return false if full_name.in?(TITLES)
      return false if dqt_name.blank?

      NameMatcher.new(full_name, dqt_name, check_first_name_only:).matches?
    end

    def check_failure(reason)
      CheckResult.new(nil, false, false, false, false, 0, reason)
    end
  end
end
