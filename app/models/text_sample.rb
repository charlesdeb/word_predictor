# frozen_string_literal: true

class TextSample < ApplicationRecord
  require 'date'

  validates :description, presence: true
  validates :text, presence: true

  DEFAULT_CHUNK_SIZE = 3
  DEFAULT_OUTPUT_SIZE = 100

  def build_word_chunks
    # TODO: it might be better to get the upper limit from a setting, or
    # according to how many unique chunks we got for the previous chunk_size
    chunk_sizes = 2..8

    chunk_sizes.each do |chunk_size|
      build_word_chunks_of_size(chunk_size) unless text.size < chunk_size
    end
  end

  def build_word_chunks_of_size(chunk_size, save_strategy = :insert_all)
    # create a hash
    chunks_hash = build_chunk_hash(chunk_size)

    # store it chunk by chunk in the database
    save_word_chunks(chunks_hash, chunk_size, save_strategy)
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

  # TODO: these are rather slow and inefficient; storing a single hash per
  # row may be a better solution
  def save_word_chunks(chunks_hash, chunk_size, save_strategy = :insert_all)
    case save_strategy
    when :insert_all
      save_word_chunks_by_insert_all(chunks_hash, chunk_size)
    when :create!
      save_word_chunks_by_create(chunks_hash, chunk_size)
    else
      raise "Unknown save_strategy: #{save_strategy}"
    end
  end

  def save_word_chunks_by_insert_all(chunks_hash, chunk_size)
    current_time = DateTime.now
    import_array = []
    chunks_hash.each do |chunk_text, count|
      import_hash = { text: chunk_text, size: chunk_size,
                      count: count, text_sample_id: id,
                      created_at: current_time, updated_at: current_time }
      import_array << import_hash
    end
    WordChunk.insert_all import_array
  end

  def save_word_chunks_by_create(chunks_hash, chunk_size)
    chunks_hash.each do |chunk_text, count|
      WordChunk.create!(
        text: chunk_text, size: chunk_size, count: count, text_sample_id: id
      )
    end
  end

  def generate(params = {})
    unless chunks_built?
      return { message: 'Word chunks have not been built for this text sample' }
    end

    chunk_size = params[:chunk_size] || DEFAULT_CHUNK_SIZE
    output_size = params[:output_size] || DEFAULT_OUTPUT_SIZE

    { text: generate_text(chunk_size, output_size) }

    # next_word_chunk = choose_starting_word_chunk(chunk_size)

    # output = next_word_chunk.text
    # while output.size < output_size
    #   next_character = next_word_chunk.select_next_character
    #   output += next_character
    #   next_word_chunk = WordChunk
    #                     .find_next_chunk(next_word_chunk, next_character)
    # end

    # output
  end

  def generate_text(chunk_size, output_size) end

  def chunks_built?
    puts 'in chunks_built?'
  end

  def choose_starting_word_chunk(chunk_size); end
end
