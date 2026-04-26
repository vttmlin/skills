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

- MySQL client installed (`mysql` command)
- SSH access to bastion host (if using SSH tunnel)
- SSH key-based authentication configured

### Configuration

Create `~/.skills/vttmlin/mysql/{md5}/config.yml` where `{md5}` is the MD5 hash of the skill directory path:

```yaml
databases:
  <database_name>:
    database:
      host: "<mysql_host>"
      port: 3306
      user: "<username>"
      password: "<password>"
      name: "<database_name>"
    ssh:
      enabled: true
      host: "<bastion_host>"
      user: "<ssh_user>"
      key_path: "~/.ssh/id_rsa"
      local_port: 13306
```

## Usage

### List configured databases

```bash
mysql-cli list
```

### Execute a query

```bash
mysql-cli query -d <database_name> -q "SELECT * FROM users LIMIT 10"
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
