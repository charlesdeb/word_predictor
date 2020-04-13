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
    allow(@text_sample)
      .to receive(:generate_text)
      .and_return('The rain in Spain')
    @generated_text = @text_sample.generate_text

    render

    expect(rendered).to match(/Generated Text/)
    expect(rendered).to match(/The rain in Spain/)
  end
end
