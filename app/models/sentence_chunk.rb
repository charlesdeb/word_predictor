# frozen_string_literal: true

# Much of this code is very similar to that in WordChunk. It may be worth
# refactoring into a Chunk parent class eventually

# for a Sentence Chunk, a 'chunk' is an ordered collection of words, spaces and
# punctuation (all called tokens)
class SentenceChunk < ApplicationRecord
  belongs_to :text_sample

  validates :text, presence: true # may normalise this later
  validates :size, presence: true
  validates :count, presence: true

  CHUNK_SIZE_RANGE = (2..8).freeze

  def self.analyse(text_sample)
    # TODO: it might be better to get the upper limit from a setting, or
    # according to how many unique chunks we got for the previous chunk_size
    chunk_sizes = CHUNK_SIZE_RANGE

    # break the text_sample up into tokens
    text_sample_tokens = split_into_tokens(text_sample.text)
    # puts text_sample_tokens.join

    chunk_sizes.each do |chunk_size|
      unless text_sample_tokens.size < chunk_size
        count_chunks_of_size(text_sample_tokens, text_sample.id, chunk_size)
      end
    end
  end

  # TODO: maybe this should go into some helper method?
  # 'hey, man!'  -> ["hey", ",", " ", "man", "!"]
  #
  # we could make this simpler just by breaking on spaces and ditching
  # punctuation eg 'hey, man!' -> ["hey", "man"]
  # text_sample_tokens = text_sample.text
  #                                 .split(/\s|\p{Punct}/)
  #                                 .compact
  #                                 .reject(&:empty?)
  def self.split_into_tokens(text)
    text
      .split(/(\s)|(\p{Punct})/)
      .compact
      .reject(&:empty?)
  end

  def self.count_chunks_of_size(
    sentence_chunks, text_sample_id, chunk_size
  )
    chunks_hash = build_chunks_hash(sentence_chunks, chunk_size)

    save_chunks(chunks_hash, text_sample_id, chunk_size, :insert_all)
  end

  def self.build_chunks_hash(sentence_chunks, chunk_size)
    hash = Hash.new(0)
    limit = sentence_chunks.size - chunk_size
    (0..limit).each do |i|
      # iterate through the sentence chunks one token at a time
      chunk_text = sentence_chunks[i, chunk_size].join
      # increment the count of the chunk we just found
      hash[chunk_text] += 1
    end
    hash
  end

  def self.save_chunks(chunk_hash, text_sample_id, chunk_size, save_strategy); end
end
