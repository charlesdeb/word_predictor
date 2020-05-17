# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WordChunk, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:text) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:count) }
    it { should belong_to(:text_sample) }
  end

  describe '::analyse' do
    it 'builds 2 character chunks' do
      text_sample = create(:text_sample_two_chars)
      allow(WordChunk).to receive(:build_word_chunks_of_size)
      WordChunk.analyse text_sample

      expect(WordChunk).to(
        have_received(:build_word_chunks_of_size).with(text_sample, 2).once
      )
      expect(WordChunk).not_to(
        have_received(:build_word_chunks_of_size).with(text_sample, 3)
      )
    end

    it 'builds 2 and 3 character chunks' do
      text_sample = create(:text_sample_three_chars)
      allow(WordChunk).to receive(:build_word_chunks_of_size)
      WordChunk.analyse(text_sample)

      expect(WordChunk).to(
        have_received(:build_word_chunks_of_size).with(text_sample, 2).once
      )
      expect(WordChunk).to(
        have_received(:build_word_chunks_of_size).with(text_sample, 3).once
      )
    end
  end

  describe '::build_word_chunks_of_size' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'at') }
    let(:chunks_hash) { { 'at' => 1 } }

    before(:each) do
      allow(WordChunk).to receive(:build_chunks_hash).and_return(chunks_hash)
      allow(WordChunk).to receive(:save_word_chunks)
      WordChunk.build_word_chunks_of_size(text_sample, 2)
    end

    it 'builds a hash' do
      expect(WordChunk)
        .to have_received(:build_chunks_hash)
        .with(text_sample.text, 2)
    end

    it 'saves the hash to the database' do
      expect(WordChunk)
        .to have_received(:save_word_chunks)
        .with(chunks_hash, text_sample, 2, :insert_all)
    end
  end

  describe '::build_chunks_hash' do # rubocop:disable Metrics/BlockLength
    context '2 letter text sample, chunk size of 2' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'at') }
      it 'builds hash' do
        expect(WordChunk.build_chunks_hash(text_sample.text, 2))
          .to eq({ 'at' => 1 })
      end
    end

    context '3 letter text sample, chunk size of 2' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'ant') }
      it 'builds hash' do
        expect(WordChunk.build_chunks_hash(text_sample.text, 2))
          .to eq({ 'an' => 1, 'nt' => 1 })
      end
    end

    context '3 letter text sample, chunk size of 2, repeating chunks' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'aaa') }
      it 'builds hash' do
        expect(WordChunk.build_chunks_hash(text_sample.text, 2))
          .to eq({ 'aa' => 2 })
      end
    end

    context '4 letter text sample, chunk size of 2, repeating chunks' do
      let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'aaab') }
      it 'builds hash' do
        expect(WordChunk.build_chunks_hash(text_sample.text, 2))
          .to eq({ 'aa' => 2, 'ab' => 1 })
      end
    end
  end

  describe '::save_word_chunks' do # rubocop:disable Metrics/BlockLength
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
    end

    describe '[behaviour]' do
      let(:chunk_size) { 2 }
      let(:chunks_hash) { WordChunk.build_chunks_hash(text_sample.text, chunk_size) }

      before(:each) do
        allow(WordChunk).to receive(:save_word_chunks_by_insert_all)
        allow(WordChunk).to receive(:save_word_chunks_by_create)
      end

      it 'raises an exception for an unknown save_strategy' do
        expect do
          WordChunk.save_word_chunks(chunks_hash, text_sample, chunk_size, :bogus_strategy)
        end
          .to raise_exception(/Unknown save_strategy/)
      end

      it 'uses :insert_all as the default strategy' do
        WordChunk.save_word_chunks(chunks_hash, text_sample, chunk_size)
        expect(WordChunk).to have_received(:save_word_chunks_by_insert_all)
      end

      it 'uses :insert_all when instructed' do
        WordChunk.save_word_chunks(chunks_hash, text_sample, chunk_size, :insert_all)
        expect(WordChunk).to have_received(:save_word_chunks_by_insert_all)
      end

      it 'uses :create! when instructed' do
        WordChunk.save_word_chunks(chunks_hash, text_sample, chunk_size, :create!)
        expect(WordChunk).to have_received(:save_word_chunks_by_create)
      end
    end

    describe '[performance]', skip: true do # rubocop:disable Metrics/BlockLength
      around(:each) do |example|
        start_time = DateTime.now

        example.run

        seconds_elapsed = (DateTime.now - start_time) * 1000.0
        chunk_size = example.metadata[:chunk_size]
        puts "saving chunks (size #{chunk_size} took #{seconds_elapsed} seconds"
      end

      context 'chunk size of 2', chunk_size: 2 do
        let(:chunk_size) { 2 }
        let(:chunks_hash) { WordChunk.build_chunks_hash(text_sample.text, chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :create!)
        end
      end

      context 'chunk size of 3', chunk_size: 3 do
        let(:chunk_size) { 3 }
        let(:chunks_hash) { WordChunk.build_chunks_hash(text_sample.text, chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :create!)
        end
      end

      context 'chunk size of 4', chunk_size: 4 do
        let(:chunk_size) { 4 }
        let(:chunks_hash) { WordChunk.build_chunks_hash(text_sample.text, chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :create!)
        end
      end

      context 'chunk size of 8', chunk_size: 8 do
        let(:chunk_size) { 8 }
        let(:chunks_hash) { WordChunk.build_chunks_hash(text_sample.text, chunk_size) }
        it 'uses insert_all for individual word_chunks' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :insert_all)
        end
        it 'uses individual create! for each word_chunk' do
          WordChunk
            .save_word_chunks(chunks_hash, text_sample, chunk_size, :create!)
        end
      end
    end
  end

  describe '::save_word_chunks_by_insert_all' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'ant') }
    let(:chunk_hash) { { 'an' => 1, 'nt' => 1 } }

    before(:each) do
      allow(WordChunk).to receive(:build_chunks_hash).and_return(chunk_hash)
    end

    it 'saves the hash to the database' do
      allow(WordChunk).to receive(:insert_all)
      WordChunk.save_word_chunks_by_insert_all(chunk_hash, text_sample, 2)

      expect(WordChunk).to(
        have_received(:insert_all).once
      )
    end
  end

  describe '::save_word_chunks_by_create' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'ant') }
    let(:chunk_hash) { { 'an' => 1, 'nt' => 1 } }

    before(:each) do
      allow(WordChunk).to receive(:build_chunks_hash).and_return(chunk_hash)
    end

    it 'saves the hash to the database' do
      allow(WordChunk).to receive(:create!)
      WordChunk.save_word_chunks_by_create(chunk_hash, text_sample, 2)

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

  describe '::choose_starting_word_chunk' do
    let(:chunk_size) { 3 }
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'mice')
    end

    before(:each) do
      WordChunk.build_word_chunks_of_size(text_sample, chunk_size)
    end

    it 'all WordChunks are potential candidates' do
      candidates = %w[mic ice]

      # if we run this 100 times, it's pretty unlikely we won't get both of
      # these
      100.times do
        candidate = WordChunk.choose_starting_word_chunk(text_sample, chunk_size)
        candidates.delete(candidate.text) if candidates.include?(candidate.text)
        break if candidates.empty?
      end
      expect(candidates).to eq([])
    end

    it 'returns a WordChunk' do
      result = WordChunk.choose_starting_word_chunk(text_sample, chunk_size)
      expect(result).to be_instance_of(WordChunk)
    end
  end

  describe '#choose_next_word_chunk' do
    let(:where_chain) { double('WhereChain') }
    let(:word_chunk) { create(:word_chunk) }
    let(:candidates) { double('candidates') }

    before(:each) do
      allow(WordChunk).to receive(:choose_word_chunk_from_candidates)
      allow(WordChunk)
        .to receive(:where).and_return(where_chain)

      allow(where_chain).to receive(:limit).and_return(candidates)

      word_chunk.choose_next_word_chunk
    end

    it 'finds candidate word chunks' do
      expect(WordChunk)
        .to(have_received(:where)
        .with('text_sample_id = :text_sample_id AND size = :word_chunk_size AND text LIKE :chunk_head',
              { chunk_head: 't%', text_sample_id: word_chunk.text_sample_id,
                word_chunk_size: 2 }))
    end

    it 'chooses word chunk from candidates' do
      expect(WordChunk)
        .to(
          have_received(:choose_word_chunk_from_candidates).with(candidates)
        )
    end
  end

  describe '::choose_word_chunk_from_candidates' do
    let(:counts_array) { [build(:word_chunk), build(:word_chunk)] }
    let(:candidates) { double('candidates') }

    before(:each) do
      allow(WordChunk)
        .to receive(:build_counts_array).and_return(counts_array)
    end

    it 'calculates probabilities of each word chunk' do
      WordChunk.choose_word_chunk_from_candidates(candidates)

      expect(WordChunk)
        .to(have_received(:build_counts_array).with(candidates))
    end

    it 'selects a word chunk' do
      new_word_chunk = WordChunk.choose_word_chunk_from_candidates(candidates)

      expect(new_word_chunk).to be_instance_of(WordChunk)
    end
  end

  describe '::build_counts_array' do
    let!(:word_chunk_at) { create(:word_chunk, text: 'at', count: 2) }
    let!(:word_chunk_an) { create(:word_chunk, text: 'an', count: 1) }
    let(:candidates) { WordChunk.all }

    it 'has the right number of elements' do
      counts_array = WordChunk.build_counts_array(candidates)

      expect(counts_array.size).to eq(3)
    end
  end

  describe ''
  # describe '#choose_next_word_chunk' do
  #   context 'chunk size of 2' do
  #     let(:chunk_size) { 2 }
  #     let(:text_sample) do
  #       TextSample.create!(description: 'Stuff', text: 'abcdef')
  #     end

  #     before(:each) do
  #       text_sample.build_word_chunks_of_size(chunk_size)
  #     end

  #     it 'returns a WordChunk starting with the right letters' do
  #       word_chunk = WordChunk.where(
  #         { text_sample_id: text_sample.id, text: 'ab', size: chunk_size }
  #       ).first
  #       result = word_chunk.choose_next_word_chunk
  #       expect(result.text[0]).to eq('b')
  #     end
  #   end

  #   context 'chunk size of 3' do
  #     let(:chunk_size) { 3 }
  #     let(:text_sample) do
  #       TextSample.create!(description: 'Stuff', text: 'abcdef')
  #     end

  #     before(:each) do
  #       text_sample.build_word_chunks_of_size(chunk_size)
  #     end

  #     it 'returns a WordChunk starting with the right letters' do
  #       word_chunk = WordChunk.where(
  #         { text_sample_id: text_sample.id, text: 'abc', size: chunk_size }
  #       ).first
  #       result = word_chunk.choose_next_word_chunk
  #       expect(result.text[0..1]).to eq('bc')
  #     end
  #   end
  #     let(:chunk_size) { 2 }
  #     let(:text_sample) do
  #       TextSample.create!(description: 'Stuff', text: 'abc abd abe fgh fgh fgi')
  #     end

  #     before(:each) do
  #       text_sample.build_word_chunks_of_size(chunk_size)
  #     end

  #     it 'chooses c,d and e after ab more or less evenly' do
  #       results = Hash.new(0)
  #       word_chunk = WordChunk.where(
  #         { text_sample_id: text_sample.id, text: 'ab', size: chunk_size }
  #       ).first
  #       300.times do
  #         next_work_chunk = word_chunk.choose_next_word_chunk
  #         results[next_work_chunk.text[-1]] += 1
  #       end
  #       puts results

  #       expect(results['c']).to be_within(15).of(100)
  #       expect(results['d']).to be_within(15).of(100)
  #       expect(results['e']).to be_within(15).of(100)
  #     end

  #     it 'chooses h after fg more or less twice as many time' do
  #       results = Hash.new(0)
  #       word_chunk = WordChunk.where(
  #         { text_sample_id: text_sample.id, text: 'fg', size: chunk_size }
  #       ).first
  #       3.times do
  #         next_work_chunk = word_chunk.choose_next_word_chunk
  #         results[next_work_chunk.text[-1]] += 1
  #       end
  #       puts results

  #       # expect(results['h']).to be_within(15).of(200)
  #       # expect(results['i']).to be_within(15).of(100)
  #     end
  #   end
  # end
end
