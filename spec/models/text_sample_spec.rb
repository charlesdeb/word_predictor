# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextSample, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:text) }
  end

  describe '#analyse' do
    let(:text_sample) { create(:text_sample) }
    it 'uses word chunk strategy' do
      allow(WordChunk).to receive(:analyse)
      text_sample.analyse
      expect(WordChunk).to have_received(:analyse).with(text_sample)
    end

    it 'uses sentence chunk strategy' do
      allow(SentenceChunk).to receive(:analyse)
      text_sample.analyse
      expect(SentenceChunk).to have_received(:analyse).with(text_sample)
    end
  end

  describe '#generate' do # rubocop:disable Metrics/BlockLength
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end
    let(:chunk_size) { 3 }
    let(:output_size) { 50 }

    it 'uses word chunk strategy if none specified' do
      allow(WordChunk).to receive(:generate).and_return({ output: 'stuff' })
      text_sample.generate
      expect(WordChunk)
        .to have_received(:generate)
        .with({ text_sample_id: text_sample.id })
    end

    it 'handles strategy as a string' do
      generate_params =
        {
          strategy: 'sentence_chunk',
          chunk_size: chunk_size,
          output_size: output_size
        }
      allow(SentenceChunk).to receive(:generate).and_return({ output: 'stuff' })

      text_sample.generate generate_params

      expect(SentenceChunk)
        .to have_received(:generate)
    end

    context 'with word chunk strategy' do
      let(:generate_params) do
        {
          strategy: :word_chunk,
          chunk_size: chunk_size,
          output_size: output_size
        }
      end

      before(:each) do
        allow(WordChunk).to receive(:generate).and_return({ output: 'stuff' })
      end

      it 'uses word chunk strategy' do
        text_sample.generate generate_params

        expect(WordChunk)
          .to have_received(:generate)
          .with({
                  chunk_size: chunk_size,
                  output_size: output_size,
                  text_sample_id: text_sample.id
                })
      end

      it 'includes strategy in output' do
        result = text_sample.generate generate_params

        expect(result[:strategy]).to be(:word_chunk)
      end
    end

    skip 'with sentence chunk strategy' do
      let(:generate_params) do
        {
          strategy: :sentence_chunk,
          chunk_size: chunk_size,
          output_size: output_size
        }
      end

      before(:each) do
        allow(SentenceChunk).to receive(:generate).and_return({ output: 'stuff' })
      end

      it 'uses sentence chunk strategy' do
        text_sample.generate generate_params

        expect(SentenceChunk)
          .to have_received(:generate)
          .with({
                  chunk_size: chunk_size,
                  output_size: output_size,
                  text_sample_id: text_sample.id
                })
      end

      it 'includes strategy in output' do
        result = text_sample.generate generate_params

        expect(result[:strategy]).to be(:sentence_chunk)
      end
    end
  end
end
