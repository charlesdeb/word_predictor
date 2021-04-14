class RenameTextToTokenIds < ActiveRecord::Migration[6.0]
  def up
    change_table :sentence_chunks do |t|
      t.rename :text, :token_ids
    end
  end

  def down
    change_table :sentence_chunks do |t|
      t.rename :token_ids, :text
    end
  end
end
