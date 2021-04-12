# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Token, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_length_of(:token).is_at_least(1) }
  end

  describe '::id_ise' do
    let(:text) { 'boo hoo' }
    let(:text_tokens) { ['boo', ' ', 'hoo'] }

    before(:each) do
      allow(Token).to receive(:split_into_tokens).and_return(text_tokens)
      allow(Token).to receive(:set_text_token_ids)
      allow(Token).to receive(:replace_tokens_with_token_ids)
      Token.id_ise(text)
    end

    it 'splits text into tokens' do
      expect(Token).to have_received(:split_into_tokens).with(text, anything)
    end

    it 'sets token ids for tokens' do
      expect(Token).to have_received(:set_text_token_ids)
    end

    it 'replaces tokens with token ids' do
      expect(Token).to have_received(:replace_tokens_with_token_ids).with(text_tokens)
    end
  end

  describe '::split_into_tokens' do # rubocop:disable Metrics/BlockLength
    describe ' :sentence is the default strategy ' do
      it 'handles: hey!' do
        result = Token.split_into_tokens('hey!')
        expect(result).to eq(['hey', '!'])
      end
    end

    describe ' for sentence strategy' do # rubocop:disable Metrics/BlockLength
      let(:strategy) { :strategy }
      it 'handles: hey!' do
        result = Token.split_into_tokens('hey!', strategy)
        expect(result).to eq(['hey', '!'])
      end

      it 'handles: hey, dude!' do
        result = Token.split_into_tokens('hey, dude!', strategy)
        expect(result).to eq(['hey', ',', ' ', 'dude', '!'])
      end

      it 'handles: hey,  dude! (double space)' do
        result = Token.split_into_tokens('hey,  dude!', strategy)
        expect(result).to eq(['hey', ',', '  ', 'dude', '!'])
      end

      it 'handles: hey  dude (double space)' do
        result = Token.split_into_tokens('hey  dude', strategy)
        expect(result).to eq(['hey', '  ', 'dude'])
      end

      it "handles: hey hey'" do
        result = Token.split_into_tokens('hey hey', strategy)
        expect(result).to eq(['hey', ' ', 'hey'])
      end

      it "handles: hey, I said 'dude!'" do
        result = Token.split_into_tokens("hey, I said 'dude!'", strategy)
        expect(result).to eq(['hey', ',', ' ', 'I', ' ', 'said',
                              ' ', '\'', 'dude', '!', '\''])
      end
    end

    describe ' for word strategy' do
      it 'handles: abc'
      it 'handles: abc!'
      it 'handles: ab c\''
    end
  end

  describe '::set_text_token_ids' do
    it 'adds the right number of tokens' do
      text_tokens = %w[the hat]
      Token.set_text_token_ids(text_tokens)
      expect(Token.count).to eq(2)
    end

    it 'handles spaces' do
      text_tokens = ['the', ' ', 'hat']
      Token.set_text_token_ids(text_tokens)
      expect(Token.count).to eq(3)
    end

    it 'handles duplicate tokens in the text' do
      text_tokens = %w[the hat hat]
      Token.set_text_token_ids(text_tokens)
      expect(Token.count).to eq(2)
    end

    it "it doesn't add duplicate tokens from a previous analysis" do
      # Add the 'hat' token
      Token.create!({ token: 'hat', created_at: DateTime.now })

      # Try to add 'hat#' again
      text_tokens = %w[the hat]
      Token.set_text_token_ids(text_tokens)
      expect(Token.count).to eq(2)
    end
  end

  describe '::replace_tokens_with_token_ids' do
    before(:each) do
      current_time = DateTime.now
      Token.create!({ id: 1, token: 'the', created_at: current_time })
      Token.create!({ id: 2, token: ' ', created_at: current_time })
      Token.create!({ id: 3, token: 'hat', created_at: current_time })
    end

    it 'works' do
      text_tokens = ['the', ' ', 'hat']
      result = Token.replace_tokens_with_token_ids(text_tokens)
      expect(result).to eq([1, 2, 3])
    end

    it 'handles duplicates' do
      text_tokens = ['the', ' ', 'hat', ' ', 'hat']
      result = Token.replace_tokens_with_token_ids(text_tokens)
      expect(result).to eq([1, 2, 3, 2, 3])
    end

    it 'handles missing tokens' do
      text_tokens = ['the', ' ', 'cat']
      expect { Token.replace_tokens_with_token_ids(text_tokens) }.to raise_error(/Unknown token/)
    end
  end
end
