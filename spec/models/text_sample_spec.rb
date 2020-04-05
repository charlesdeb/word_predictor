# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextSample, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:text) }
  end

  # describe '::class_method' do
  describe '#build_word_chunks' do
    describe 'builds different sized chunks' do
      it 'handles 2 character chunks' do
        text_sample = create(:text_sample_two_chars)
        allow(text_sample).to receive(:build_word_chunks_of_size)
        text_sample.build_word_chunks

        expect(text_sample).to(
          have_received(:build_word_chunks_of_size).with(2).once
        )
        expect(text_sample).not_to(
          have_received(:build_word_chunks_of_size).with(3)
        )
      end

      it 'handles 3 character chunks' do
        text_sample = create(:text_sample_three_chars)
        allow(text_sample).to receive(:build_word_chunks_of_size)
        text_sample.build_word_chunks

        expect(text_sample).to(
          have_received(:build_word_chunks_of_size).with(2).once
        )
        expect(text_sample).to(
          have_received(:build_word_chunks_of_size).with(3).once
        )
      end
    end
  end
end
