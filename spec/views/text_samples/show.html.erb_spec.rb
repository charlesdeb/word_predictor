# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'text_samples/show', type: :view do # rubocop:disable Metrics/BlockLength
  before(:each) do
    @text_sample = assign(:text_sample, TextSample.create!(
                                          description: 'Description',
                                          text: 'MyText'
                                        ))
  end

  it 'renders attributes' do
    render
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/MyText/)
  end

  context 'plain show' do # rubocop:disable Metrics/BlockLength
    before(:each) do
      render
    end

    it 'shows a drop down for generate strategy with a default' do
      generate_strategy = Setting.generate_strategy
      regexp = Regexp.new(
        "<option selected=\"selected\" value=\"#{generate_strategy}\">"
      )
      expect(rendered).to match regexp
    end

    it 'sets the default output size' do
      output_size = Setting.output_size
      regexp = Regexp.new(
        "id=\"output_size\" value=\"#{output_size}\""
      )
      render
      expect(rendered).to match regexp
    end

    it 'shows a drop down for chunk size with a default' do
      chunk_size = Setting.chunk_size
      regexp = Regexp.new(
        "<option selected=\"selected\" value=\"#{chunk_size}\">"
      )
      expect(rendered).to match regexp
    end

    it "shows a drop down with 'all chunk sizes'" do
      regexp = Regexp.new(
        '<option (.*) value="all">All Chunk Sizes'
      )
      expect(rendered).to match regexp
    end

    it 'shows a drop down for prior word count with a default' do
      prior_word_count = Setting.prior_word_count
      regexp = Regexp.new(
        "<option selected=\"selected\" value=\"#{prior_word_count}\">"
      )
      expect(rendered).to match regexp
    end

    it "shows a drop down with 'all prior word counts'" do
      regexp = Regexp.new(
        '<option (.*) value="all">All Prior Word Counts'
      )
      expect(rendered).to match regexp
    end
  end

  context 'after generation' do # rubocop:disable Metrics/BlockLength
    let(:generated_text) { 'some text' }
    let(:chunk_size) { 3 }
    let(:output_size) { 33 }

    describe 'uses form values from last time' do
      let(:request) do
        double('request',
               query_parameters: {
                 output_size: output_size, chunk_size: chunk_size
               })
      end

      it 'sets chunk_size to the last chosen value' do
        regexp = Regexp.new(
          "<option selected=\"selected\" value=\"#{chunk_size}\">#{chunk_size}"
        )
        render template: 'text_samples/show.html.erb',
               locals: { request: request }
        expect(rendered).to match regexp
      end

      it 'sets output_size to the last chosen value' do
        regexp = Regexp.new(
          "id=\"output_size\" value=\"#{output_size}\""
        )
        render template: 'text_samples/show.html.erb',
               locals: { request: request }
        expect(rendered).to match regexp
      end
    end

    it 'shows text for one chunk size' do
      @generated_texts = [{ text: generated_text, chunk_size: chunk_size }]

      render

      expect(rendered).to match(/Generated Text/)
      expect(rendered).not_to match(/Generated Texts/)

      regexp = Regexp.new("Chunk Size #{chunk_size}")
      expect(rendered).not_to match(regexp)

      regexp = Regexp.new(generated_text)
      expect(rendered).to match(regexp)
    end

    it 'shows text for multiple chunk sizes' do
      @generated_texts = [
        { text: "#{generated_text}-2", chunk_size: 2 },
        { text: "#{generated_text}-3", chunk_size: 3 }
      ]

      render

      expect(rendered).to match(/Generated Texts/)

      expect(rendered).to match(/Chunk Size 2/)
      expect(rendered).to match(/Chunk Size 3/)

      regexp = Regexp.new("#{generated_text}-2")
      expect(rendered).to match(regexp)

      regexp = Regexp.new("#{generated_text}-3")
      expect(rendered).to match(regexp)
    end
  end
end
