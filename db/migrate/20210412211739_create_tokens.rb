class CreateTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :tokens do |t|
      t.text :token

      t.timestamps
    end
    add_index :tokens, :token, unique: true
  end
end
