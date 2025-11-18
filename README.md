# DATAFIX AUTOMATION

Small Ruby utility to help automate datafix tickets:

- An input spreadsheet (XLSX/XLS) that contains account / subscription information.
- A PHP admin export (YAML) that contains IDs and related metadata.

The tool parses both sources and produces two sets of records:

- Account data (`build_account_data`)
- Subscription data (`build_subscription_data`)

The combined results are written as pretty-printed JSON to an output file and also printed to STDOUT so you can inspect them or pipe them into other tools.

## Requirements

- Ruby (2.6+).
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
│   │   ├── November 2025 Datafix for missing subs requested 11th November (1).xlsx
│   │   └── November 2025 Datafix for missing subs requested 7th november (3).xlsx
│   ├── mappings
│   │   ├── datafix_nov_11.yaml
│   │   └── datafix_nov_7.yaml
│   ├── output
│   │   └── SBS-152399-datafix.json
│   └── queries
│       ├── MSO.txt
│       └── PE.txt
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
  - `data/output/` – generated JSON output files.
  - `data/queries/` – helper SQL/text queries used when preparing datafix inputs.
- `config/datafix.yml` – default configuration (see below).

> `bin/datafix` reads configuration via `DataFix.config`, which looks for `config/datafix.yml` relative to the project root / library paths.
</details>

## Configuration

Configuration lives in a YAML file (typically `config/datafix.yml`) and is split into a `files` section and a `settings` section.

```yaml
files:
  input_file: "data/input/xxx.xlsx"
  php_admin_file: "data/mappings/xxx.yaml"

  # Optional: override the default output path
  output_file: "data/output/xxx.json"
  # Optional: placeholder for future logging
  log_file: "data/logs/..."

settings:
  # Input spreadsheet (XLSX/XLS)
  lookup_column_input: "Client GUID"
  target_columns_input:
    - "Account Number for Client"
    - "Subscription Number Created 1"
    - "Subscription Number Created 2"

  # PHP admin export (YAML)
  lookup_column_php_admin: "client_business_guid"
  target_columns_php_admin:
    - "client_business_id"
    - "account_number"
    - "sub_id"
    - "subscription_number"

  # Behaviour flags
  target_columns: false # if true, only use the configured target_* columns
  manual: false         # if true, prompt interactively for columns
```

You can keep sensible defaults in `config/datafix.yml` and still override them with CLI flags for one-off runs.

## CLI Usage

The main entrypoint is `bin/datafix`. You can run it with or without options:

```bash
ruby bin/datafix [options] [INPUT.xlsx MAPPING.yml]
```

Options:

- `-c`, `--config PATH` – path to a config YAML (defaults to `config/datafix.yml` via `DataFix.config`).
- `-i`, `--input PATH` – path to the input spreadsheet (XLSX/XLS).
- `-m`, `--mapping PATH` – path to the PHP admin mapping YAML.
- `-o`, `--output PATH` – path (and file name) for the output JSON file.
- `--manual` – enable manual column selection prompts.
- `--no-manual` – disable manual column selection prompts.
- `--only TARGETS` – run a subset of builders:
  - `accounts` – only build account data.
  - `subs` or `subscriptions` – only build subscription data.
  - `both` – run both builders (default behaviour).
- `-h`, `--help` – show help and exit.

Resolution order for input/mapping file paths:

1. CLI options (`--input`, `--mapping`) if provided.
2. Positional arguments (`INPUT.xlsx MAPPING.yml`).
3. Config file (`files.input_file`, `files.php_admin_file` keys in `config/datafix.yml`).

If neither source provides both paths, the tool prints the usage message and exits.

Resolution order for the output JSON path:

1. CLI option (`--output PATH`) if provided.
2. Config file (`files.output_file` key in `config/datafix.yml`), if present and non-empty.
3. Fallback: `data/output/<normalized_input_filename>_datafix.json`.

In all cases, the JSON is also printed to STDOUT.

### Examples

Use default config (`config/datafix.yml`):

```bash
ruby bin/datafix
```

Override both files on the command line:

```bash
ruby bin/datafix -i data/input/other_input.xlsx -m data/mappings/other_mapping.yaml
```

Custom output file:

```bash
ruby bin/datafix -i data/input/other_input.xlsx -m data/mappings/other_mapping.yaml -o data/output/custom_datafix.json
```

Run only subscription data build:

```bash
ruby bin/datafix --only subs
```

Enable interactive column selection for a single run:

```bash
ruby bin/datafix --manual
```

## Output Format

Running `bin/datafix` produces a JSON object with two top-level keys:

- `accounts` – array of account records built by `DataFix::BuildData#build_account_data`.
- `subscriptions` – array of subscription records built by `DataFix::BuildData#build_subscription_data`.

Each account record includes:

- `client_business_guid`
- `client_business_id`
- `zuora_account_number`

Each subscription record includes:

- `client_business_guid`
- `sub_id`
- `zuora_subscription_number`

Example shape:

```json
{
  "accounts": [
    {
      "client_business_guid": "...",
      "client_business_id": 123,
      "zuora_account_number": "A-000123"
    }
  ],
  "subscriptions": [
    {
      "client_business_guid": "...",
      "sub_id": 456,
      "zuora_subscription_number": "SUB-000456"
    }
  ]
}
```

## Interactive Column Selection

Column selection is controlled by the `settings` section in `config/datafix.yml`:

- `manual`:
  - When `true` (or when you pass `--manual`), the CLI will prompt you to choose columns.
  - When `false` (or when you pass `--no-manual`), the CLI uses configured or inferred columns without prompting.
- `target_columns`:
  - When `true`, the lists in `target_columns_input` / `target_columns_php_admin` are used.
  - When `false`, all columns are used (unless manual mode is enabled).

When manual mode is enabled, `DataFix::ParseFiles` will:

- For XLSX:
  - Print available column headers with indices.
  - Prompt you to choose a "main" lookup column and one or more additional columns to extract.
- For YAML:
  - Locate the first `type: table` entry.
  - Print available keys and prompt similarly for the main key and additional keys.
