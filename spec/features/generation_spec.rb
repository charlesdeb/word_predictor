# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Generating Text', type: :feature do
  let(:text_sample) { create(:text_sample_two_chars) }
  # let(:text_sample) { double('text_sample') }
  let(:generated_text) { 'some text' }
  let(:generation_result) { { text: generated_text } }

  before(:each) do
    # text_sample.build_word_chunks
    # allow(TextSample).to receive(:find).and_return(text_sample)
    allow(text_sample)
      .to receive(:generate).and_return(generation_result)
  end

  # scenario 'User generates with default settings' do
  #   visit text_sample_path text_sample

  #   click_button 'Generate'

  #   expect(text_sample)
  #     .to have_received(:generate)
  #     .with({ chunk_size: TextSample::DEFAULT_CHUNK_SIZE.to_s,
  #             output_size: TextSample::DEFAULT_OUTPUT_SIZE.to_s,
  #             id: text_sample.id.to_s })
  # end
end
