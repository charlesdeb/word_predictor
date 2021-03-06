# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_04_22_214651) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "sentence_chunks", force: :cascade do |t|
    t.integer "size", null: false
    t.integer "count", null: false
    t.bigint "text_sample_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "token_ids", array: true
    t.index ["size"], name: "index_sentence_chunks_on_size"
    t.index ["text_sample_id"], name: "index_sentence_chunks_on_text_sample_id"
    t.index ["token_ids"], name: "index_sentence_chunks_on_token_ids", using: :gin
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "text_samples", force: :cascade do |t|
    t.string "description", null: false
    t.text "text", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tokens", force: :cascade do |t|
    t.text "token"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["token"], name: "index_tokens_on_token", unique: true
  end

  create_table "word_chunks", force: :cascade do |t|
    t.string "text", null: false
    t.integer "size", null: false
    t.integer "count", null: false
    t.bigint "text_sample_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["size"], name: "index_word_chunks_on_size"
    t.index ["text"], name: "index_word_chunks_on_text"
    t.index ["text_sample_id"], name: "index_word_chunks_on_text_sample_id"
  end

  add_foreign_key "sentence_chunks", "text_samples"
  add_foreign_key "word_chunks", "text_samples"
end
