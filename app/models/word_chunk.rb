class WordChunk < ApplicationRecord
  belongs_to :text_sample

  validates :text, presence: true
  validates :size, presence: true
  validates :count, presence: true
end
