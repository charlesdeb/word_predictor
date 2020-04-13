# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'text_samples/show', type: :view do
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
end
