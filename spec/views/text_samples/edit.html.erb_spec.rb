require 'rails_helper'

RSpec.describe "text_samples/edit", type: :view do
  before(:each) do
    @text_sample = assign(:text_sample, TextSample.create!(
      description: "MyString",
      text: "MyText"
    ))
  end

  it "renders the edit text_sample form" do
    render

    assert_select "form[action=?][method=?]", text_sample_path(@text_sample), "post" do

      assert_select "input[name=?]", "text_sample[description]"

      assert_select "textarea[name=?]", "text_sample[text]"
    end
  end
end
