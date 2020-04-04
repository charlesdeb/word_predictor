require 'rails_helper'

RSpec.describe "text_samples/new", type: :view do
  before(:each) do
    assign(:text_sample, TextSample.new(
      description: "MyString",
      text: "MyText"
    ))
  end

  it "renders new text_sample form" do
    render

    assert_select "form[action=?][method=?]", text_samples_path, "post" do

      assert_select "input[name=?]", "text_sample[description]"

      assert_select "textarea[name=?]", "text_sample[text]"
    end
  end
end
