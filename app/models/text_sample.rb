# frozen_string_literal: true

class TextSample < ApplicationRecord
  validates :description, presence: true
  validates :text, presence: true

  def build_word_chunks
    # TODO: it might be better to get the upper limit from a setting, or
    # according to how many unique chunks we got for the previous chunk_size
    chunk_sizes = 2..8

    chunk_sizes.each do |chunk_size|
      build_word_chunks_of_size(chunk_size) unless text.size < chunk_size
    end
  end

  def build_word_chunks_of_size(chunk_size)
    # create a hash
    chunks_hash = build_chunk_hash(chunk_size)

    # store it chunk by chunk in the database
    # TODO: this is very slow and inefficient; storing a single hash per
    # row may be a better solution
    chunks_hash.each do |chunk_text, count|
      WordChunk.create!(
        text: chunk_text, size: chunk_size, count: count, text_sample_id: id
      )
    end
  end

  def build_chunk_hash(chunk_size)
    hash = Hash.new(0)
    limit = text.size - chunk_size
    (0..limit).each do |i|
      # iterate through the text one character at a time
      chunk_text = text[i, chunk_size]
      # increment the count of the chunk we just found
      hash[chunk_text] += 1
    end
    hash
  end
end
