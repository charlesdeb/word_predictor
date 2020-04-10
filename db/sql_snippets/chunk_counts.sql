SELECT
  size,
  unique_word_chunks "# Unique Word Chunks",
  chunk_single_occurences "# Chunk Single Occurrences",
  to_char((chunk_single_occurences::float / unique_word_chunks) * 100,'99D9%') "Percentage of single chunk appearances"
FROM (
  SELECT
    size,
    (
      SELECT
        count(size)
      FROM
        word_chunks wc2
      WHERE
        text_sample_id = wc1.text_sample_id
        AND wc1.size = wc2.size) AS unique_word_chunks,
      (
        SELECT
          count(wc3.count)
        FROM
          word_chunks wc3
        WHERE
          text_sample_id = wc1.text_sample_id
          AND wc1.size = wc3.size
        GROUP BY
          wc3.count
        HAVING
          wc3.count = 1) AS chunk_single_occurences
      FROM
        word_chunks wc1
      WHERE
        text_sample_id = 10
      GROUP BY
        size,
        wc1.text_sample_id
      ORDER BY
        2) subquery;

