FactoryBot.define do
  factory :trip do
    title      { Faker::Lorem.sentence(word_count: 3).truncate(Trip::MAX_TITLE) }
    start_date { Faker::Date.backward(days: 365) }
    end_date   { start_date + rand(1..Trip::MAX_DAYS).days }
    user
  end
end
