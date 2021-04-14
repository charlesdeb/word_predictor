# frozen_string_literal: true

# Much of this code is very similar to that in WordChunk. It may be worth
# refactoring into a Chunk parent class eventually

# for a Sentence Chunk, a 'chunk' is an ordered collection of words, spaces and
# punctuation (all called tokens)
class SentenceChunk < ApplicationRecord
  belongs_to :text_sample

  validates :token_ids, presence: true # may normalise this later, or convert to a serializable column type
  validates :size, presence: true
  validates :count, presence: true

  serialize(:token_ids, Array)

  CHUNK_SIZE_RANGE = (2..8).freeze

  def self.analyse(text_sample)
    # TODO: it might be better to get the upper limit from a setting, or
    # according to how many unique chunks we got for the previous chunk_size
    chunk_sizes = CHUNK_SIZE_RANGE

    # break the text_sample up into an array of token IDs
    text_sample_token_ids = Token.id_ise(text_sample.text, :sentence)

    chunk_sizes.each do |chunk_size|
      next if text_sample_token_ids.size < chunk_size

      count_chunks(text_sample_token_ids, text_sample.id, chunk_size)
    end
  end

  def self.count_chunks(token_ids, text_sample_id, chunk_size)
    chunks_hash = build_chunks_hash(token_ids, chunk_size)

    save_chunks(chunks_hash, text_sample_id, chunk_size, :insert_all)
  end

  def self.build_chunks_hash(token_ids, chunk_size)
    hash = Hash.new(0)
    limit = token_ids.size - chunk_size
    (0..limit).each do |i|
      # iterate through the sentence chunks one token at a time
      # chunk_text = token_ids[i, chunk_size].join
      chunk_text = token_ids[i, chunk_size]
      # increment the count of the chunk we just found
      # use fetch to retrieve hash values if the array is a key
      # h = {[1]=> 2}
      # h.fetch([1])   #  => 2
      hash[chunk_text] += 1
    end
    hash
  end

  def self.save_chunks(chunks_hash, text_sample_id, chunk_size, save_strategy = :insert_all)
    case save_strategy
    when :insert_all
      # uses lots of database rows
      save_chunks_by_insert_all(chunks_hash, text_sample_id, chunk_size)
    # when :create!
    #   # VEEERY slow and uses lots of DB rows
    #   save_chunks_by_create(chunks_hash, text_sample_id, chunk_size)
    else
      raise "Unknown save_strategy: #{save_strategy}"
    end
  end

  def self.save_chunks_by_insert_all(  # rubocop:disable Metrics/MethodLength
    chunks_hash, text_sample_id, chunk_size
  )
    current_time = DateTime.now
    import_array = []
    chunks_hash.each do |token_ids, count|
      import_hash = {
        token_ids: token_ids,
        size: chunk_size,
        count: count,
        text_sample_id: text_sample_id,
        created_at: current_time,
        updated_at: current_time
      }
      import_array << import_hash
    end
    SentenceChunk.insert_all! import_array
  end
end
