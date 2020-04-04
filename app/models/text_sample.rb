class TextSample < ApplicationRecord
  validates :description, presence: true
  validates :text, presence: true
end
