# frozen_string_literal: true

class WordChunk < ApplicationRecord
  belongs_to :text_sample

  validates :text, presence: true
  validates :size, presence: true
  validates :count, presence: true

  def find_next_chunk(next_character); end

  def select_next_character
    'a'
  end
end
