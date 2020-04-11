# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'text_samples/show', type: :view do
  before(:each) do
    @text_sample = assign(:text_sample, TextSample.create!(
                                          description: 'Description',
                                          text: 'MyText'
                                        ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/MyText/)
  end
end
