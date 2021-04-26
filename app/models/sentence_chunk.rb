# frozen_string_literal: true

# Much of this code is very similar to that in WordChunk. It may be worth
# refactoring into a Chunk parent class eventually

# for a Sentence Chunk, a 'chunk' is an ordered collection of words, spaces and
# punctuation (all called tokens)
class SentenceChunk < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :text_sample

  validates :token_ids, presence: true # may normalise this later
  validates :size, presence: true
  validates :count, presence: true

  # serialize(:token_ids, Array)

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

  def self.save_chunks_by_insert_all( # rubocop:disable Metrics/MethodLength
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

  def self.reanalyse(text_sample)
    # clear out anything from previous analysis
    SentenceChunk.where('text_sample_id = ?', text_sample.id).delete_all
    SentenceChunk.analyse(text_sample)
  end

  # Entry point for generating text using the sentence chunk strategy
  #
  # @param [Hash] params parameters to generate with
  # @option [Integer] chunk_size chunk size to use for generation
  # @option [Integer] token_size number of tokens to generate
  # @option [Integer] text_sample_id TextSample to use as the model
  def self.generate(params = {}) # rubocop:disable Metrics/MethodLength
    unless chunks_built_for? params[:text_sample_id]
      return { message: 'Sentence chunks have not been built for this text sample' }
    end

    chunk_size, token_size, text_sample_id = extract_generate_params(params)

    text_sample_text = TextSample.find(text_sample_id).text
    text_sample_token_length = Token.split_into_tokens(text_sample_text).length

    output = []

    if chunk_size == 'all'
      CHUNK_SIZE_RANGE.each do |current_chunk_size|
        # handle edge case where text sample has less tokens than the chunk size
        if current_chunk_size <= text_sample_token_length
          output.push(generate_text(current_chunk_size, token_size,
                                    text_sample_id))
        end
      end
    else
      output.push(generate_text(chunk_size, token_size, text_sample_id))
    end

    { output: output }
  end

  # Helper method that pulls individual parameters out of params or sets
  # reasonable defaults
  # @param (see ::generate)
  def self.extract_generate_params(params = {})
    chunk_size =
      if params[:chunk_size]
         .to_i.zero?
        Setting.chunk_size
      else params[:chunk_size].to_i
      end

    token_size = if params[:output_size]
                    .to_i.zero?
                   Setting.token_size else params[:output_size].to_i end

    [chunk_size, token_size, params[:text_sample_id]]
  end

  def self.chunks_built_for?(text_sample_id)
    !SentenceChunk.find_by(text_sample_id: text_sample_id).nil?
  end

  # Actually generate the text for the given chunk_size and text sample
  # @param Integer chunk_size chunk size to use for generation
  # @param Integer token_size number of tokens to generate
  # @param Integer text_sample_id TextSample to use as the model
  #
  # @return Hash with generated text and chunk_size
  def self.generate_text(chunk_size, token_size, text_sample_id)
    chunk = choose_starting_chunk(text_sample_id, chunk_size)

    output_token_ids = chunk.token_ids
    while output_token_ids.size < token_size
      chunk = chunk.choose_next_chunk
      # if we couldn't get a next chunk, then just leave it there
      break unless chunk

      next_token_id = chunk.token_ids[-1]
      output_token_ids << next_token_id
    end

    output = Token.replace_token_ids_with_tokens(output_token_ids).join

    { text: output, chunk_size: chunk_size }
  end

  def self.choose_starting_chunk(text_sample_id, chunk_size)
    candidates = SentenceChunk
                 .where({ text_sample_id: text_sample_id, size: chunk_size })
                 .limit(nil)
    candidates[(rand * candidates.size).to_i]
  end

  # Choose the next chunk after this one
  def choose_next_chunk
    token_ids_where = []

    # grab all but the first token in the chunk
    token_ids[1..].map.with_index do |token_id, index|
      # and build a where clause so that all the tokens in the array match.
      # Note: PostgreSQL arrays are 1-indexed and not 0-indexed
      token_ids_where << "token_ids[#{index + 1}] = #{token_id}"
    end
    token_ids_where = token_ids_where.join(' AND ')

    candidates = SentenceChunk
                 .where("text_sample_id = :text_sample_id AND size = :sentence_chunk_size AND #{token_ids_where}",
                        text_sample_id: text_sample.id, sentence_chunk_size: size)
                 .limit(nil)

    SentenceChunk.choose_chunk_from_candidates(candidates)
  end

  def self.choose_chunk_from_candidates(candidates)
    counts_array = SentenceChunk.build_counts_array(candidates)

    counts_array[(rand * counts_array.size).to_i]
  end

  def self.build_counts_array(candidates)
    counts_array = []
    candidates.each do |chunk|
      chunk.count.times { counts_array.push(chunk) }
    end
    counts_array
  end

  # helper method for converting an array of token_ids back to an array of
  # readable text
  def to_tokens
    Token.replace_token_ids_with_tokens(token_ids)
  end
end
