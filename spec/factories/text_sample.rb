# This will guess the TextSample class
FactoryBot.define do
  factory :text_sample_simple, class: TextSample do
    description { 'Simple' }
    text { 'The man in the mirror' }
  end
end
