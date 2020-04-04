class AddNotNulls < ActiveRecord::Migration[6.0]
  def up
    change_column_null :text_samples, :description, false
    change_column_null :text_samples, :text, false
  end

  def down
    change_column_null :text_samples, :description, true
    change_column_null :text_samples, :text, true
  end
end
