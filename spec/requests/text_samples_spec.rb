# frozen_string_literal: true

require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe '/text_samples', type: :request do # rubocop:disable Metrics/BlockLength
  # TextSample. As you add validations to TextSample, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    { description: 'Something here', text: 'Lots more text' }
  end

  let(:invalid_attributes) do
    { description: '', text: '' }
  end

  describe 'GET /index' do
    it 'renders a successful response' do
      TextSample.create! valid_attributes
      get text_samples_url
      expect(response).to be_successful
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      text_sample = TextSample.create! valid_attributes
      get text_sample_url(text_sample)
      expect(response).to be_successful
    end
  end

  describe 'GET /new' do
    it 'renders a successful response' do
      get new_text_sample_url
      expect(response).to be_successful
    end
  end

  describe 'GET /edit' do
    it 'renders a successful response' do
      text_sample = TextSample.create! valid_attributes
      get edit_text_sample_url(text_sample)
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do # rubocop:disable Metrics/BlockLength
    context 'with valid parameters' do
      it 'creates a new TextSample' do
        expect do
          post text_samples_url, params: { text_sample: valid_attributes }
        end.to change(TextSample, :count).by(1)
      end

      # it 'builds new WordChunk records' do
      it 'analyses text sample' do
        text_sample = TextSample.create!(valid_attributes)
        allow(TextSample).to receive(:new).and_return(text_sample)
        allow(text_sample).to receive(:analyse)
        post text_samples_url, params: { text_sample: valid_attributes }
        expect(text_sample).to have_received(:analyse)
      end

      it 'redirects to the created text_sample' do
        post text_samples_url, params: { text_sample: valid_attributes }
        expect(response).to redirect_to(text_sample_url(TextSample.last))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new TextSample' do
        expect do
          post text_samples_url, params: { text_sample: invalid_attributes }
        end.to change(TextSample, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post text_samples_url, params: { text_sample: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /update' do # rubocop:disable Metrics/BlockLength
    context 'with valid parameters' do
      let(:new_attributes) do
        { description: 'Something new here', text: 'Lots more changed text' }
      end

      it 'updates the requested text_sample' do
        text_sample = TextSample.create! valid_attributes
        patch text_sample_url(text_sample), params: {
          text_sample: new_attributes
        }
        text_sample.reload
        skip('Add assertions for updated state')
      end

      it 'redirects to the text_sample' do
        text_sample = TextSample.create! valid_attributes
        patch text_sample_url(text_sample), params: { text_sample: new_attributes }
        text_sample.reload
        expect(response).to redirect_to(text_sample_url(text_sample))
      end
    end

    context 'with invalid parameters' do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        text_sample = TextSample.create! valid_attributes
        patch text_sample_url(text_sample), params: { text_sample: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /reanalyse' do
    it 'sets success flash' do
      text_sample = TextSample.create! valid_attributes

      patch reanalyse_text_sample_url(text_sample)

      expect(flash[:notice]).to eq('Text sample reanalysed successfully')
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the requested text_sample' do
      text_sample = TextSample.create! valid_attributes
      expect do
        delete text_sample_url(text_sample)
      end.to change(TextSample, :count).by(-1)
    end

    it 'redirects to the text_samples list' do
      text_sample = TextSample.create! valid_attributes
      delete text_sample_url(text_sample)
      expect(response).to redirect_to(text_samples_url)
    end
  end

  describe 'GET /generate' do # rubocop:disable Metrics/BlockLength
    let(:text_sample) { TextSample.create! valid_attributes }
    let(:chunk_size) { 3 }
    let(:output_size) { 100 }
    let(:generate_params) do
      { chunk_size: chunk_size, output_size: output_size }
    end

    before(:each) do
      allow(TextSample)
        .to receive(:find).and_return(text_sample)
    end

    describe 'setting generate parameters' do
      let(:generation_result) { { message: 'bad' } }

      before(:each) do
        allow(text_sample)
          .to receive(:generate).and_return(generation_result)

        get generate_text_sample_url(text_sample), params: {
          chunk_size: chunk_size, output_size: output_size
        }
      end

      it 'sets chunk_size in form to last chosen value' do
        # ensure chunk size is set
        regexp = Regexp.new(
          "<option selected=\"selected\" value=\"#{chunk_size}\">#{chunk_size}"
        )
        expect(response.body).to match regexp

        # ensure output size is set
        regexp = Regexp.new(
          "id=\"output_size\" value=\"#{output_size}\""
        )
        expect(response.body).to match regexp
      end
    end

    context 'WordChunks have not been built' do
      let(:generation_result) { { message: 'bad' } }

      before(:each) do
        allow(text_sample)
          .to receive(:generate).and_return(generation_result)
        get generate_text_sample_url(text_sample), params: {
          chunk_size: chunk_size, output_size: output_size
        }
      end

      it 'renders a successful response' do
        expect(response).to be_successful
      end

      it 'sets a flash message' do
        expect(flash[:notice]).to eq(generation_result[:message])
      end
    end

    context 'WordChunks have been built' do
      let(:generated_text) { 'some text' }

      let(:generation_result) do
        { output: [{ text: generated_text, chunk_size: chunk_size }] }
      end

      before(:each) do
        allow(text_sample)
          .to receive(:generate).and_return(generation_result)

        get generate_text_sample_url(text_sample), params: {
          chunk_size: chunk_size, output_size: output_size
        }
      end

      it 'renders a successful response' do
        expect(response).to be_successful
      end

      it 'contains the generated text' do
        expect(response.body).to include(generated_text)
      end
    end
  end
end
