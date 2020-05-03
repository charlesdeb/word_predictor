# frozen_string_literal: true

class WordChunk < ApplicationRecord
  belongs_to :text_sample

  validates :text, presence: true
  validates :size, presence: true
  validates :count, presence: true

  def self.choose_starting_word_chunk(text_sample, chunk_size)
    candidates = WordChunk
                 .where({ text_sample_id: text_sample.id, size: chunk_size })
                 .limit(nil)
    candidates[(rand * candidates.size).to_i]
  end

  # Choose the next word chunk after this one
  def choose_next_word_chunk
    chunk_head = "#{text[1..-1]}%"

    candidates = WordChunk
                 .where('text_sample_id = :text_sample_id AND size = :word_chunk_size AND text LIKE :chunk_head',
                        text_sample_id: text_sample.id, word_chunk_size: size,
                        chunk_head: chunk_head)
                 .limit(nil)

    WordChunk.choose_word_chunk_from_candidates(candidates)
  end

  def self.choose_word_chunk_from_candidates(candidates)
    counts_array = WordChunk.build_counts_array(candidates)

    counts_array[(rand * counts_array.size).to_i]
  end

  def self.build_counts_array(candidates)
    counts_array = []
    candidates.each do |word_chunk|
      word_chunk.count.times { counts_array.push(word_chunk) }
    end
    counts_array
  end
end
