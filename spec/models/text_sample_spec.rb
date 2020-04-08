# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextSample, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:text) }
  end

  # describe '::class_method' do
  describe '#build_word_chunks' do
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

  describe '#build_word_chunks_of_size' do # rubocop:disable Metrics/BlockLength
    before(:each) do
      # don't hit database
      allow(WordChunk).to receive(:create!)
    end

    context '2 letter text sample, chunk size of 2' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'at') }
      let(:chunk_hash) { { 'at' => 1 } }

      before(:each) do
        allow(text_sample).to receive(:build_chunk_hash).and_return(chunk_hash)
      end

      it 'builds a hash' do
        text_sample.build_word_chunks_of_size(2)
        expect(text_sample).to have_received(:build_chunk_hash).with(2)
      end

      it 'saves the hash to the database' do
        text_sample.build_word_chunks_of_size(2)

        expect(WordChunk).to(
          have_received(:create!)
          .with(text: 'at', size: 2, count: 1, text_sample_id: text_sample.id)
        )
      end
    end

    context '3 letter text sample, chunk size of 2' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'ant') }
      let(:chunk_hash) { { 'an' => 1, 'nt' => 1 } }

      before(:each) do
        allow(text_sample).to receive(:build_chunk_hash).and_return(chunk_hash)
      end

      it 'builds a hash' do
        text_sample.build_word_chunks_of_size(2)
        expect(text_sample).to have_received(:build_chunk_hash).with(2)
      end

      it 'saves the hash to the database' do
        allow(WordChunk).to receive(:create!)
        text_sample.build_word_chunks_of_size(2)

        expect(WordChunk).to(
          have_received(:create!)
          .with(text: 'an', size: 2, count: 1, text_sample_id: text_sample.id)
        )
        expect(WordChunk).to(
          have_received(:create!)
          .with(text: 'nt', size: 2, count: 1, text_sample_id: text_sample.id)
        )
      end
    end
  end

  describe '#build_chunk_hash' do
    context '2 letter text sample, chunk size of 2' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'at') }
      it 'builds hash' do
        expect(text_sample.build_chunk_hash(2)).to eq({ 'at' => 1 })
      end
    end

    context '3 letter text sample, chunk size of 2' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'ant') }
      it 'builds hash' do
        expect(text_sample.build_chunk_hash(2)).to eq({ 'an' => 1, 'nt' => 1 })
      end
    end

    context '3 letter text sample, chunk size of 2, repeating chunks' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'aaa') }
      it 'builds hash' do
        expect(text_sample.build_chunk_hash(2)).to eq({ 'aa' => 2 })
      end
    end

    context '4 letter text sample, chunk size of 2, repeating chunks' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'aaab') }
      it 'builds hash' do
        expect(text_sample.build_chunk_hash(2)).to eq({ 'aa' => 2, 'ab' => 1 })
      end
    end
  end
end
