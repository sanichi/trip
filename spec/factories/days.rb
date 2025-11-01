FactoryBot.define do
  factory :day do
    trip
    date { trip.start_date + rand(0..(trip.end_date - trip.start_date).to_i).days }
    title { Faker::Lorem.sentence(word_count: 3).truncate(Day::MAX_TITLE) }
    draft { [true, false].sample }
    notes { Faker::Lorem.paragraph(sentence_count: 3) }
  end
end
