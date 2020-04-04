class CreateTextSamples < ActiveRecord::Migration[6.0]
  def change
    create_table :text_samples do |t|
      t.string :description
      t.text :text

      t.timestamps
    end
  end
end
