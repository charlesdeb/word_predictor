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

  it 'shows generated text' do
    chunk_size = 3
    output_size = 100
    generate_params = { chunk_size: chunk_size, output_size: output_size }

    allow(@text_sample)
      .to receive(:generate)
      .and_return({ text: 'The rain in Spain' })
    @generated_text = @text_sample.generate(generate_params)[:text]

    render

    expect(rendered).to match(/Generated Text/)
    expect(rendered).to match(/The rain in Spain/)
  end

  it 'shows a drop down for chunk size with a default' do
    r = Regexp.new(
      "<option selected=\"selected\" value=\"#{TextSample::DEFAULT_CHUNK_SIZE}\">#{TextSample::DEFAULT_CHUNK_SIZE}</option>"
    )
    render
    expect(rendered).to match r
  end
  it 'sets the default output size' do
    r = Regexp.new(
      "id=\"output_size\" value=\"#{TextSample::DEFAULT_OUTPUT_SIZE}\""
    )
    render
    expect(rendered).to match r
  end
end
