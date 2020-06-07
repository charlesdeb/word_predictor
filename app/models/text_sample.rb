# frozen_string_literal: true

class TextSample < ApplicationRecord
  require 'date'

  validates :description, presence: true
  validates :text, presence: true

  STRATEGIES = %i[word_chunk sentence_chunk].freeze

  def analyse
    STRATEGIES.each do |strategy|
      case strategy
      when :word_chunk
        WordChunk.analyse self
      when :sentence_chunk
        SentenceChunk.analyse self
      end
    end
  end

  # generate text for the current text sample using the given strategy
  def generate(params = { strategy: :word_chunk })
    # add the current text sample to params
    params.merge!({ text_sample_id: id })

    # case params['strategy'].parameterize.underscore.to_sym
    # case params.except!(:strategy)
    case params.extract!(:strategy)
    when :word_chunk
      { strategy: :word_chunk }.merge(WordChunk.generate(params))
    when :sentence_chunk
      { strategy: :sentence_chunk }.merge(SentenceChunk.generate(params))
    else
      { strategy: :word_chunk }.merge(WordChunk.generate(params))
    end
  end
end
