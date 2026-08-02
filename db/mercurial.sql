CREATE TABLE year (id INTEGER PRIMARY KEY, year INTEGER NOT NULL UNIQUE CHECK(year BETWEEN 1800 AND 2100));
CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, sort_name text not null default name, blurb text);
CREATE TABLE album (id INTEGER PRIMARY KEY, title TEXT NOT NULL, artist_id INTEGER NOT NULL REFERENCES artist(id) ON DELETE RESTRICT, year_id INTEGER NOT NULL REFERENCES year(id) ON DELETE RESTRICT, is_winner boolean not null default false, blurb text, sort_title text, cover_filename text, cover_source_url text, UNIQUE(title, artist_id));
CREATE INDEX idx_album_artist ON album(artist_id);
CREATE INDEX idx_album_year   ON album(year_id);
CREATE TABLE album_retail_link (
  id        INTEGER PRIMARY KEY,
  album_id  INTEGER NOT NULL REFERENCES album(id) ON DELETE CASCADE,
  retailer  TEXT    NOT NULL,            -- 'amazon'
  country   TEXT    NOT NULL,            -- 'GB'
  asin      TEXT,                         -- for Amazon
  url       TEXT,                         -- full affiliate/deep link
  link_type TEXT    NOT NULL DEFAULT 'product', -- product, stream, or search
  UNIQUE(album_id, retailer, country, link_type)
);
CREATE INDEX idx_retail_album ON album_retail_link(album_id);
