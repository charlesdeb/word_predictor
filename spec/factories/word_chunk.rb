# frozen_string_literal: true

FactoryBot.define do
  factory :word_chunk, class: WordChunk do
    size { 2 }
    text { 'At' }
    count { 1 }
    # text_sample_two_chars
    association :text_sample, factory: :text_sample_two_chars
  end
end
