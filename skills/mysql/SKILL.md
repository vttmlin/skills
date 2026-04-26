---
name: mysql
description: |
  MySQL CLI tool with SSH tunnel support. Use when you need to:
  - Connect to MySQL database through SSH tunnel
  - Execute read-only SQL queries
  - Manage multiple database configurations
  - Query databases with JSON output

  Triggers: "mysql", "MySQL", "database query", "ssh tunnel mysql", "connect to mysql", "mysql-cli"
---

## Overview

This skill provides a MySQL CLI tool that automatically establishes SSH tunnels for secure database connections and executes queries in read-only mode.

## Setup

### Prerequisites

- SSH access to bastion host (if using SSH tunnel)
- SSH key-based authentication configured

### Step 1: Locate the mysql-cli binary

The binary is located at:
```
/Users/vttmlin/workspace/part-time/skills/skills-cli/bin/mysql/mysql-cli-darwin-arm64
```

Available binaries:
- `mysql-cli-darwin-arm64` - macOS Apple Silicon
- `mysql-cli-darwin-amd64` - macOS Intel
- `mysql-cli-linux-arm64` - Linux ARM64
- `mysql-cli-linux-amd64` - Linux x86_64

### Step 2: Configure databases

#### Config path

```bash
# Skill directory: /Users/vttmlin/workspace/part-time/skills/skills/skills/mysql
# MD5: 083b3499dbb89f8e87bd69448d33178a

# Config path: ~/.skills/vttmlin/skills/mysql/083b3499dbb89f8e87bd69448d33178a/config.yml
mkdir -p ~/.skills/vttmlin/skills/mysql/083b3499dbb89f8e87bd69448d33178a
```

#### Config file format (NESTED structure)

**IMPORTANT: This skill uses NESTED YAML structure (database settings under `database:` key)!**

```yaml
databases:
  <connection_name>:
    database:
      host: <mysql_host>
      port: 3306
      user: <username>
      password: <password>
      name: <database_name>
    ssh:
      enabled: <true|false>
      host: <bastion_host>     # only if ssh enabled
      user: <ssh_user>         # only if ssh enabled
      key_path: <path_to_key>  # only if ssh enabled
      local_port: <port>        # only if ssh enabled
```

### Configuration Examples

**Example 1: Direct connection (no SSH tunnel)**
```yaml
databases:
  OmniClick:
    database:
      host: 192.168.192.32
      port: 3306
      user: root
      password: Yxx521125.
      name: OmniClick
    ssh:
      enabled: false
```

**Example 2: Connection via SSH tunnel**
```yaml
databases:
  production:
    database:
      host: 127.0.0.1
      port: 3306
      user: readonly_user
      password: prod_pass
      name: production_db
    ssh:
      enabled: true
      host: bastion.example.com
      user: jump
      key_path: ~/.ssh/id_rsa
      local_port: 13306
```

## Usage

### List configured databases

```bash
/Users/vttmlin/workspace/part-time/skills/skills-cli/bin/mysql/mysql-cli-darwin-arm64 list
```

### Execute a query

```bash
/Users/vttmlin/workspace/part-time/skills/skills-cli/bin/mysql/mysql-cli-darwin-arm64 query -d <connection_name> -q "SELECT * FROM users LIMIT 10"
```

### Output format

All output is JSON:

```json
{
  "columns": ["id", "name", "email"],
  "rows": [
    [1, "John", "john@example.com"],
    [2, "Jane", "jane@example.com"]
  ]
}
```

### Error format

```json
{
  "error": "database not found",
  "code": 1
}
```

## Commands

| Command | Description |
|---------|-------------|
| `list` | List all configured databases |
| `query -d <db> -q <sql>` | Execute SQL query |
| `version` | Show version info |

## Troubleshooting

**Problem: `database not found`**
- Verify config is at: `~/.skills/vttmlin/skills/mysql/083b3499dbb89f8e87bd69448d33178a/config.yml`
- Verify config uses NESTED structure (database settings under `database:` key)

**Problem: `read-only mode: only SELECT queries are allowed`**
- The `readonly: true` setting only allows SELECT queries
- To allow other queries, set `readonly: false` in config (use with caution)
