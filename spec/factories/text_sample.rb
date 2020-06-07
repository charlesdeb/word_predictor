# frozen_string_literal: true

FactoryBot.define do
  # This will guess the TextSample class
  factory :text_sample do
    description { 'Three words' }
    text { 'Mack the knife' }
  end

  factory :text_sample_two_chars, class: TextSample do
    description { 'Two characters' }
    text { 'At' }
  end

  factory :text_sample_three_chars, class: TextSample do
    description { 'Three characters' }
    text { 'The' }
  end

  factory :text_sample_two_tokens, class: TextSample do
    description { 'Two tokens' }
    text { 'Hey!' }
  end

  factory :text_sample_three_tokens, class: TextSample do
    description { 'Three tokens' }
    text { 'Hey dude' }
  end
end
