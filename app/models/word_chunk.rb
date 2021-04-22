# frozen_string_literal: true

class WordChunk < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :text_sample

  validates :text, presence: true
  validates :size, presence: true
  validates :count, presence: true

  CHUNK_SIZE_RANGE = (2..8).freeze

  def self.analyse(text_sample)
    # TODO: it might be better to get the upper limit from a setting, or
    # according to how many unique chunks we got for the previous chunk_size
    chunk_sizes = CHUNK_SIZE_RANGE

    chunk_sizes.each do |chunk_size|
      count_chunks_of_size(text_sample, chunk_size) unless text_sample.text.size < chunk_size
    end
  end

  def self.count_chunks_of_size(
    text_sample, chunk_size,
    save_strategy = :insert_all
  )
    # create a hash
    chunks_hash = build_chunks_hash(text_sample.text, chunk_size)

    # store chunk_hash in the database
    save_word_chunks(chunks_hash, text_sample, chunk_size, save_strategy)
  end

  def self.build_chunks_hash(text, chunk_size)
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

  # TODO: these are rather slow and inefficient; storing a single hash per
  # row may be a better solution
  def self.save_word_chunks(
    chunks_hash, text_sample, chunk_size,
    save_strategy = :insert_all
  )

    case save_strategy
    when :insert_all
      # uses lots of database rows
      save_word_chunks_by_insert_all(chunks_hash, text_sample, chunk_size)
    when :create!
      # VEEERY slow and uses lots of DB rows
      save_word_chunks_by_create(chunks_hash, text_sample, chunk_size)
    else
      raise "Unknown save_strategy: #{save_strategy}"
    end
  end

  def self.save_word_chunks_by_insert_all( # rubocop:disable Metrics/MethodLength
    chunks_hash, text_sample, chunk_size
  )
    current_time = DateTime.now
    import_array = []
    chunks_hash.each do |chunk_text, count|
      import_hash = {
        text: chunk_text, size: chunk_size,
        count: count, text_sample_id: text_sample.id,
        created_at: current_time, updated_at: current_time
      }
      import_array << import_hash
    end
    WordChunk.insert_all import_array
  end

  def self.save_word_chunks_by_create(chunks_hash, text_sample, chunk_size)
    chunks_hash.each do |chunk_text, count|
      WordChunk.create!(
        text: chunk_text, size: chunk_size,
        count: count, text_sample_id: text_sample.id
      )
    end
  end

  # Entry point for generating text using the word chunk strategy
  def self.generate(params = {}) # rubocop:disable Metrics/MethodLength
    unless chunks_built_for? params[:text_sample_id]
      return { message: 'Word chunks have not been built for this text sample' }
    end

    chunk_size, output_size, text_sample_id = extract_generate_params(params)

    text_sample_length = TextSample.find(text_sample_id).text.length

    output = []

    if chunk_size == 'all'
      CHUNK_SIZE_RANGE.each do |current_chunk_size|
        # handle edge case where text sample is shorter than the chunk size
        if current_chunk_size <= text_sample_length
          output.push(generate_text(current_chunk_size, output_size,
                                    text_sample_id))
        end
      end
    else
      output.push(generate_text(chunk_size, output_size, text_sample_id))
    end

    { output: output }
  end

  def self.extract_generate_params(params = {})
    chunk_size =
      if params[:chunk_size]
         .to_i.zero?
        Setting.chunk_size
      else params[:chunk_size].to_i
      end

    output_size = if params[:output_size]
                     .to_i.zero?
                    Setting.output_size else params[:output_size].to_i end

    [chunk_size, output_size, params[:text_sample_id]]
  end

  def self.chunks_built_for?(text_sample_id)
    !WordChunk.find_by(text_sample_id: text_sample_id).nil?
  end

  def self.generate_text(chunk_size, output_size, text_sample_id)
    word_chunk = choose_starting_word_chunk(text_sample_id, chunk_size)

    output = word_chunk.text
    while output.size < output_size
      word_chunk = word_chunk.choose_next_word_chunk
      # if we couldn't get a next chunk, then just leave it there
      break unless word_chunk

      next_character = word_chunk.text[-1]
      output += next_character
    end

    { text: output, chunk_size: chunk_size }
  end

  def self.choose_starting_word_chunk(text_sample_id, chunk_size)
    candidates = WordChunk
                 .where({ text_sample_id: text_sample_id, size: chunk_size })
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
