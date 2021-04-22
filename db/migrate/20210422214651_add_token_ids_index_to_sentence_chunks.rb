class AddTokenIdsIndexToSentenceChunks < ActiveRecord::Migration[6.0]
  def change
    add_index :sentence_chunks, :token_ids, using: 'gin'
  end
end
