---
name: opencode-summary
description: |
  总结 OpenCode 会话历史，提取项目知识和业务特性并持久化到文档。

  从 opencode.db 数据库读取当前项目的所有会话数据，用 AI 总结成结构化知识文档，
  写入 docs/opencode-summary/ 目录。支持变更检测（仅重新总结有更新的会话）和并行处理。

  Triggers: "总结会话", "总结项目", "回顾会话", "回顾历史", "session summary",
  "opencode summary", "总结历史会话", "持久化项目知识", "提取业务知识"
---

# OpenCode Session Summary

从 opencode.db 数据库中提取当前项目的会话内容，AI 总结为结构化的项目知识文档，持久化到 `docs/opencode-summary/` 目录。

## 数据库位置

```
DB_PATH="$HOME/.local/share/opencode/opencode.db"
```

确认文件存在后再继续。如果不存在，告知用户并停止。

## 第一步：项目匹配

SKILL.md 的绝对路径即为项目定位的锚点。

1. 确定本 SKILL.md 的绝对路径（从 skill 加载信息中获取）
2. 查询所有项目：
   ```bash
   sqlite3 "$DB_PATH" "SELECT id, worktree FROM project;"
   ```
3. 对每条记录做前缀匹配：SKILL.md 路径以 `worktree` 开头 → 候选
4. 多条匹配时取 `length(worktree)` 最长的（最精确匹配）
5. 记录匹配到的 `PROJECT_ID` 和 `PROJECT_WORKTREE`

示例：
```
skill_path: /Users/vttmlin/workspace/part-time/skills/.opencode/skills/opencode-summary/SKILL.md
候选:
  /Users/vttmlin/workspace/part-time/skills       ← 最长匹配 ✅
  /Users/vttmlin/workspace/part-time/skills/skills ← 不匹配
```

## 第二步：查询会话

```bash
sqlite3 "$DB_PATH" "SELECT id, parent_id, title, time_created, time_updated FROM session WHERE project_id = '${PROJECT_ID}' ORDER BY time_created ASC;"
```

构建父子关系：
- `parent_id` 为空 → 主会话
- `parent_id` 有值 → 子会话（归属对应的主会话）

每个主会话 + 其所有子会话 = 一个总结单元。

## 第三步：变更检测

对每个主会话：

1. 获取 `session.time_updated`（unix timestamp）
2. 检查输出文件是否存在：`{PROJECT_WORKTREE}/docs/opencode-summary/{main-session-id}.md`
3. 判断逻辑：
   - 文件不存在 → 需要总结
   - 文件存在且 `文件 mtime >= session.time_updated` → 跳过（已最新）
   - 文件存在且 `文件 mtime < session.time_updated` → 需要重新总结

用 bash 实现：
```bash
OUTPUT_FILE="${PROJECT_WORKTREE}/docs/opencode-summary/${SESSION_ID}.md"
if [ -f "$OUTPUT_FILE" ]; then
    FILE_MTIME=$(stat -f %m "$OUTPUT_FILE")
    if [ "$FILE_MTIME" -ge "$SESSION_TIME_UPDATED" ]; then
        # 跳过，已最新
        continue
    fi
fi
# 需要总结
```

收集所有需要总结的主会话列表。

## 第四步：提取会话内容

对每个需要总结的主会话（含其子会话），提取 part 数据：

```bash
# 获取主会话和所有子会话 ID
SESSION_IDS=$(sqlite3 "$DB_PATH" "SELECT id FROM session WHERE id = '${MAIN_SESSION_ID}' OR parent_id = '${MAIN_SESSION_ID}';")

# 构建 IN 子句
IN_CLAUSE=$(echo "$SESSION_IDS" | tr '\n' ',' | sed 's/,$//' | sed 's/^/(/;s/$/)/' | sed 's/\([^,]*\)/\"\1\"/g' | sed 's/,,/,/g')

# 提取 part 数据
sqlite3 "$DB_PATH" "
SELECT p.id, p.session_id, p.time_created, p.data
FROM part p
WHERE p.session_id IN ${IN_CLAUSE}
  AND json_extract(p.data, '$.type') IN ('text', 'tool', 'file', 'patch', 'agent')
ORDER BY p.time_created ASC;
"
```

