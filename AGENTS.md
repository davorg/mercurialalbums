# Mercurial Albums repository guide

## What this repository is

This is a Perl static-site generator for <https://mercurialalbums.com/>. The
generated site is committed in `docs/` (the GitHub Pages publishing root).

- `db/mercurial.db` is the database used by the production build and is the
  canonical enriched data store.
- `albums.csv` is a legacy historical import seed and is not part of the current
  maintenance workflow. Leave it unchanged; the enriched production database is
  authoritative.
- `lib/Mercurial/App.pm` enumerates and writes the static pages.
- `lib/Mercurial/Schema*.pm` is the DBIx::Class model over the SQLite database.
- `tt_lib/` contains the Template Toolkit templates.
- `docs/` contains generated HTML, the sitemap, static assets, and album-cover
  images. Album records name their cover explicitly with `cover_filename`; covers are
  exactly 500x500 and are no longer coupled to ASIN filenames.
- `bin/` contains import, enrichment, build, and development utilities.

## Routine data-update workflow

1. Verify the shortlist against the official Mercury Prize site. Preserve the
   official artist and album spelling/capitalization unless there is a strong
   site-consistency reason to do otherwise.
2. Add the year, artists, and albums directly to `db/mercurial.db`, using
   `is_winner=0` until the winner is announced. Prefer a small,
   reviewable script or explicit transaction; do not replace the database.
   Reuse an existing artist row when the exact artist already exists.
   Store a known winner announcement date in `year.winner_announcement_date` using
   ISO `YYYY-MM-DD` format.
3. Populate `sort_name` and `sort_title` using `Mercurial::Sort::sort_value`.
   It trims and collapses whitespace, lowercases the value, and removes a leading whole-word English article
   (`a`, `an`, or `the`). Run `bin/add_album_sort_title db/mercurial.db` to
   backfill both columns after bulk data changes.
4. Add Amazon destinations in `album_retail_link`. `link_type=product` uses an
   ASIN; `link_type=stream` stores a verified Amazon Music album URL. An album can
   have both. Album pages fall back to an Amazon Music search when no exact stream
   URL is known. `bin/mb2asin` should always be run with `--dry-run` first.
5. Add a unique 500x500 cover, set `album.cover_filename`, and record its original
   location in `album.cover_source_url`. Resize proportionally and pad rather than
   cropping artwork.
6. Rebuild the committed output from the production database:

       PERL5LIB=lib bin/build_site --db db/mercurial.db --out docs

   For a disposable preview, use a temporary output directory instead of
   `docs`. `bin/dev` defaults to the empty root-level `mercurialalbums.db`, so
   pass `db/mercurial.db` explicitly if using it:

       PERL5LIB=lib bin/dev db/mercurial.db site

7. Review the generated year page, new/existing artist pages, new album pages,
   indexes, and `docs/sitemap.xml`. The build does not remove stale generated
   files, so check the diff rather than assuming the output directory is clean.
8. Check `git status` and the complete diff. Preserve unrelated working-tree
   files and changes.

When the winner is announced, set exactly one album for that year to
`is_winner=1` in `db/mercurial.db`, then rebuild `docs/`.

Use `bin/set_winner YEAR` to list the shortlisted albums and their IDs. After
verifying the announced result, run `bin/set_winner YEAR ALBUM_ID` to set the
winner transactionally, clearing any previous winner for that year. For 2026:

    bin/set_winner 2026
    bin/set_winner 2026 ALBUM_ID &&
      PERL5LIB=lib bin/build_site --db db/mercurial.db --out docs

Replace `ALBUM_ID` with the ID from the listing. The helper defaults to this
repository's production database; `--db FILE` selects another existing database.
An album outside the selected year's shortlist is rejected without changing
winner flags. The helper updates the database only; the build remains separate.

## Useful checks

Run a clean build into a temporary directory:

    tmpdir=$(mktemp -d)
    PERL5LIB=lib bin/build_site --db db/mercurial.db --out "$tmpdir"

Useful SQLite checks:

    sqlite3 db/mercurial.db \
      'select y.year, count(*) from album a join year y on y.id=a.year_id group by y.year order by y.year;'

    sqlite3 db/mercurial.db \
      'select y.year, sum(a.is_winner) from album a join year y on y.id=a.year_id group by y.year order by y.year;'

Run `prove -v t/set_winner.t` for the winner-update regression checks. These use
disposable databases and cover validation, winner replacement, repeated runs,
transaction rollback, and preservation of other data. There is no dependency
manifest or comprehensive site test suite; verify site changes with a clean
build and inspection of the generated diff/HTML. The code requires modern Perl
(the application uses Perl 5.40 class syntax) and locally installed CPAN dependencies including
DBIx::Class, Template Toolkit, Moose/Moo, and SQLite support.

## File ownership

All files created or modified during maintenance must remain owned by `dave:dave`.
After commands that run with elevated privileges, verify touched files with `stat`
and restore ownership with `chown dave:dave` when necessary.

## Cautions discovered during repository inspection

- Do not edit generated `docs/` pages by hand; change data/templates and build.
- `bin/load` is additive (`find_or_create`) and only imports four CSV fields. It
  will not update existing winner flags or enriched fields.
- `db/mercurial.sql`, the live database, and the DBIx::Class result classes must
  be kept synchronized when schema fields are changed.
- Amazon Music album streams do not themselves earn affiliate income. Product
  links use ASIN affiliate handling; the separate Music Unlimited trial link is
  the bounty-eligible call to action.
- `bin/get_data` scrapes Wikipedia and its simple delimiter parsing has already
  produced malformed historical CSV data. Do not use it as an authoritative,
  unattended import path.
- The root-level `mercurialalbums.db` is an empty file; the actual database is
  `db/mercurial.db`.
