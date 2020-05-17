# frozen_string_literal: true

class TextSample < ApplicationRecord
  require 'date'

  validates :description, presence: true
  validates :text, presence: true

  STRATEGIES = %i[word_chunk word].freeze

  def analyse
    STRATEGIES.each do |strategy|
      case strategy
      when :word_chunk
        WordChunk.analyse self
        # when :word

      end
    end
  end

  def generate(params = {})
    unless chunks_built?
      return { message: 'Word chunks have not been built for this text sample' }
    end

    output_size =
      params[:output_size].to_i.zero? ? Setting.output_size : params[:output_size].to_i

    output = []

    if params[:chunk_size] == 'all'
      WordChunk::CHUNK_SIZE_RANGE.each do |chunk_size|
        output.push(generate_text(chunk_size, output_size))
      end
    else
      chunk_size =
        params[:chunk_size].to_i.zero? ? Setting.chunk_size : params[:chunk_size].to_i
      output.push(generate_text(chunk_size, output_size))
    end
    { output: output }
  end

  def generate_text(chunk_size, output_size)
    word_chunk = WordChunk.choose_starting_word_chunk(self, chunk_size)

    output = word_chunk.text
    while output.size < output_size
      word_chunk = word_chunk.choose_next_word_chunk
      next_character = word_chunk.text[-1]
      output += next_character
    end

    { text: output, chunk_size: chunk_size }
  end

  def chunks_built?
    !WordChunk.find_by(text_sample_id: id).nil?
  end
end
