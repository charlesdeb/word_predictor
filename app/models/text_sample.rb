# frozen_string_literal: true

class TextSample < ApplicationRecord
  validates :description, presence: true
  validates :text, presence: true

  def build_word_chunks
    chunk_sizes = 2..8

    chunk_sizes.each do |chunk_size|
      build_word_chunks_of_size(chunk_size) unless text.size < chunk_size
    end
  end

  def build_word_chunks_of_size(chunk_size)
    chunks_hash = build_chunk_hash(chunk_size)

    chunks_hash.each do |chunk_text, count|
      WordChunk.create!(
        text: chunk_text, size: chunk_size, count: count, text_sample_id: id
      )
    end
  end

  def build_chunk_hash(chunk_size); end
end
