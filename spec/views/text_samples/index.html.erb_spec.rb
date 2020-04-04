require 'rails_helper'

RSpec.describe "text_samples/index", type: :view do
  before(:each) do
    assign(:text_samples, [
      TextSample.create!(
        description: "Description",
        text: "MyText"
      ),
      TextSample.create!(
        description: "Description",
        text: "MyText"
      )
    ])
  end

  it "renders a list of text_samples" do
    render
    assert_select "tr>td", text: "Description".to_s, count: 2
    assert_select "tr>td", text: "MyText".to_s, count: 2
  end
end
