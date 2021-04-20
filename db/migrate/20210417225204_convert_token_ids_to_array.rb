# This will destroy any data in the token_ids column of the sentence_chunks table
class ConvertTokenIdsToArray < ActiveRecord::Migration[6.0]
  def up
    remove_column(:sentence_chunks, :token_ids)
    add_column(:sentence_chunks, :token_ids, :integer, array: true)
  end

  def down
    remove_column(:sentence_chunks, :token_ids)
    add_column(:sentence_chunks, :token_ids, :text)
  end
end
