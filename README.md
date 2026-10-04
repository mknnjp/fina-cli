# fina — Swift-Native CLI for Firefly III

A fast, type-safe command-line client for [Firefly III](https://www.firefly-iii.org/), built with Swift 6 and `swift-argument-parser`. Manage accounts and transactions without leaving your terminal. 🚀

## ✨ Features

| Feature | Description |
|---|---|
| 🏦 `accounts list` | List accounts with balances in an aligned table |
| 🧾 `transactions list` | List transactions with `--limit` and `--account` filters |
| ➕ `transactions create` | Create a single-split transaction (withdrawal / deposit / transfer) |
| ✏️ `transactions update` | Update a single-split transaction by ID |
| ⚙️ Flexible config | JSON config file with environment-variable fallback |
| 🔒 Secure by default | Config file permissions hardened to `0600` on load |
| � Scriptable | `--format json` emits machine-readable output for piping into `jq` or scripts |
| �🧪 Tested | Unit tests with fixture-backed networking mocks |

## 📋 Requirements

| Requirement | Version / Detail |
|---|---|
| 🍎 Swift | `6.3.3` (see `.swift-version`) |
| 📦 SwiftPM | Bundled with the Swift toolchain |
| 🌐 Firefly III | Running instance with API access (`/api/v1`) |
| 🔑 API token | Personal access token from Firefly III (`Profile` → `OAuth`) |
| 💻 Platform | macOS or Linux |

## 📦 Installation

### 1️⃣ Clone the repository

```bash
git clone https://github.com/mknnjp/fina-cli.git
cd fina-cli
```

### 2️⃣ Build the release binary

```bash
swift build -c release
```

### 3️⃣ Install to your `PATH` (optional)

```bash
cp .build/release/fina /usr/local/bin/fina
fina --help
```

> 💡 Tip: during development, run directly with `swift run fina -- <args>`.

## ⚙️ Configuration

`fina` resolves credentials in the following priority order:

| Priority | Source | Detail |
|---|---|---|
| 🥇 1st | 📄 Config file | `~/.config/fina/config.json` (values take precedence) |
| 🥈 2nd | 🌿 Environment | `FINA_BASE_URL` and `FINA_TOKEN` fill gaps / act as fallback |

### 📄 Option A — Config file

```json
{
  "baseURL": "https://firefly.example.com",
  "token": "your-personal-access-token"
}
```

```bash
mkdir -p ~/.config/fina
cat > ~/.config/fina/config.json <<'JSON'
{
  "baseURL": "https://firefly.example.com",
  "token": "your-personal-access-token"
}
JSON
chmod 600 ~/.config/fina/config.json
```

> 🔒 File permissions are automatically tightened to `0600` on successful load. `base_url` (snake_case) is also accepted as a key.

### 🌿 Option B — Environment variables

| Variable | Description | Example |
|---|---|---|
| `FINA_BASE_URL` | Base URL of the Firefly III instance | `https://firefly.example.com` |
| `FINA_TOKEN` | Personal access token | `eyJ0eXAiOiJKV1QiLCJhbGci...` |

```bash
export FINA_BASE_URL="https://firefly.example.com"
export FINA_TOKEN="your-personal-access-token"
```

## 🖥️ Usage

```bash
fina --help
fina accounts --help
fina transactions --help
```

### 📚 Command reference

| Command | Purpose | Key options |
|---|---|---|
| 🏦 `fina accounts list` | List accounts with balances | `--format <plain\|json>` |
| 🧾 `fina transactions list` | List transactions | `--limit <n>`, `--account <id-or-name>`, `--format <plain\|json>` |
| ➕ `fina transactions create` | Create a single-split transaction | `--type`, `--date`, `--amount`, `--description`, `--source`, `--destination`, `--currency`, `--format <plain\|json>` |
| ✏️ `fina transactions update <id>` | Update a single-split transaction | `--journal-id`, `--type`, `--date`, `--amount`, `--description`, `--source`, `--destination`, `--currency`, `--format <plain\|json>` |

### 🏦 List accounts

```bash
fina accounts list
```

Example output:

```text
ID  NAME            TYPE     CURRENCY  BALANCE
1   Main Checking   asset    JPY       125000
2   Cash Wallet     asset    JPY       12000
```

### 🧾 List transactions

```bash
fina transactions list --limit 10
fina transactions list --account "Main Checking"
fina transactions list --limit 20 --account 1
```

Example output:

```text
ID  DATE        DESCRIPTION      TYPE        AMOUNT  SOURCE         DESTINATION
12  2026-09-01  Grocery run      withdrawal  5400    Main Checking  Supermarket
13  2026-09-02  Salary           deposit     300000  Employer       Main Checking
```

| Option | Required | Description |
|---|---|---|
| `--limit <n>` | No | Maximum number of transactions |
| `--account <id-or-name>` | No | Filter by account ID or name |

### ➕ Create a transaction

```bash
fina transactions create \
  --type withdrawal \
  --date 2026-09-11 \
  --amount 1500 \
  --description "Coffee beans" \
  --source "Main Checking" \
  --destination "Cafe" \
  --currency JPY
```

| Option | Required | Description |
|---|---|---|
| `--type` | ✅ Yes | `withdrawal`, `deposit`, or `transfer` |
| `--date` | ✅ Yes | `YYYY-MM-DD` |
| `--amount` | ✅ Yes | Decimal amount as a string (e.g. `1500`) |
| `--description` | ✅ Yes | Human-readable description |
| `--source` | ✅ Yes | Source account ID or name |
| `--destination` | ✅ Yes | Destination account ID or name |
| `--currency` | No | Currency code (e.g. `JPY`, `USD`) |

### ✏️ Update a transaction

```bash
fina transactions update 12 --amount 1600 --description "Coffee beans (updated)"
fina transactions update 12 --journal-id 45 --date 2026-09-10 --currency JPY
```

| Option | Required | Description |
|---|---|---|
| `<id>` | ✅ Yes | Transaction ID (positional argument) |
| `--journal-id` | No | Transaction journal ID |
| `--type` / `--date` / `--amount` / `--description` | No | Fields to update |
| `--source` / `--destination` / `--currency` | No | Account / currency overrides |

## 📤 Output formats

Every command accepts `--format <plain|json>` (short `-f`). The default is `plain`, so existing
invocations are unchanged.

| Format | Status | Description |
|---|---|---|
| 📝 `plain` | ✅ Default | Fixed-width aligned tables for humans |
| 🧩 `json` | ✅ Available | Compact single-line JSON for scripts |

The option is accepted at any command depth — both positions below are equivalent:

```bash
fina --format json accounts list
fina accounts list --format json
```

### 📝 Plain text (default)

```bash
fina accounts list
```

```text
ID  NAME            TYPE     CURRENCY  BALANCE
1   Main Checking   asset    JPY       125000
2   Cash Wallet     asset    JPY       12000
```

### 🧩 JSON

```bash
fina accounts list --format json
```

```json
{"accounts":[{"balance":"125000","currency":"JPY","id":"1","name":"Main Checking","type":"asset"},{"balance":"12000","currency":"JPY","id":"2","name":"Cash Wallet","type":"asset"}]}
```

| Command | Top-level JSON key |
|---|---|
| `accounts list` | `accounts` |
| `transactions list` | `transactions` |
| `transactions create` / `update` | `action`, `id` |

Piping into `jq`:

```bash
# Account names only
fina accounts list --format json | jq -r '.accounts[].name'

# Transactions over 1000, most recent first
fina transactions list --limit 20 --format json | jq '.transactions[] | select(.amount > 1000)'

# Capture the ID of a created transaction
id=$(fina transactions create --type withdrawal --date 2026-09-11 --amount 1500 \
  --description "Coffee" --source "Main Checking" --destination "Cafe" --format json | jq -r '.id')
```

### ⚠️ Errors

Success output goes to **stdout**; errors go to **stderr** and exit non-zero. With
`--format json`, errors are wrapped in an `error` object:

```bash
$ fina accounts list --format json
# stderr:
{"error":"Missing config at /home/you/.config/fina/config.json. Expected JSON with required fields: baseURL, token."}
```

> 💡 Tip: argument errors (for example an unknown `--format` value) are always plain text with a usage hint, even when `--format json` is requested. Help output is plain text too.

## 🏗️ Project structure

| Path | Description |
|---|---|
| `Sources/fina/` | Executable entry point (`@main`) |
| `Sources/FinaCore/Commands/` | `accounts` and `transactions` subcommands |
| `Sources/FinaCore/Commands/Shared/` | Shared `CommandContext` and `ClientFactory` wiring |
| `Sources/FinaCore/Config/` | `FinaConfig`, `ConfigLoader`, `ConfigError` |
| `Sources/FinaCore/Models/` | `Account`, `Transaction`, `Budget`, API envelopes |
| `Sources/FinaCore/Networking/` | `FireflyClient`, `FireflyAPI`, error mapping |
| `Sources/FinaCore/Output/` | Plain-table and JSON formatters |
| `Tests/finaTests/` | Unit tests + JSON fixtures |

## 🧪 Development

| Task | Command |
|---|---|
| 🔨 Build | `swift build` |
| ▶️ Run | `swift run fina -- accounts list` |
| ✅ Test | `swift test` |
| 🧹 Format check | `swiftformat --lint .` (if installed) |

## ⚠️ Error handling

| Situation | Behavior |
|---|---|
| 📭 Missing config | Clear error with expected path and required fields (`baseURL`, `token`) |
| 🧨 Invalid JSON / bad URL | `ConfigError.invalid` with reason |
| 🌐 HTTP `4xx` / `5xx` | `FireflyError.requestFailed` with status code and body message |
| 🧩 Decoding failure | `FireflyError.decodingFailed` with detail |

## 🗺️ Roadmap

| Status | Item |
|---|---|
| ✅ Done | Accounts list, transactions list / create / update |
| 🚧 Next | `--format json` wiring, budgets commands |
| 🔮 Later | Pagination, search filters, interactive setup (`fina init`) |

## 🤝 Contributing

1. 🍴 Fork the repository.
2. 🌱 Create a branch (e.g. `feature/add-budgets-list`).
3. 💾 Commit with [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat(budgets): add budgets list command`).
4. 📬 Open a pull request.

See `.github/instructions/` for branch and commit conventions.

## 📄 License

BSD 3-Clause License. See [LICENSE](./LICENSE) for details. © 2026 mknnjp.