### 内容预处理

逐条解析 part 的 JSON data 字段：

- **text 类型** (`json_extract(data, '$.type') = 'text'`)：
  - 提取 `json_extract(data, '$.text')`
  - 过滤掉包含 `<skill-instruction>` 的内容
  - 超过 2000 字符截断为前 2000 + `...[truncated]`

- **tool 类型** (`json_extract(data, '$.type') = 'tool'`)：
  - 提取工具名：`json_extract(data, '$.tool')`
  - 提取状态：`json_extract(data, '$.state.status')`
  - 提取简要参数：`json_extract(data, '$.state.input')` 截断到 200 字符
  - 格式：`[tool] {tool_name} ({status}): {参数摘要}`

- **file 类型** (`json_extract(data, '$.type') = 'file'`)：
  - 提取文件路径信息
  - 格式：`[file] {路径信息}`

- **patch 类型** (`json_extract(data, '$.type') = 'patch'`)：
  - 统计变更行数（`+` 行数和 `-` 行数），不包含完整 diff
  - 格式：`[patch] +{N}/-{M} 行`

- **agent 类型** (`json_extract(data, '$.type') = 'agent'`)：
  - 提取任务描述
  - 格式：`[agent] {任务描述}`

将预处理后的内容按时间顺序拼接为一个文本块，作为总结的输入。

## 第五步：AI 总结

读取 `references/summary-template.md` 获取总结模板和规则。

对每个会话的预处理文本，使用 LLM 进行总结。总结 prompt：

```
你是一个项目知识总结专家。请根据以下会话内容，提取该项目相关的业务知识和特性。

## 总结模板

### 会话目标
[1-2 句话描述这次会话要完成什么]

### 关键决策
- [记录会话中做出的重要技术/业务决策及原因]

### 业务知识发现
- [从对话中发现的项目特性、业务规则、约定俗成]

### 工具使用模式
- [会话中频繁使用的工具/模式]

### 待跟进事项
- [未完成的任务、遗留问题、需要人工确认的点]

## 规则
- 不包含代码片段或代码变更摘要
- 不包含 skill 指令内容
- 聚焦于「项目知识」而非「操作日志」
- 如会话内容无有价值的知识，输出「无显著知识沉淀」
- 使用中文总结
- 每个字段控制在 3-5 个要点以内

## 会话内容

{预处理后的会话文本}
```

### 并行策略

- 需要总结的会话数 ≤ 3：串行逐个处理
- 需要总结的会话数 > 3：并行处理，同时最多 5 个并行任务
- 每个并行任务用 `task(category="quick", load_skills=[])` 委派

## 第六步：写入文件

每个总结结果写入：

```
{PROJECT_WORKTREE}/docs/opencode-summary/{main-session-id}.md
```

文件 frontmatter 格式：

```yaml
---
session_id: {main-session-id}
title: {会话标题}
child_sessions:
  - {child-id-1}
  - {child-id-2}
time_created: {datetime(time_created, 'unixepoch')}
time_updated: {datetime(time_updated, 'unixepoch')}
generated_at: {当前 ISO 8601 时间}
---
```

frontmatter 之后紧跟总结内容。

确保 `docs/opencode-summary/` 目录存在：
```bash
mkdir -p "${PROJECT_WORKTREE}/docs/opencode-summary"
```

## 第七步：报告结果

完成后输出总结：

```
## 总结完成

- 项目: {PROJECT_WORKTREE}
- 总会话数: {N}
- 已总结（跳过）: {M}
- 新增/更新: {K}
- 输出目录: docs/opencode-summary/

{如果有无显著知识沉淀的会话，列出}
```

不要自动提交 git。告知用户可查看总结文件，人工复核后自行决定是否将有价值的内容整合到 AGENTS.md 或项目文档中。
