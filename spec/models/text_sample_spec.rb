# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextSample, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:text) }
  end

  describe '#analyse' do
    it 'uses word chunk strategy' do
      text_sample = create(:text_sample)
      allow(WordChunk).to receive(:analyse)
      text_sample.analyse
      expect(WordChunk).to have_received(:analyse).with(text_sample)
    end

    it 'uses word strategy'
  end

  describe '#generate' do # rubocop:disable Metrics/BlockLength
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end
    let(:chunk_size) { 3 }
    let(:output_size) { 5 }
    let(:generate_params) do
      { chunk_size: chunk_size, output_size: output_size }
    end

    it 'checks whether WordChunks have been generated for this TextSample' do
      allow(text_sample).to receive(:chunks_built?)
      text_sample.generate generate_params
      expect(text_sample).to have_received(:chunks_built?)
    end

    context 'WordChunks have not been generated' do
      it 'returns a warning' do
        allow(text_sample).to receive(:chunks_built?).and_return(false)
        result = text_sample.generate generate_params
        expect(result[:message])
          .not_to be(nil)
        expect(result[:message])
          .to match(/Word chunks have not been built for this text sample/)
      end
    end

    context 'WordChunks have been generated' do # rubocop:disable Metrics/BlockLength
      let(:generated_text) { 'some text' }
      before(:each) do
        allow(text_sample).to receive(:chunks_built?).and_return(true)
        allow(text_sample)
          .to receive(:generate_text)
          .and_return({ text: generated_text, chunk_size: chunk_size })
      end

      it 'sets generate parameters' do
        allow(text_sample)
          .to receive(:get_generate_params)
          .and_return([output_size, chunk_size])

        text_sample.generate

        expect(text_sample)
          .to have_received(:get_generate_params)
      end

      context 'for one chunk_size' do
        let(:generation_result) do
          { output: [{ text: generated_text, chunk_size: chunk_size }] }
        end

        it 'generates the text' do
          text_sample.generate generate_params
          expect(text_sample)
            .to have_received(:generate_text)
            .with(chunk_size, output_size)
        end

        it 'returns a hash with the generated text' do
          result = text_sample.generate generate_params

          expect(result).to eq(generation_result)
        end
      end

      context 'for all chunk_sizes' do
        let(:generate_params) do
          { chunk_size: 'all', output_size: output_size }
        end

        it 'generates the right number of texts' do
          text_sample.generate generate_params
          expect(text_sample)
            .to have_received(:generate_text)
            .exactly(WordChunk::CHUNK_SIZE_RANGE.size).times
        end

        it 'returns a hash with the generated text' do
          result = text_sample.generate generate_params

          expect(result[:output].size).to eq(WordChunk::CHUNK_SIZE_RANGE.size)
        end
      end
    end
  end

  describe '#get_generate_params' do
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end
    let(:chunk_size) { 3 }
    let(:output_size) { 5 }
    let(:generate_params) do
      { chunk_size: chunk_size, output_size: output_size }
    end

    it 'uses default chunk_size and output size if no params provided' do
      e_chunk_size, e_output_size = text_sample.get_generate_params

      expect(e_chunk_size).to eq(Setting.chunk_size)
      expect(e_output_size).to eq(Setting.output_size)
    end

    it 'extracts params' do
      e_chunk_size, e_output_size = text_sample
                                    .get_generate_params generate_params

      expect(e_chunk_size).to eq(chunk_size)
      expect(e_output_size).to eq(output_size)
    end
  end

  describe '#chunks_built?' do
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end

    it 'returns true if WordChunks have been built for this text_sample' do
      text_sample.analyse
      expect(text_sample.chunks_built?).to eq(true)
    end

    it 'returns false if WordChunks have not been built for this text_sample' do
      expect(text_sample.chunks_built?).to eq(false)
    end
  end

  describe '#generate_text' do
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end

    let(:chunk_size) { 3 }
    let(:output_size) { 5 }

    let(:word_chunk) { double('WordChunk') }

    before(:each) do
      allow(WordChunk)
        .to receive(:choose_starting_word_chunk).and_return(word_chunk)
      allow(word_chunk)
        .to receive(:text).and_return('abc')
      allow(word_chunk)
        .to receive(:choose_next_word_chunk).and_return(word_chunk)
    end

    it 'chooses a starting chunk' do
      text_sample.generate_text(chunk_size, output_size)

      expect(WordChunk)
        .to(have_received(:choose_starting_word_chunk)
        .with(text_sample, chunk_size))
    end

    it 'generates the right number of extra characters' do
      text_sample.generate_text(chunk_size, output_size)

      expect(word_chunk)
        .to(have_received(:choose_next_word_chunk).twice)
    end

    it 'returns the right length of output text' do
      result = text_sample.generate_text(chunk_size, output_size)
      expect(result[:text].size).to eq(5)
    end

    it 'returns a hash with the right keys' do
      result = text_sample.generate_text(chunk_size, output_size)
      expect(result).to have_key(:chunk_size)
      expect(result).to have_key(:text)
    end
  end
end
