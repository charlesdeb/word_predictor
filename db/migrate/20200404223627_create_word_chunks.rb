class CreateWordChunks < ActiveRecord::Migration[6.0]
  def change
    create_table :word_chunks do |t|
      t.string :text
      t.integer :size
      t.integer :count
      t.references :text_sample, null: false, foreign_key: true

      t.timestamps
    end
    add_index :word_chunks, :text
    add_index :word_chunks, :size
  end
end
