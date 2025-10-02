CREATE TABLE year (id INTEGER PRIMARY KEY, year INTEGER NOT NULL UNIQUE CHECK(year BETWEEN 1800 AND 2100));
CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
CREATE TABLE album (id INTEGER PRIMARY KEY, title TEXT NOT NULL, artist_id INTEGER NOT NULL REFERENCES artist(id) ON DELETE RESTRICT, year_id INTEGER NOT NULL REFERENCES year(id) ON DELETE RESTRICT, is_winner boolean not null default false, UNIQUE(title, artist_id));
CREATE INDEX idx_album_artist ON album(artist_id);
CREATE INDEX idx_album_year   ON album(year_id);
