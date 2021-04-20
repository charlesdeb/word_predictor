# frozen_string_literal: true

FactoryBot.define do
  factory :sentence_chunk, class: SentenceChunk do
    size { 2 }
    token_ids { [1, 2] }
    count { 1 }
    # text_sample_two_chars
    association :text_sample, factory: :text_sample_two_chars
  end
end
