# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WordChunk, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:text) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:count) }
    it { should belong_to(:text_sample) }
  end

  describe '::choose_starting_word_chunk' do
    let(:chunk_size) { 3 }
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'mice')
    end

    before(:each) do
      text_sample.build_word_chunks_of_size(chunk_size)
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
