# frozen_string_literal: true

# This will guess the TextSample class
FactoryBot.define do
  factory :text_sample_two_chars, class: TextSample do
    description { 'Two characters' }
    text { 'At' }
  end

  factory :text_sample_three_chars, class: TextSample do
    description { 'Three characters' }
    text { 'The' }
  end
end
