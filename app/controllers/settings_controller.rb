# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :get_setting, only: %i[edit update]

  def create
    setting_params.keys.each do |key|
      unless setting_params[key].nil?
        Setting.send("#{key}=", setting_params[key].strip)
      end
    end
    redirect_to settings_path, notice: 'Setting was successfully updated.'
  end

  private

  def setting_params
    params.require(:setting).permit(:chunk_size, :output_size)
  end
end
