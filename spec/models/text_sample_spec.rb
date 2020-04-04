require 'rails_helper'

RSpec.describe TextSample, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:text) }
  end
end
