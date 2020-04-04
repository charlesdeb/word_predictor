require 'rails_helper'

RSpec.describe TextSample, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:text) }
  end

  describe '#build_word_chunks' do
    let(:text_sample){ create(:text_sample_simple) }
    it 'counts word chunks'
    it 'assigns the word chunks to this text sample'
  end
end
