# DATAFIX AUTOMATION

Small Ruby utility to help automate datafix tickets:

- An input spreadsheet (XLSX/XLS) that contains account / subscription information.
- A PHP admin export (YAML) that contains IDs and related metadata.

The tool parses both sources and produces two sets of records:

- Account data (`build_account_data`)
- Subscription data (`build_subscription_data`)

These are printed to STDOUT so you can inspect them or pipe them into other tools.

## Requirements

- Ruby (2.6+ should work; matches your local system Ruby).
- Bundler.
- Gems from the `Gemfile` (notably `roo`):

```bash
bundle install
```

Run all commands from the project root (the folder containing `Gemfile`).

## Project Structure
<details><summary>Project Structure</summary>

```
.
├── bin
│   └── datafix
├── config
│   └── datafix.yml
├── data
│   ├── input
│   │   └── November 2025 Datafix for missing subs requested 7th november (3).xlsx
│   ├── mappings
│   │   └── Untitled-2.yaml
│   └── SELECT cb.id as client_business_id, cb.csv
├── Gemfile
├── Gemfile.lock
├── lib
│   ├── datafix
│   │   ├── build_data.rb
│   │   └── parse_files.rb
│   └── datafix.rb
└── README.md
```

- `bin/datafix` – command‑line entrypoint.
- `lib/datafix.rb` – defines the `DataFix` module and requires subcomponents.
- `lib/datafix/parse_files.rb` – `DataFix::ParseFiles`, handles XLSX/YAML parsing and column selection.
- `lib/datafix/build_data.rb` – `DataFix::BuildData`, combines parsed input + PHP admin data.
- `data/`
  - `data/input/` – input spreadsheets (`.xlsx` / `.xls`).
  - `data/mappings/` – mapping files (`.yaml` / `.yml`).
- `config/datafix.yml` – default configuration (see below).

> `bin/datafix` will look for configuration in `config/datafix.yml` first (if it exists) and fall back to `datafix.yml` in the project root.
</details>

## Configuration

Configuration is a simple YAML file with the paths to your input and mapping files. Example (`datafix.yml` at the project root):

```yaml
input_file: "data/input/November 2025 Datafix for missing subs requested 7th november (3).xlsx"
php_admin_file: "data/mappings/Untitled-2.yaml"
```
## CLI Usage

The main entrypoint is `bin/datafix`. You can run it with or without options:

```bash
ruby bin/datafix [options] [INPUT.xlsx MAPPING.yml]
```

Options:

- `-c`, `--config PATH` – path to a config YAML (overrides the default lookup).
- `-i`, `--input PATH` – path to the input spreadsheet (XLSX/XLS).
- `-m`, `--mapping PATH` – path to the mapping YAML.
- `--only TARGETS` – run a subset of builders:
  - `accounts` – only build account data.
  - `subs` or `subscriptions` – only build subscription data.
  - `both` – run both builders (default behaviour).
- `-h`, `--help` – show help and exit.

Resolution order for file paths:

1. CLI options (`--input`, `--mapping`) if provided.
2. Positional arguments (`INPUT.xlsx MAPPING.yml`).
3. Config file (`input_file`, `php_admin_file` keys).

If neither source provides both paths, the tool prints the usage message and exits.

### Examples

Use default config (`datafix.yml` or `config/datafix.yml`):

```bash
ruby bin/datafix
```

Override both files on the command line:

```bash
ruby bin/datafix -i data/input/other_input.xlsx -m data/mappings/other_mapping.yaml
```

Run only subscription data build:

```bash
ruby bin/datafix --only subs
```

## Interactive Column Selection

When parsing files, `DataFix::ParseFiles` will:

- For XLSX:
  - Print available column headers with indices.
  - Prompt you to choose a "main" lookup column and one or more additional columns to extract.
- For YAML:
  - Locate the first `type: table` entry.
  - Print available keys and prompt similarly for the main key and additional keys.

