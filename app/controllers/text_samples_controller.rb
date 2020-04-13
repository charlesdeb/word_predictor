# frozen_string_literal: true

class TextSamplesController < ApplicationController
  before_action :set_text_sample, only: %i[show edit update destroy generate]

  # GET /text_samples
  # GET /text_samples.json
  def index
    @text_samples = TextSample.all
  end

  # GET /text_samples/1
  # GET /text_samples/1.json
  def show; end

  # GET /text_samples/new
  def new
    @text_sample = TextSample.new
  end

  # GET /text_samples/1/edit
  def edit; end

  # GET /text_samples/1/generate
  def generate
    @generated_text = @text_sample.generate_text generate_params
    # TODO: change the form_with in the show so that it submits via AJAX. This
    # method would then return a piece of JS that adds the new text to the DOM
    respond_to do |format|
      format.html { render :show }
    end
  end

  # POST /text_samples
  # POST /text_samples.json
  def create # rubocop:disable Metrics/MethodLength
    @text_sample = TextSample.new(text_sample_params)
    respond_to do |format|
      if @text_sample.save
        # TODO: it may be better to have the model call this with a callback -
        # or maybe it's better to do it explicitly
        # https://guides.rubyonrails.org/active_record_callbacks.html
        @text_sample.build_word_chunks

        format.html { redirect_to @text_sample, notice: 'Text sample was successfully created.' }
        format.json { render :show, status: :created, location: @text_sample }
      else
        format.html { render :new }
        format.json { render json: @text_sample.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /text_samples/1
  # PATCH/PUT /text_samples/1.json
  def update
    respond_to do |format|
      if @text_sample.update(text_sample_params)
        format.html { redirect_to @text_sample, notice: 'Text sample was successfully updated.' }
        format.json { render :show, status: :ok, location: @text_sample }
      else
        format.html { render :edit }
        format.json { render json: @text_sample.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /text_samples/1
  # DELETE /text_samples/1.json
  def destroy
    @text_sample.destroy
    respond_to do |format|
      format.html { redirect_to text_samples_url, notice: 'Text sample was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_text_sample
    @text_sample = TextSample.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def text_sample_params
    params.require(:text_sample).permit(:description, :text)
  end

  # Only allow a list of trusted parameters through.
  def generate_params
    params.permit(:chunk_size, :output_size)
  end
end
