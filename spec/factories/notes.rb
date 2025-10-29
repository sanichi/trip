FactoryBot.define do
  factory :note do
    draft    { [true, false].sample }
    markdown { Faker::Lorem.paragraphs(number: 3) }
    title    { Faker::Lorem.paragraph.truncate(Note::MAX_TITLE) }
    user
  end
end
