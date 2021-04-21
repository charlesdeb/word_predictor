# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SentenceChunk, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:token_ids) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:count) }
    it { should belong_to(:text_sample) }
  end

  describe '::analyse' do # rubocop:disable Metrics/BlockLength
    before(:each) do
      allow(SentenceChunk).to receive(:count_chunks)
    end

    it 'converts the text into an array of token IDs' do
      allow(Token).to receive(:id_ise).and_return([1, 2, 3])
      text_sample = create(:text_sample_three_tokens)

      SentenceChunk.analyse text_sample

      expect(Token).to have_received(:id_ise).with(text_sample.text, :sentence)
    end

    it 'counts 2-token chunks' do
      text_sample = create(:text_sample_two_tokens)
      text_sample_token_ids = [1, 2]
      allow(Token).to receive(:id_ise).and_return(text_sample_token_ids)

      SentenceChunk.analyse text_sample

      expect(SentenceChunk).to(
        have_received(:count_chunks)
        .with(text_sample_token_ids, text_sample.id, 2)
        .once
      )
      expect(SentenceChunk).not_to(
        have_received(:count_chunks)
        .with(text_sample_token_ids, text_sample.id, 3)
      )
    end

    it 'counts 2-token and 3-token chunks' do
      text_sample = create(:text_sample_three_tokens)
      text_sample_token_ids = [1, 2, 3]
      allow(Token).to receive(:id_ise).and_return(text_sample_token_ids)

      SentenceChunk.analyse text_sample

      expect(SentenceChunk).to(
        have_received(:count_chunks)
        .with(text_sample_token_ids, text_sample.id, 2)
        .once
      )

      expect(SentenceChunk).to(
        have_received(:count_chunks)
        .with(text_sample_token_ids, text_sample.id, 3)
        .once
      )
    end
  end

  describe '::count_chunks' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'at ') }
    let(:token_ids) { 'array of token ids' } # for example [1,2]
    let(:chunks_hash) { 'some hash' }

    before(:each) do
      allow(SentenceChunk).to receive(:build_chunks_hash).and_return(chunks_hash)
      allow(SentenceChunk).to receive(:save_chunks)

      SentenceChunk.count_chunks(
        token_ids, text_sample.id, 2
      )
    end

    it 'builds a hash' do
      expect(SentenceChunk)
        .to have_received(:build_chunks_hash)
        .with(token_ids, 2)
    end

    it 'saves the hash' do
      expect(SentenceChunk)
        .to have_received(:save_chunks)
        .with(chunks_hash, text_sample.id, 2, :insert_all)
    end
  end

  describe '::build_chunks_hash' do # rubocop:disable Metrics/BlockLength
    context '2 token text sample, chunk size of 2' do
      let(:text_sample) do
        TextSample.create!(description: 'Stuff', text: 'at ')
      end

      let(:token_ids) { [1, 2] }

      it 'builds hash' do
        expect(SentenceChunk.build_chunks_hash(token_ids, 2))
          .to eq({ [1, 2] => 1 })
      end
    end

    context '3 token text sample, chunk size of 2' do
      let(:text_sample) do
        TextSample.create!(description: 'Stuff', text: 'ant man')
      end

      let(:token_ids) { [1, 2, 3] }

      it 'builds hash' do
        expect(SentenceChunk.build_chunks_hash(token_ids, 2))
          .to eq({ [1, 2] => 1, [2, 3] => 1 })
        # .to eq({ 'ant ' => 1, ' man' => 1 })
      end
    end

    context '3 token text sample, chunk size of 2, repeating chunks' do
      let(:text_sample) do
        TextSample.create!(description: 'Stuff', text: '!!! and and and')
      end

      let(:token_ids) { [1, 1, 1] }

      it 'builds hash' do
        expect(SentenceChunk.build_chunks_hash(token_ids, 2))
          .to eq([1, 1] => 2)
        # .to eq({ '!!' => 2)
      end
    end

    context '4 token text sample, chunk size of 2, repeating chunks' do
      let(:text_sample) do
        TextSample.create!(description: 'Stuff', text: 'ant ant ')
      end

      let(:token_ids) { [1, 2, 1, 2] }

      it 'builds hash' do
        expect(SentenceChunk.build_chunks_hash(token_ids, 2))
          .to eq({ [1, 2] => 2, [2, 1] => 1 })
        # .to eq({ 'ant ' => 2, ' ant' => 1 })
      end
    end

    context '9 token text sample, chunk size of 2, repeating chunks' do
      let(:text_sample) do
        TextSample.create!(description: 'Stuff', text: '!!! and and and')
      end

      let(:token_ids) { [1, 1, 1, 2, 3, 2, 3, 2, 3] }
      # let(:token_ids) { ['!', '!', '!', ' ', 'and', ' ', 'and', ' ', 'and'] }

      it 'builds hash' do
        expect(SentenceChunk.build_chunks_hash(token_ids, 2))
          .to eq([1, 1] => 2, [1, 2] => 1, [2, 3] => 3, [3, 2] => 2)
        # .to eq({ '!!' => 2 , '! ' => 1, ' and' => 3, 'and ' => 2})
      end
    end

    context '9 token text sample, chunk size of 3, repeating chunks' do
      let(:text_sample) do
        TextSample.create!(description: 'Stuff', text: '!!! and and and')
      end

      let(:token_ids) { [1, 1, 1, 2, 3, 2, 3, 2, 3] }
      # let(:token_ids) { ['!', '!', '!', ' ', 'and', ' ', 'and', ' ', 'and'] }

      it 'builds hash' do
        expect(SentenceChunk.build_chunks_hash(token_ids, 3))
          .to eq([1, 1, 1] => 1, [1, 1, 2] => 1, [1, 2, 3] => 1, [2, 3, 2] => 2, [3, 2, 3] => 2)
        # .to eq({ '!!!' => 1 ,  '!! ' => 1,     '! and' => 3,   ' and ' => 2,   'and and' => 2})
      end
    end
  end

  describe '::save_chunks' do # rubocop:disable Metrics/BlockLength
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
    let(:text_sample_token_ids) { Token.id_ise(text_sample.text, :sentence) }

    describe '[behaviour]' do
      let(:chunk_size) { 2 }
      let(:token_ids) { Token.id_ise(text_sample.text) }
      let(:chunks_hash) { SentenceChunk.build_chunks_hash(token_ids, chunk_size) }

      before(:each) do
        allow(SentenceChunk).to receive(:save_chunks_by_insert_all)
      end

      it 'raises an exception for an unknown save_strategy' do
        expect do
          SentenceChunk.save_chunks(chunks_hash, text_sample.id, chunk_size, :bogus_strategy)
        end
          .to raise_exception(/Unknown save_strategy/)
      end

      it 'uses :insert_all as the default strategy' do
        SentenceChunk.save_chunks(chunks_hash, text_sample, chunk_size)
        expect(SentenceChunk).to have_received(:save_chunks_by_insert_all)
      end

      it 'uses :insert_all when instructed' do
        SentenceChunk.save_chunks(chunks_hash, text_sample, chunk_size, :insert_all)
        expect(SentenceChunk).to have_received(:save_chunks_by_insert_all)
      end
    end

    describe '[performance]', skip: false do # rubocop:disable Metrics/BlockLength
      around(:each) do |example|
        start_time = DateTime.now

        example.run

        seconds_elapsed = (DateTime.now - start_time) * 1000.0
        chunk_size = example.metadata[:chunk_size]
        puts "saving chunks (size #{chunk_size} took #{seconds_elapsed} seconds"
      end

      context 'chunk size of 2', chunk_size: 2 do
        let(:chunk_size) { 2 }
        let(:chunks_hash) { SentenceChunk.build_chunks_hash(text_sample_token_ids, chunk_size) }
        it 'uses insert_all for individual sentence_chunks' do
          SentenceChunk
            .save_chunks(chunks_hash, text_sample.id, chunk_size, :insert_all)
        end

        # it 'uses individual create! for each sentence_chunk' do
        #   SentenceChunk
        #     .save_chunks(chunks_hash, text_sample, chunk_size, :create!)
        # end
      end

      context 'chunk size of 3', chunk_size: 3 do
        let(:chunk_size) { 3 }
        let(:chunks_hash) { SentenceChunk.build_chunks_hash(text_sample_token_ids, chunk_size) }
        it 'uses insert_all for individual sentence_chunks' do
          SentenceChunk
            .save_chunks(chunks_hash, text_sample.id, chunk_size, :insert_all)
        end
        # it 'uses individual create! for each sentence_chunk' do
        #   SentenceChunk
        #     .save_chunks(chunks_hash, text_sample, chunk_size, :create!)
        # end
      end

      context 'chunk size of 4', chunk_size: 4 do
        let(:chunk_size) { 4 }
        let(:chunks_hash) { SentenceChunk.build_chunks_hash(text_sample_token_ids, chunk_size) }
        it 'uses insert_all for individual sentence_chunks' do
          SentenceChunk
            .save_chunks(chunks_hash, text_sample.id, chunk_size, :insert_all)
        end
        # it 'uses individual create! for each sentence_chunk' do
        #   SentenceChunk
        #     .save_chunks(chunks_hash, text_sample, chunk_size, :create!)
        # end
      end

      context 'chunk size of 8', chunk_size: 8 do
        let(:chunk_size) { 8 }
        let(:chunks_hash) { SentenceChunk.build_chunks_hash(text_sample_token_ids, chunk_size) }
        it 'uses insert_all for individual sentence_chunks' do
          SentenceChunk
            .save_chunks(chunks_hash, text_sample.id, chunk_size, :insert_all)
        end
        # it 'uses individual create! for each sentence_chunk' do
        #   SentenceChunk
        #     .save_chunks(chunks_hash, text_sample, chunk_size, :create!)
        # end
      end
    end
  end

  describe '::save_chunks_by_insert_all' do
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'ant man')
    end

    # let(:token_ids) { ['ant', ' ', 'man'] }
    # let(:token_ids) { [1, 2, 3] }

    let(:chunk_hash) { { [1, 2] => 1, [2, 3] => 1 } }

    it 'saves the hash to the database' do
      SentenceChunk.save_chunks_by_insert_all(chunk_hash, text_sample.id, 2)

      expect(SentenceChunk.count).to eq(2)
    end
  end

  describe '::generate' do # rubocop:disable Metrics/BlockLength
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end
    let(:chunk_size) { 3 }
    let(:token_size) { 5 }

    let(:generate_params) do
      { chunk_size: chunk_size,
        token_size: token_size,
        text_sample_id: text_sample.id }
    end

    it 'checks whether SentenceChunks have been generated for given TextSample' do
      allow(SentenceChunk).to receive(:chunks_built_for?)
      allow(SentenceChunk).to receive(:generate_text)
        .and_return({ text: 'some generated text',
                      chunk_size: 'some size' })
      SentenceChunk.generate generate_params
      expect(SentenceChunk).to have_received(:chunks_built_for?)
    end

    context 'SentenceChunks have not been generated' do
      it 'returns a warning' do
        allow(SentenceChunk).to receive(:chunks_built_for?)
          .with(anything)
          .and_return(false)
        result = SentenceChunk.generate generate_params
        expect(result[:message])
          .not_to be(nil)
        expect(result[:message])
          .to match(/Sentence chunks have not been built for this text sample/)
      end
    end

    context 'SentenceChunks have been generated' do # rubocop:disable Metrics/BlockLength
      let(:generated_token_ids) { [1, 2, 3] }
      let(:generated_tokens) { ['some', ' ', 'text'] }
      let(:generated_text) { 'some text' }
      before(:each) do
        allow(SentenceChunk).to receive(:chunks_built_for?).and_return(true)
        allow(SentenceChunk)
          .to receive(:generate_text)
          .and_return({ text: generated_text, chunk_size: chunk_size })
        allow(SentenceChunk)
          .to receive(:extract_generate_params)
          .and_return([chunk_size, token_size, text_sample.id])
        # allow(Token)
        #   .to receive(:replace_token_ids_with_tokens)
        #   .and_return(generated_tokens)
      end

      it 'extracts generate parameters' do
        SentenceChunk.generate generate_params

        expect(SentenceChunk)
          .to have_received(:extract_generate_params)
      end

      context 'for one chunk_size' do
        let(:generation_result) do
          { output: [{ text: generated_text, chunk_size: chunk_size }] }
        end

        it 'generates the tokens' do
          SentenceChunk.generate generate_params
          expect(SentenceChunk)
            .to have_received(:generate_text)
            .with(chunk_size, token_size, text_sample.id)
        end

        it 'returns a hash with the generated text' do
          result = SentenceChunk.generate generate_params

          expect(result).to eq(generation_result)
        end
      end

      context 'for all chunk_sizes' do
        let(:chunk_size) { 'all' }
        let(:generate_params) do
          { chunk_size: :chunk_size,
            token_size: token_size,
            text_sample_id: text_sample.id }
        end

        before(:each) do
          allow(SentenceChunk)
            .to receive(:extract_generate_params)
            .and_return([chunk_size, token_size, text_sample.id])
        end

        it 'generates the right number of texts' do
          SentenceChunk.generate generate_params
          expect(SentenceChunk)
            .to have_received(:generate_text)
            .exactly(SentenceChunk::CHUNK_SIZE_RANGE.size).times
        end

        it 'returns a hash with the generated text' do
          result = SentenceChunk.generate generate_params

          expect(result[:output].size).to eq(SentenceChunk::CHUNK_SIZE_RANGE.size)
        end
      end
    end
  end

  describe '::chunks_built_for?' do
    it 'returns true if built' do
      allow(SentenceChunk).to receive(:find_by).and_return 'something'

      expect(SentenceChunk.chunks_built_for?(-100)).to be true
    end

    it 'returns false if not built' do
      allow(SentenceChunk).to receive(:find_by).and_return nil

      expect(SentenceChunk.chunks_built_for?(-100)).to be false
    end
  end

  describe '::extract_generate_params' do
    let(:text_sample) { TextSample.create!(description: 'Stuff', text: 'another man') }
    let(:chunk_size) { 3 }
    let(:token_size) { 5 }
    let(:generate_params) do
      { chunk_size: chunk_size,
        token_size: token_size,
        text_sample_id: text_sample.id }
    end

    it 'uses default chunk_size and token_size if no params provided' do
      e_chunk_size, e_token_size = SentenceChunk.extract_generate_params

      expect(e_chunk_size).to eq(Setting.chunk_size)
      expect(e_token_size).to eq(Setting.token_size)
    end

    it 'extracts params' do
      e_chunk_size, e_token_size, e_text_sample_id = SentenceChunk
                                                     .extract_generate_params generate_params

      expect(e_chunk_size).to eq(chunk_size)
      expect(e_token_size).to eq(token_size)
      expect(e_text_sample_id).to eq(text_sample.id)
    end
  end

  describe '::generate_text' do # rubocop:disable Metrics/BlockLength
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'another man')
    end

    let(:chunk_size) { 3 }
    let(:token_size) { 5 }
    let(:sentence_chunk) { double('SentenceChunk') }

    before(:each) do
      allow(SentenceChunk)
        .to receive(:choose_starting_chunk).and_return(sentence_chunk)
      allow(sentence_chunk)
        .to receive(:token_ids).and_return([1, 2, 3])
      allow(sentence_chunk)
        .to receive(:choose_next_chunk).and_return(sentence_chunk)
      allow(Token)
        .to receive(:replace_token_ids_with_tokens)
        .and_return(['another', ' ', 'man'])
    end

    it 'chooses a starting chunk' do
      SentenceChunk.generate_text(chunk_size, token_size, text_sample.id)

      expect(SentenceChunk)
        .to(have_received(:choose_starting_chunk)
        .with(text_sample.id, chunk_size))
    end

    it 'generates the right number of extra tokens' do
      SentenceChunk.generate_text(chunk_size, token_size, text_sample.id)

      expect(sentence_chunk)
        .to(have_received(:choose_next_chunk).twice)
    end

    it 'returns a hash with the right keys' do
      result = SentenceChunk.generate_text(chunk_size, token_size, text_sample.id)
      expect(result).to have_key(:chunk_size)
      expect(result).to have_key(:text)
    end
  end

  describe '::choose_starting_chunk' do
    let(:chunk_size) { 3 }
    let(:text_sample) do
      TextSample.create!(description: 'Stuff', text: 'take me to the river')
    end
    let(:text_sample_token_ids) { Token.id_ise(text_sample.text, :sentence) }

    before(:each) do
      SentenceChunk.count_chunks(text_sample_token_ids, text_sample.id, chunk_size)
    end

    it 'all SentenceChunks are potential candidates' do
      candidates = ['take me', ' me ', 'me to', ' to ', 'to the', ' the ', 'the river']

      # if we run this 100 times, it's pretty unlikely we won't get both of
      # these chunks
      100.times do
        candidate_token_ids = SentenceChunk.choose_starting_chunk(
          text_sample.id, chunk_size
        ).token_ids
        candidate_text = Token.replace_token_ids_with_tokens(candidate_token_ids).join
        candidates.delete(candidate_text) if candidates.include?(candidate_text)
        break if candidates.empty?
      end
      expect(candidates).to eq([])
    end

    it 'returns a SentenceChunk' do
      result = SentenceChunk.choose_starting_chunk(text_sample.id, chunk_size)
      expect(result).to be_instance_of(SentenceChunk)
    end
  end

  describe '#choose_next_chunk' do
    let(:where_chain) { double('WhereChain') }
    let(:sentence_chunk) { create(:sentence_chunk) }
    let(:candidates) { double('candidates') }

    before(:each) do
      allow(SentenceChunk).to receive(:choose_chunk_from_candidates)
      allow(SentenceChunk)
        .to receive(:where).and_return(where_chain)

      allow(where_chain).to receive(:limit).and_return(candidates)

      sentence_chunk.choose_next_chunk
    end

    it 'finds candidate sentence chunks' do
      expect(SentenceChunk)
        .to(have_received(:where)
        .with('text_sample_id = :text_sample_id AND size = :sentence_chunk_size AND token_ids[0] = 2',
              { text_sample_id: sentence_chunk.text_sample_id,
                sentence_chunk_size: 2 }))
    end

    it 'chooses word chunk from candidates' do
      expect(SentenceChunk)
        .to(
          have_received(:choose_chunk_from_candidates).with(candidates)
        )
    end
  end

  describe '::choose_chunk_from_candidates' do
    let(:counts_array) { [build(:sentence_chunk), build(:sentence_chunk)] }
    let(:candidates) { double('candidates') }

    before(:each) do
      allow(SentenceChunk)
        .to receive(:build_counts_array).and_return(counts_array)
    end

    it 'calculates probabilities of each word chunk' do
      SentenceChunk.choose_chunk_from_candidates(candidates)

      expect(SentenceChunk)
        .to(have_received(:build_counts_array).with(candidates))
    end

    it 'selects a word chunk' do
      new_chunk = SentenceChunk.choose_chunk_from_candidates(candidates)

      expect(new_chunk).to be_instance_of(SentenceChunk)
    end
  end

  describe '::build_counts_array' do
    let!(:sentence_chunk_1_2) { create(:sentence_chunk, token_ids: [1, 2], count: 2) } # rubocop:disable Naming/VariableNumber
    let!(:sentence_chunk_1_3) { create(:sentence_chunk, token_ids: [1, 3], count: 1) } # rubocop:disable Naming/VariableNumber
    let(:candidates) { SentenceChunk.all }

    it 'has the right number of elements' do
      counts_array = SentenceChunk.build_counts_array(candidates)

      expect(counts_array.size).to eq(3)
    end
  end

  describe '#to_tokens' do
    it 'converts an array of token ids to the text of the tokens' do
      text_sample = TextSample.create!(description: 'Stuff', text: 'take me to the river')
      text_sample.analyse

      sentence_chunk = SentenceChunk.where("text_sample_id = #{text_sample.id}").first
      expect(sentence_chunk.to_tokens).to eq(['take', ' '])
    end
  end
end
