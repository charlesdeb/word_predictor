# frozen_string_literal: true

# All the tokens that make up the text analysis. At time of writing, a token
# can be a single character, punctuation mark (incl. space) or a word.
# It is also case sensitive, but this may need to be changed
# It may be a whole lot more efficient to store these as serialized values or
# even the potgres hstore column type - but for now, we'll use a simple table
class Token < ApplicationRecord
  validates :token, length: { minimum: 1 }

  def self.id_ise(text, strategy = :sentence)
    text_tokens = split_into_tokens(text, strategy)

    # ensure the database has a store of all these tokens - we'll need their IDs soon
    set_text_token_ids(text_tokens)

    # replace each token with its ID
    replace_tokens_with_token_ids(text_tokens)
  end

  # 'hey, man!'  -> ["hey", ",", " ", "man", "!"]
  #
  # we could make this simpler just by breaking on spaces and ditching
  # punctuation eg 'hey, man!' -> ["hey", "man"]
  # We treat a single space as different to multiple spaces
  #
  # text_sample_tokens = text_sample.text
  #                                 .split(/\s|\p{Punct}/)
  #                                 .compact
  #                                 .reject(&:empty?)
  def self.split_into_tokens(text, _strategy = :sentence)
    text
      .split(/(\s+)|(\p{Punct})/)
      .compact
      .reject(&:empty?)
  end

  def self.set_text_token_ids(text_tokens, _strategy = :sentence)
    current_time = DateTime.now

    # strip out the duplicate tokens. Although insert all will do this, it's
    # more efficient to do it in memory here
    unique_text_tokens = text_tokens.uniq
    unique_text_tokens_import = unique_text_tokens.map do |the_token|
      { token: the_token,
        created_at: current_time, updated_at: current_time }
    end

    # Stick in the database
    Token.insert_all unique_text_tokens_import
  end

  # convert an array of text tokens to an array of token ids
  #
  # @param [Array] text_tokens
  def self.replace_tokens_with_token_ids(text_tokens)
    text_tokens.map do |token|
      Token.where({ token: token }).first.id
    rescue NoMethodError
      raise StandardError, "Unknown token (#{token}). You may need to reanalyse the source text"
    end
  end

  # convert an array of token ids to an array of text tokens
  #
  # @param [Array] token_ids
  def self.replace_token_ids_with_tokens(token_ids)
    token_ids.map do |token_id|
      Token.where({ id: token_id }).first.token
    rescue NoMethodError
      raise StandardError, "Unknown token id(#{token_id}). You may need to reanalyse the source text"
    end
  end
end
