# README

The ideas behind this little app can be found at https://hlml.blog/2020/04/25/what-comes-next/.

This repo just contains the source code and tests used to build it out - along with the real Ruby code as opposed to the pseudo-code the blog post has in it.

You are welcome to clone and try to run it. It's a standard Ruby on Rails app (6.0.22). The only caveat is that it uses an array database column for the `sentence_chunks` table, so if you don't use Postgres, the schema might not work too well. Otherwise, it's just the same old `rake db:migrate`

## Is it efficient?

Not really. You'll get a ton of rows in your database for text of any great length - especially for the `WordChunk` strategy. This is just a hobby project.

## Why Ruby and not Python?

I like Ruby (and Rspec) and right now, I don't know Python that well.

## Why do WordChunk and SentenceChunk look _very_ similar

Laziness. They should be refactored and likely will be in the next iteration of this project.
