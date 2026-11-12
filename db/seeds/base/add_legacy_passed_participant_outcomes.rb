FactoryBot.create(:legacy_passed_participant_outcome, trn: "1234567", completion_date: Date.parse("2020-01-01"))
FactoryBot.create(:legacy_passed_participant_outcome, trn: "1234567", course_short_code: "NPQML", completion_date: Date.parse("2020-02-02"))
user = User.first
FactoryBot.create(:legacy_passed_participant_outcome, trn: user.trn, completion_date: Date.parse("2020-03-03"))
FactoryBot.create(:legacy_passed_participant_outcome, trn: user.trn, course_short_code: "NPQML", completion_date: Date.parse("2020-04-04"))
