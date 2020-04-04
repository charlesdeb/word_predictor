require 'rails_helper'

RSpec.describe WordChunk, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:text) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:count) }
    it { should belong_to(:text_sample) }
  end
end
