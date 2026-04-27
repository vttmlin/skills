---
name: mysql
description: |
  MySQL CLI tool with SSH tunnel support. Use when you need to:
  - Connect to MySQL database through SSH tunnel
  - Execute SQL queries with JSON output
  - Manage multiple database configurations
  - Open interactive MySQL shell

  Triggers: "mysql", "MySQL", "database query", "ssh tunnel mysql", "connect to mysql", "mysql-cli"
---

## Overview

MySQL CLI tool that connects to MySQL databases via local `mysql` client binary. Supports SSH tunnel for secure connections through bastion hosts. All output is JSON. Every execution is logged.

## Setup

### Prerequisites

- `mysql` client installed and accessible in PATH
- SSH key-based authentication configured (if using SSH tunnel)

### Binary

```
./scripts/mysql-cli-{os}-{arch}
```

| Platform | Binary |
|----------|--------|
| macOS Apple Silicon | `mysql-cli-darwin-arm64` |
| macOS Intel | `mysql-cli-darwin-amd64` |
| Linux ARM64 | `mysql-cli-linux-arm64` |
| Linux x86_64 | `mysql-cli-linux-amd64` |
| Windows | `mysql-cli-windows-amd64.exe` |

### Config

Config path is auto-derived from the binary location: `~/.skills/vttmlin/skills/mysql/{md5}/config.yml`

```yaml
databases:
  <name>:
    database:
      host: <mysql_host>
      port: 3306
      user: <username>
      password: <password>
      name: <database_name>
      readonly: true        # optional, default false
    ssh:
      enabled: <true|false>
      host: <bastion_host>
      port: 22               # optional, default 22
      user: <ssh_user>
      key_path: <path_to_key>  # optional
      local_port: <port>        # optional, auto-assign if omitted
      ssh_config_host: <host>  # optional, read from ~/.ssh/config
```

`ssh_config_host`: When set, reads HostName/User/Port/IdentityFile from `~/.ssh/config` for that host. Config-level values take precedence over SSH config values.

### Environment Variables

| Variable | Description |
|----------|-------------|
| `MYSQL_SKILL_DIR` | Override SKILL.md directory resolution (for development) |

### Logs

Logs are written to `~/.skills/vttmlin/skills/mysql/{md5}/logs/YYYY-MM-DD.log`. Every command execution and SQL statement is logged.

## Usage

### List databases

```bash
./scripts/mysql-cli-darwin-arm64 list
```

### Execute a query

```bash
./scripts/mysql-cli-darwin-arm64 query -d <name> -q "SELECT * FROM users LIMIT 10"
```

### Open interactive shell

```bash
./scripts/mysql-cli-darwin-arm64 connect -d <name>
```

### Show version

```bash
./scripts/mysql-cli-darwin-arm64 version
```

## Output

### Success

```json
{
  "columns": ["id", "name"],
  "rows": [
    [1, "Alice"],
    [2, "Bob"]
  ]
}
```

### Error

```json
{
  "error": "database not found, available: [OmniClick, diyring]",
  "code": 1
}
```

## Commands

| Command | Description |
|---------|-------------|
| `list` | List all configured database names |
| `query -d <name> -q <sql>` | Execute SQL query, return JSON results |
| `connect -d <name>` | Open interactive MySQL shell |
| `version` | Show version info |

## Troubleshooting

**`database not found`**
- Verify config file exists under the correct `{md5}` directory
- Check that the database name matches the key in config.yml

**`tunnel port not ready: timeout waiting for port`**
- Verify SSH key and bastion host accessibility
- Check if the configured `local_port` is already in use

**`read-only mode: only SELECT/SHOW/DESCRIBE/EXPLAIN queries are allowed`**
- Set `readonly: false` in the database config to allow all queries
