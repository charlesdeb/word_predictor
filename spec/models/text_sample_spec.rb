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

  describe '#build_word_chunks_of_size' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'at') }
    let(:chunk_hash) { { 'at' => 1 } }

    before(:each) do
      allow(text_sample).to receive(:build_chunk_hash).and_return(chunk_hash)
      allow(text_sample).to receive(:save_word_chunks)
    end

    it 'builds a hash' do
      text_sample.build_word_chunks_of_size(2)
      expect(text_sample).to have_received(:build_chunk_hash).with(2)
    end

    it 'attempts to save the hash to the database' do
      text_sample.build_word_chunks_of_size(2)
      expect(text_sample).to have_received(
        :save_word_chunks
      ).with(chunk_hash, 2, :insert_all)
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

  describe '#save_word_chunks' do # rubocop:disable Metrics/BlockLength
    let(:long_string) do
      <<~LONG.strip
        The rain in Spain falls mainly in the plain, but we do not really
        know what we are missing in this much longer sentence. Will it
        make a massive difference to the import time, or am I just
        doing premature optimisation which by common consent is largely
        seen as a waste of time. But here we go, adding a bunch more text
        to see if the extra overhead of text will make the slightest bit of
        difference to the import time. Right now, I am not convinced, but
        who knows. The best way to know is always to measure and then
        measure again - checking the hypothesis against the actual results
        of the test.
      LONG
    end
    let(:text_sample) do
      TextSample.create!(description: 'Longer sample', text: long_string)
      # TextSample.create!(description: 'Longer sample', text: 'anty')
    end

    describe '[behaviour]' do
      let(:chunk_size) { 2 }
      let(:chunks_hash) { text_sample.build_chunk_hash(chunk_size) }

      before(:each) do
        allow(text_sample).to receive(:save_word_chunks_by_insert_all)
        allow(text_sample).to receive(:save_word_chunks_by_create)
      end

      it 'raises an exception for an unknown save_strategy' do
        expect do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :bogus_strategy)
        end
          .to raise_exception(/Unknown save_strategy/)
      end

      it 'uses :insert_all as the default strategy' do
        text_sample.save_word_chunks(chunks_hash, chunk_size)
        expect(text_sample).to have_received(:save_word_chunks_by_insert_all)
      end

      it 'uses :insert_all when instructed' do
        text_sample.save_word_chunks(chunks_hash, chunk_size, :insert_all)
        expect(text_sample).to have_received(:save_word_chunks_by_insert_all)
      end

      it 'uses :create! when instructed' do
        text_sample.save_word_chunks(chunks_hash, chunk_size, :create!)
        expect(text_sample).to have_received(:save_word_chunks_by_create)
      end
    end

    describe '[performance]' do # rubocop:disable Metrics/BlockLength
      around(:each) do |example|
        start_time = DateTime.now

        example.run

        seconds_elapsed = (DateTime.now - start_time) * 1000.0
        chunk_size = example.metadata[:chunk_size]
        puts "saving chunks (size #{chunk_size} took #{seconds_elapsed} seconds"
      end

      context 'chunk size of 2', chunk_size: 2 do
        let(:chunk_size) { 2 }
        let(:chunks_hash) { text_sample.build_chunk_hash(chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :create!)
        end
      end

      context 'chunk size of 3', chunk_size: 3 do
        let(:chunk_size) { 3 }
        let(:chunks_hash) { text_sample.build_chunk_hash(chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :create!)
        end
      end

      context 'chunk size of 4', chunk_size: 4 do
        let(:chunk_size) { 4 }
        let(:chunks_hash) { text_sample.build_chunk_hash(chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :create!)
        end
      end

      context 'chunk size of 8', chunk_size: 8 do
        let(:chunk_size) { 8 }
        let(:chunks_hash) { text_sample.build_chunk_hash(chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          text_sample.save_word_chunks(chunks_hash, chunk_size, :create!)
        end
      end
    end
  end

  describe '#save_word_chunks_by_insert_all' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'ant') }
    let(:chunk_hash) { { 'an' => 1, 'nt' => 1 } }

    before(:each) do
      allow(text_sample).to receive(:build_chunk_hash).and_return(chunk_hash)
    end

    it 'saves the hash to the database' do
      allow(WordChunk).to receive(:insert_all)
      text_sample.save_word_chunks_by_insert_all(chunk_hash, 2)

      expect(WordChunk).to(
        have_received(:insert_all).once
      )
    end
  end

  describe '#save_word_chunks_by_create' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'ant') }
    let(:chunk_hash) { { 'an' => 1, 'nt' => 1 } }

    before(:each) do
      allow(text_sample).to receive(:build_chunk_hash).and_return(chunk_hash)
    end

    it 'saves the hash to the database' do
      allow(WordChunk).to receive(:create!)
      text_sample.save_word_chunks_by_create(chunk_hash, 2)

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

  describe '#generate_text' do # rubocop:disable Metrics/BlockLength
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end

    let(:chunk_size) { 3 }
    let(:output_size) { 5 }
    let(:generate_params) do
      { chunk_size: chunk_size, output_size: output_size }
    end

    context 'parameters provided' do
      let(:word_chunk) { double('WordChunk') }

      before(:each) do
        allow(word_chunk).to receive(:text).and_return('abc')
        allow(word_chunk).to receive(:select_next_character).and_return('a')
        allow(WordChunk).to receive(:find_next_chunk).and_return(word_chunk)
        allow(text_sample)
          .to receive(:choose_starting_word_chunk).and_return(word_chunk)
      end

      it 'chooses a starting chunk' do
        text_sample.generate_text generate_params

        expect(text_sample)
          .to(have_received(:choose_starting_word_chunk)
          .with(chunk_size))
      end

      it 'generates the right number of extra characters' do
        text_sample.generate_text generate_params

        expect(word_chunk)
          .to(have_received(:select_next_character).twice)

        expect(WordChunk)
          .to(have_received(:find_next_chunk).twice)
      end

      it 'returns the right length of output text' do
        expect(text_sample.generate_text(generate_params).size).to eq(5)
      end
    end

    context 'parameters not provided' do
    end
  end
end
