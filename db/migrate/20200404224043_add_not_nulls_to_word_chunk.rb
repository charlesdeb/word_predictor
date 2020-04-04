class AddNotNullsToWordChunk < ActiveRecord::Migration[6.0]
  def up
    change_column_null :word_chunks, :text, false
    change_column_null :word_chunks, :size, false
    change_column_null :word_chunks, :count, false
  end

  def down
    change_column_null :word_chunks, :text, true
    change_column_null :word_chunks, :size, true
    change_column_null :word_chunks, :count, true
  end
end
