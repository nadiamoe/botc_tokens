# Running botc_tokens in Docker

## Build
```bash
docker build --build-arg VERSION=2025.2.23 -t botc_tokens .
```
`VERSION` is only used for `botc_tokens version`. It defaults to `0.0.0`.

The image has Python 3.12, ImageMagick 6 (needed by Wand), and the ImageMagick PDF policy fix so `group` can write PDFs.
The default fonts, leaves, and backgrounds are bundled, so there is nothing else to download. Role icons are fetched by
`update`, which needs internet access.

## Run
The entrypoint is `botc_tokens` and the working dir is `/work`, so mount your files there:
```bash
docker run --rm -v "$PWD":/work botc_tokens <command> [args]
```

## Order of commands
```
update  ->  (trim-icons)  ->  create  ->  group
```

### 1. update
```bash
docker run --rm -v "$PWD":/work botc_tokens update -o inputs
```
- Downloads `roles.json` and `nightsheet.json` from the script tool. Missing ability text and reminders are scraped
  from the wiki. Icons are downloaded and trimmed.
- Writes `inputs/<edition>/<team>/<id>.json` plus the icon next to each one.
- Incremental: existing role JSONs and icons are kept, so hand edits survive.
- `--reminders reminders.json` overrides the wiki's reminder guesses (validated against a schema).
- `--script-filter Experimental` only pulls roles whose version contains that text. Default is everything.
- `-c/--custom-list <file or https url>` only updates the roles in a custom script JSON. Bare string entries are
  looked up in the official data.
- `--use-playtest` takes icons from the `tomozbot/botc-icons` GitHub repo instead of the wiki.

You can skip this step and write the role JSON and icons by hand. A role JSON needs `name`, `ability`, `reminders`,
`type`, `home_script`, and an `icon` path relative to the JSON file.

### 2. trim-icons (optional)
```bash
docker run --rm -v "$PWD":/work botc_tokens trim-icons my_icons -i
```
Crops transparent borders. `update` already does this for downloaded icons, so it only matters for your own. Without
`-i` it writes `*_trimmed.png` copies instead of overwriting.

### 3. create
```bash
docker run --rm -v "$PWD":/work botc_tokens create inputs -o tokens
```
- Reads every `*.json` under the search dir, so keep unrelated JSON out of it.
- Writes `tokens/<home_script>/<type>/<id>.png` plus `<id>-Reminder-<text>.png` for each reminder.
- Skips tokens that already exist. Delete a PNG to regenerate it.
- Options: `--components <dir or zip>`, `--role-diameter` (default 575), `--reminder-diameter` (default 325),
  `--skip-ability-text`.

To customize the look, dump the defaults, edit them, and point `create` at them:
```bash
docker run --rm -v "$PWD":/work botc_tokens dump-components mycomps
docker run --rm -v "$PWD":/work botc_tokens create inputs --components mycomps
```

### 4. group
```bash
docker run --rm -v "$PWD":/work botc_tokens group script.json --token-dir tokens -o printables
```
- `script.json` is an export from the official script tool (`_meta` is skipped). A directory of token PNGs works too,
  and `--token-dir` is then ignored.
- Roles are matched to PNGs by id, lowercased with underscores and apostrophes stripped. Misses print a warning.
- Writes `printables/roles.pdf` and `printables/reminders.pdf`.
- Default page is 2550x3300 pixels (Letter at 300 dpi). Options: `--paper-width`, `--paper-height`,
  `--margin-horizontal`, `--margin-vertical`, `--padding`, `--grid` (instead of close packing), and
  `--duplicates dup.json` for per-role copy counts.
