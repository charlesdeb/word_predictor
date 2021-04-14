class AddTimestampsToSentenceChunks < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :sentence_chunks
  end
end
