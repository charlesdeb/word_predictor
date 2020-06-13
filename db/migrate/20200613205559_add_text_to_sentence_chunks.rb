class AddTextToSentenceChunks < ActiveRecord::Migration[6.0]
  def change
    add_column :sentence_chunks, :text, :string
    add_index :sentence_chunks, :text
  end
end
