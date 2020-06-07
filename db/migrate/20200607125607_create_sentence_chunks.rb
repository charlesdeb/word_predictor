# frozen_string_literal: true

class CreateSentenceChunks < ActiveRecord::Migration[6.0]
  def change
    create_table :sentence_chunks do |t|
      t.integer :size, null: false
      t.integer :count, null: false
      t.references :text_sample, null: false, foreign_key: true
    end
    add_index :sentence_chunks, :size
  end
end
