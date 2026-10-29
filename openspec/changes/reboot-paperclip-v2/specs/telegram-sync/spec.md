## Purpose
Defines the headless Telegram Bot sync worker that securely ingests notes from mobile devices into atomic inbox files with zero idle RAM.

## Requirements

### Requirement: Secure Credential Management & Authorization
The sync worker SHALL never accept authentication tokens via command-line arguments.

#### Scenario: Token Resolution
- **WHEN** `telegram_sync.py` runs
- **THEN** it resolves the bot token from Windows Credential Manager (`Paperclip/TelegramBotToken`) or a gitignored `sync/.env` file
- **AND** all error logs sanitize the token from request URLs (`/bot<REDACTED>/`)

#### Scenario: Unauthorized Chat Dropping
- **WHEN** an incoming update arrives from a `chat.id` or `from.id` not present in `ALLOWED_CHAT_IDS`
- **THEN** the update is logged as an unauthorized drop and acknowledged without writing any file to the vault

### Requirement: Process Mutual Exclusion & Network Resilience
The worker SHALL guarantee single-instance execution and bounded network calls.

#### Scenario: Concurrent Sync Invocation
- **WHEN** a sync is triggered while another sync is currently running
- **THEN** the second process detects an active `.sync.lock` file and immediately terminates with code 0

#### Scenario: Network Timeouts & HTTP 429
- **WHEN** communicating with `api.telegram.org`
- **THEN** all HTTP requests enforce `timeout=10`
- **AND** HTTP 429 rate limit responses parse `parameters.retry_after` and set a cooldown in `.telegram_state.json`

### Requirement: Idempotent Atomic Ingestion & Non-Text Defense
Each message SHALL be written to disk safely without race conditions or crashes on media attachments.

#### Scenario: Non-Text Message Payloads
- **WHEN** an incoming message contains voice notes, photos, or documents rather than text
- **THEN** the worker defensive extractor captures duration/file details without crashing on missing `text` keys

#### Scenario: Deterministic Collision-Proof Filenames
- **WHEN** writing an authorized note
- **THEN** the file is saved to `Dev/home/00-inbox/tg/{timestamp}_{update_id}-tg.md` using exclusive creation (`mode="x"`)
- **AND** `.telegram_state.json` updates transactionally via temporary file + `os.replace`
