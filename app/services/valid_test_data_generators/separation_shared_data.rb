# frozen_string_literal: true

module ValidTestDataGenerators
  class SeparationSharedData < ApplicationsPopulater
    SHARED_USERS = {
      "LLSE" => [
        { name: "Caleb Abbott MD", email: "caleb_md_abbott@deckow.io", trn: "9999006", date_of_birth: "1971-02-09", ecf_id: "4abe57c4-f2b7-45bb-ab5b-cc78b235ab81" },
        { name: "Dr. Israel Lang", email: "lang_israel_dr@donnelly-erdman.org", trn: "9999007", date_of_birth: "1960-01-05", ecf_id: "1253dec4-e7c8-4795-b1f1-29736cec37af" },
        { name: "Fr. Monroe Jerde", email: "fr_jerde_monroe@jaskolski.com", trn: "9999008", date_of_birth: "1986-07-01", ecf_id: "ce24b3ff-6d73-424b-926c-4e31e84add60" },
        { name: "Karon Runolfsson", email: "karon.runolfsson@block-rolfson.com", trn: "9999009", date_of_birth: "1980-07-31", ecf_id: nil },
        { name: "Leila Beer", email: "beer.leila@mante.co", trn: "9999010", date_of_birth: "1969-02-22", ecf_id: nil },
        { name: "Dr. Vinita Mosciski", email: "mosciski_vinita_dr@hermiston-johns.info", trn: "9999011", date_of_birth: "1970-10-10", ecf_id: nil },
      ],
      "Teacher Development Trust" => [
        { name: "Charity Bergstrom", email: "charity.bergstrom@simonis.com", trn: "9999012", date_of_birth: "1974-03-13", ecf_id: "5331709b-af99-4a9c-8e84-04f6df94ac25" },
        { name: "Lanelle Will", email: "lanelle_will@roberts.org", trn: "9999013", date_of_birth: "1988-07-18", ecf_id: "4e5cf943-d59c-465e-a820-600935c9dbaa" },
        { name: "Chas McDermott DO", email: "chas.do.mcdermott@howe-harris.co", trn: "9999014", date_of_birth: "1970-12-28", ecf_id: "c5e8af3d-4346-4db6-956a-da838eb38232" },
        { name: "Fr. Porfirio Huel", email: "huel.porfirio.fr@schuppe.com", trn: "9999015", date_of_birth: "1960-03-19", ecf_id: nil },
        { name: "Wendie Harvey", email: "harvey_wendie@brakus-olson.biz", trn: "9999016", date_of_birth: "1985-07-30", ecf_id: nil },
        { name: "Normand Carter", email: "normand_carter@herzog.biz", trn: "9999017", date_of_birth: "1980-04-19", ecf_id: nil },
      ],
      "National Institute of Teaching" => [
        { name: "Major Satterfield", email: "major.satterfield@roberts-larkin.com", trn: "9999018", date_of_birth: "1966-01-04", ecf_id: "d11ddf46-5850-4de4-b4e8-bbccb07f2056" },
        { name: "Abram Bauch", email: "bauch.abram@hyatt.io", trn: "9999019", date_of_birth: "1990-07-18", ecf_id: "7ce449b3-360d-4eeb-bc73-1c0c6fac48a7" },
        { name: "Noe Goodwin", email: "noe.goodwin@schamberger.com", trn: "9999020", date_of_birth: "1995-04-02", ecf_id: "3bf47d05-bc75-4e9b-afbc-d36134d93880" },
        { name: "Russ Cremin", email: "cremin_russ@farrell-jacobi.co", trn: "9999021", date_of_birth: "1962-05-02", ecf_id: nil },
        { name: "Bryon Prosacco", email: "prosacco.bryon@toy-daugherty.net", trn: "9999022", date_of_birth: "1970-08-26", ecf_id: nil },
        { name: "Cornell Kris III", email: "kris.cornell.iii@hyatt.org", trn: "9999023", date_of_birth: "1980-06-30", ecf_id: nil },
      ],
      "Best Practice Network" => [
        { name: "Wen Block", email: "block_wen@batz.com", trn: "9999024", date_of_birth: "1978-05-30", ecf_id: "ea810e48-98b7-454a-be00-3a35fdd73685" },
        { name: "Grayce Pouros", email: "grayce_pouros@mertz.info", trn: "9999025", date_of_birth: "1961-04-22", ecf_id: "9dc0c8a7-f68b-4cfa-9d57-108ed38b458c" },
        { name: "Orlando Upton", email: "orlando.upton@jaskolski-pagac.org", trn: "9999026", date_of_birth: "1965-07-27", ecf_id: "971f320d-3a56-48fa-9b57-b5c1cd39898a" },
        { name: "Debbra Koepp", email: "koepp_debbra@abernathy-russel.name", trn: "9999027", date_of_birth: "1960-11-12", ecf_id: nil },
        { name: "Ardis Connelly JD", email: "jd_ardis_connelly@mertz-watsica.net", trn: "9999028", date_of_birth: "1966-05-10", ecf_id: nil },
        { name: "Vicente Friesen", email: "friesen_vicente@moen-conn.net", trn: "9999029", date_of_birth: "1989-10-24", ecf_id: nil },
      ],
      "Church of England" => [
        { name: "Jeana Beer DVM", email: "jeana_beer_dvm@romaguera.com", trn: "9999030", date_of_birth: "1995-09-13", ecf_id: "c2c6061c-666c-4bc9-a742-3bb98ef352d9" },
        { name: "Thi Herzog", email: "thi_herzog@barrows.com", trn: "9999031", date_of_birth: "1983-09-21", ecf_id: "0d5609ba-d975-45da-9b55-0d1b7ab338bb" },
        { name: "Hank Steuber Jr.", email: "jr_hank_steuber@larson-steuber.info", trn: "9999032", date_of_birth: "1969-03-24", ecf_id: "01eb5b14-7294-462a-b885-715f829f0a0e" },
        { name: "Genevieve Schaefer", email: "schaefer_genevieve@hintz.net", trn: "9999033", date_of_birth: "1966-03-21", ecf_id: nil },
        { name: "Shane Thompson", email: "thompson.shane@stokes.io", trn: "9999034", date_of_birth: "1973-08-23", ecf_id: nil },
        { name: "Rachelle Shanahan", email: "shanahan_rachelle@frami-hoeger.biz", trn: "9999035", date_of_birth: "1991-01-21", ecf_id: nil },
      ],
      "Ambition Institute" => [
        { name: "Sen. Jettie Hammes", email: "jettie.hammes.sen@rohan.com", trn: "9999036", date_of_birth: "1963-12-23", ecf_id: "a330a796-82b1-4e0f-87a6-753174c30e32" },
        { name: "Dr. Numbers Lakin", email: "numbers_dr_lakin@wolf.biz", trn: "9999037", date_of_birth: "1981-05-29", ecf_id: "387fdcd4-2d89-46a0-8263-76cc7c73a488" },
        { name: "Sen. Shaunte Dicki", email: "shaunte_sen_dicki@upton.io", trn: "9999038", date_of_birth: "1992-04-23", ecf_id: "c30f95c9-d29c-4008-b9a1-173ddf7b3122" },
        { name: "Joesph Bradtke", email: "joesph_bradtke@schuppe.info", trn: "9999039", date_of_birth: "1973-05-01", ecf_id: nil },
        { name: "Amb. Sam Mante", email: "amb_mante_sam@rogahn.org", trn: "9999040", date_of_birth: "1995-09-08", ecf_id: nil },
        { name: "Tommy Bailey", email: "bailey.tommy@kozey.info", trn: "9999041", date_of_birth: "1992-10-01", ecf_id: nil },
      ],
      "Teach First" => [
        { name: "Prof. Shaquita Windler", email: "windler.prof.shaquita@prosacco-parker.net", trn: "9999042", date_of_birth: "1973-02-24", ecf_id: "36c88a03-46af-4a89-83dc-8b34bc98281e" },
        { name: "Frances Ankunding LLD", email: "ankunding_frances_lld@blick.name", trn: "9999043", date_of_birth: "1966-03-01", ecf_id: "032c45fa-dc44-4f3f-a24c-d829d2a35772" },
        { name: "Daisy Wuckert", email: "wuckert_daisy@lubowitz.net", trn: "9999044", date_of_birth: "1976-12-08", ecf_id: "0c9ab4f3-c65a-45c5-a46b-3ba64b8194f7" },
        { name: "Clemente Pacocha", email: "clemente_pacocha@gleason.net", trn: "9999045", date_of_birth: "1993-06-17", ecf_id: nil },
        { name: "Philip Yundt", email: "philip_yundt@cassin.net", trn: "9999046", date_of_birth: "1964-09-30", ecf_id: nil },
        { name: "Tandy Jerde", email: "tandy.jerde@balistreri-kunze.name", trn: "9999047", date_of_birth: "1976-06-24", ecf_id: nil },
      ],
      "School-Led Network" => [
        { name: "Boyd Crist", email: "boyd_crist@oreilly.name", trn: "9999048", date_of_birth: "1966-02-21", ecf_id: "0b9f7208-8ac9-4ab3-966b-81e77265500b" },
        { name: "Alfonzo Kreiger", email: "kreiger_alfonzo@kunde-padberg.name", trn: "9999049", date_of_birth: "1960-01-19", ecf_id: "ffe120a4-b341-4244-bdc0-cfdec325f8ca" },
        { name: "Dr. Numbers Kulas", email: "kulas.dr.numbers@bednar.name", trn: "9999050", date_of_birth: "1997-06-08", ecf_id: "98e71c3b-91ed-40d6-97ff-14084afba94b" },
        { name: "Fr. Terisa Wiegand", email: "fr.wiegand.terisa@balistreri.info", trn: "9999051", date_of_birth: "1990-01-30", ecf_id: nil },
        { name: "Troy Frami", email: "troy_frami@schmitt.com", trn: "9999052", date_of_birth: "1986-08-17", ecf_id: nil },
        { name: "Leon Boyer", email: "leon_boyer@lowe.biz", trn: "9999053", date_of_birth: "1985-12-12", ecf_id: nil },
      ],
      "University College London (UCL) Institute of Education" => [
        { name: "Seth Mann", email: "seth_mann@howe.io", trn: "9999054", date_of_birth: "1972-11-22", ecf_id: "4764a600-99f7-4fec-8585-7c286bafa9f3" },
        { name: "Joan Orn", email: "joan.orn@feil.com", trn: "9999055", date_of_birth: "1976-11-01", ecf_id: "e074f1c0-a175-4b35-84ab-97472fd228a3" },
        { name: "Lisette Beahan", email: "lisette.beahan@tillman.org", trn: "9999056", date_of_birth: "1967-07-05", ecf_id: "247c46d7-b6c2-4e99-95ca-b38589cbf4ea" },
        { name: "Joaquin Lockman", email: "joaquin_lockman@stoltenberg.co", trn: "9999057", date_of_birth: "1977-05-07", ecf_id: nil },
        { name: "Alissa Wuckert", email: "alissa_wuckert@reilly.name", trn: "9999058", date_of_birth: "1972-02-05", ecf_id: nil },
        { name: "Tova Schulist", email: "schulist.tova@reichel-pfannerstill.io", trn: "9999059", date_of_birth: "1975-11-10", ecf_id: nil },
      ],
    }.freeze

    class << self
      def populate(lead_provider:, cohort:)
        new(lead_provider:, cohort:).populate
      end
    end

    def populate
      return unless Rails.env.in?(%w[development review separation])

      logger.info "SeparationSharedData: Started!"

      ActiveRecord::Base.transaction do
        create_participants!
      end

      logger.info "SeparationSharedData: Finished!"
    end

  private

    def initialize(lead_provider:, cohort:, logger: Rails.logger)
      @lead_provider = lead_provider
      @cohort = cohort
      @logger = logger
      @courses = Course.all.reject { |c| c.identifier == "npq-additional-support-offer" }
    end

    def create_participants!
      SHARED_USERS[lead_provider.name].each do |user_params|
        school = School.open.order("RANDOM()").first
        user = shared_participant_identity(user_params)

        create_participant(user:, school:)
      end
    end

    def shared_participant_identity(params)
      user = if params[:ecf_id].present?
               User.find_or_initialize_by(ecf_id: params[:ecf_id])
             else
               User.find_or_initialize_by(email: params[:email])
             end

      user.update!(
        full_name: params[:name],
        email: params[:email],
        trn: params[:trn],
        date_of_birth: params[:date_of_birth],
      )

      user
    end
  end
end