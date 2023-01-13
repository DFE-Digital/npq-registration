module Services
  module Eligibility
    # Note that this doesn't take into account any details about the user or application. This is
    # just for determining course+institution eligibility. Further checks related to do with the user
    # are performed after this service is called.
    class TargetedDeliveryFunding
      attr_reader :institution, :course, :employment_role

      def initialize(institution:, course:, employment_role: nil)
        @institution = institution
        @course = course
        @employment_role = employment_role
      end

      def call
        return false if institution.nil?
        return true  if eligible_fe_ukprns.include?(institution.ukprn)
        return false if institution.is_a?(LocalAuthority)
        return false if institution.is_a?(PrivateChildcareProvider)
        return false if institution.number_of_pupils.nil?
        return false if institution.number_of_pupils.zero?

        return false if employment_role == "lead_mentor_for_accredited_itt_provider"
        return false unless course.supports_targeted_delivery_funding?

        eligible_establishment_type_codes.include?(institution.establishment_type_code) &&
          institution.number_of_pupils < pupil_count_threshold
      end

    private

      def pupil_count_threshold
        600
      end

      def eligible_establishment_type_codes
        [
          1, # Community school
          2, # Voluntary aided school
          3, # Voluntary controlled school
          5, # Foundation school
          6, # City technology college
          7, # Community special school
          8, # Non-maintained special school
          10, # Other independent special school
          12, # Foundation special school
          14, # Pupil referral unit
          15, # Local authority nursery school
          18, # Further education
          24, # Secure units
          26, # Service children's education
          28, # Academy sponsor led
          31, # Sixth form centres
          32, # Special post 16 institution
          33, # Academy special sponsor led
          34, # Academy converter
          35, # Free schools
          36, # Free schools special
          38, # Free schools alternative provision
          39, # Free schools 16 to 19
          40, # University technical college
          41, # Studio schools
          42, # Academy alternative provision converter
          43, # Academy alternative provision sponsor led
          44, # Academy special converter
          45, # Academy 16-19 converter
          46, # Academy 16 to 19 sponsor led
        ].map(&:to_s)
      end

      def eligible_fe_ukprns
        [
          10_000_350, # Arden College
          10_000_599, # Beaumont College - A Salutem/Ambito College
          10_000_872, # Bridge College
          10_001_538, # Coleg Elidyr
          10_001_867, # The David Lewis Centre
          10_001_929, # Derwen College
          10_002_006, # Communication Specialist College -  Doncaster
          10_002_345, # Education and Services for People with Autism
          10_002_396, # Fairfield Farm College (Fairfield Farm Trust)
          10_002_409, # Farleigh Further Education College - Frome
          10_002_546, # The Fortune Centre of Riding Therapy
          10_003_029, # Hereward College of Further Education
          10_003_136, # Homefield College
          10_003_774, # Landmarks
          10_003_775, # Langdon College
          10_003_940, # Linkage College
          10_004_444, # The Mount Camphill Community Ltd
          10_004_502, # St Piers College (Young Epilepsy)
          10_004_527, # National Star College
          10_004_665, # Works 4 U Support Services (Norman Mackie & Associates Ltd)
          10_004_841, # Oakwood Court College (Phoenix Learning Care Ltd)
          10_005_036, # Camphill Wakefield (Pennine Camphill Community Ltd)
          10_005_151, # Portland College
          10_005_320, # Queen Alexandra College
          10_005_557, # Royal Mencap Society
          10_005_558, # Royal National College for the Blind
          10_005_748, # Sense College
          10_006_159, # St Elizabeth's Centre
          10_006_199, # St. John's College (Brighton)
          10_006_374, # Strathmore College
          10_007_031, # Treloar College
          10_007_111, # Uckfield  College
          10_007_872, # South West Regional Assessment Centre
          10_008_456, # Regent College
          10_009_031, # Ruskin Mill College
          10_009_069, # Dorton College of Further Education
          10_009_111, # Orpheus Centre
          10_009_120, # Condover College Limited
          10_009_777, # Thornbeck College - North East Autism Society
          10_010_025, # ROC College (part of United Response)
          10_012_804, # Cambian Lufton College
          10_012_806, # Pengwern College
          10_012_810, # Livability Nash College
          10_012_814, # Henshaws College
          10_012_822, # Cambian Dilston College
          10_012_825, # Infocus College
          10_019_237, # Activate
          10_021_185, # Groundwork South Tyneside and Newcastle
          10_024_163, # Area 51 Education Ltd
          10_024_771, # Exeter Royal Academy for Deaf Education
          10_024_772, # Royal College Manchester (Seashell Trust)
          10_025_914, # Glasshouse College
          10_025_915, # Freeman College
          10_027_379, # Cambian Wing College
          10_027_384, # Sense College Loughborough
          10_028_480, # The Autism Project - CareTrade
          10_028_500, # Bemix
          10_032_448, # Eat That Frog C.I.C
          10_032_637, # Novalis Trust
          10_032_898, # Trinity Specialist College
          10_038_981, # Sheiling College
          10_040_374, # St Martins Centre (St Roses School)
          10_040_375, # Lakeside Early Adult Provision - LEAP College (Wargrave House Ltd)
          10_041_170, # Expanse Learning (Expanse Group Ltd)
          10_041_272, # Liberty Training
          10_041_294, # White Rocks Farm
          10_043_186, # Fir Tree Fishery CIC
          10_044_455, # TMP Studios CIC
          10_044_946, # Brogdale CIC
          10_045_935, # SupaJam Education In Music and Media
          10_046_350, # Big Creative Academy
          10_046_840, # Heart of Birmingham Vocational College
          10_046_853, # Lifeworks College
          10_048_022, # Percy Hedley Hedleys College
          10_048_265, # Ambitious College
          10_049_051, # Chatsworth Futures Limited
          10_054_747, # Orchard Hill College of Further Education
          10_055_015, # LifeBridge ASEND
          10_055_371, # Community College Initiative Ltd
          10_055_517, # My Life Learning
          10_055_888, # Trinity Solutions Academy
          10_056_251, # Brentwood Community College
          10_056_799, # Trinity Post 16 Solutions Ltd.
          10_056_854, # Wilson Stuart University College Birmingham Partnership Trust
          10_057_205, # The Ridge Employability College
          10_057_307, # Woodpecker Court
          10_057_981, # Ada National College for Digital Skills
          10_063_538, # Chadsgrove Educational Trust Specialist College
          10_064_084, # Health Education England
          10_064_516, # Calman Colaiste (Kisimul Group)
          10_067_032, # Lighthouse Futures Trust
          10_067_033, # Catcote Futures
          10_067_343, # KMS Kent Ltd
          10_067_359, # Victoria College
          10_067_674, # LINK19 College
          10_067_684, # Routes4Life Limited
          10_067_746, # Aurora Boveridge College
          10_067_747, # Woodbridge College
          10_067_866, # The Michael Tippett College
          10_067_932, # Phoenix Autism Trust
          10_068_178, # Downs View Life Skills College
          10_068_204, # Newfriars College
          10_068_348, # Great Oaks Charitable Trust T/A Great Oaks College
          10_082_882, # Future Horizons Leeds Ltd
          10_083_399, # ROTHERHAM OPPORTUNITIES COLLEGE
          10_083_456, # Grow 19 LTD
          10_083_475, # Folkestone Beacon Plus
          10_083_544, # FORWARD2 EMPLOYMENT LIMITED
          10_083_841, # Q+
          10_084_353, # Valley College
          10_084_430, # Horizons College
          10_086_392, # The Park College
          10_088_608, # Willow Green CIO
          10_088_810, # Employ My Ability (EMA) Ltd
          10_089_242, # Richard Huish College
        ].map(&:to_s)
      end
    end
  end
end
