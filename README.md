# vttmlin/skills

**dev-workflow**：一套从 issue 到合并交付的通用开发流程 skill，不绑定语言和项目。

原则是**并行写，排队建，合并验**：调研、写文档、写代码、审查都尽量并行；构建和测试全局只有一个槽位，所有调用排队执行；测试和审查统一在集成分支上做。

## Skills

| skill | 作用 |
|---|---|
| `dev-workflow` | 入口和底座：判断当前处于哪个阶段并转交；提供共享约定、`dev-agent` 定义和构建锁脚本 |
| `dev-issue` | Issue 阶段：读取 issue，并行调研出事实清单，查重，确认是否要做 |
| `dev-requirements` | 需求阶段：拷问到没有遗漏，拆分 sub-issue，为每个 sub-issue 生成 OpenSpec change |
| `dev-implement` | 开发阶段：给任务分组，每组派一个 `dev-agent`，在独立 worktree 里按 TDD + ub-mode 实现 |
| `dev-test` | 测试阶段：合并到集成分支统一测试，并行审查，返工，然后发 PR、归档 |
| `dev-install` | 把套件安装到项目里：补齐依赖，初始化 OpenSpec，注册 `dev-agent`，生成项目配置 |
| `dev-feedback` | 把这些 skill 或 `dev-agent` 的问题、功能建议整理成 issue，提交到本仓库 |

`dev-issue`、`dev-requirements`、`dev-implement`、`dev-test` 会读取 `dev-workflow` 的共享约定，所以这几个 skill 必须和 `dev-workflow` 装在同一个目录下。

## 安装

### 方式一：npx skills

推荐先只装 `dev-install`，再让它补齐其余的部分：

```bash
npx skills add vttmlin/skills -s dev-install
```

然后在 AI 工具里运行 `/dev-install`。

也可以一次全部装上，或者交互式地挑选要装的 skill：

```bash
npx skills add vttmlin/skills -s '*'
npx skills add vttmlin/skills
```

### 方式二：Claude Code 插件

```bash
claude plugin marketplace add vttmlin/skills
claude plugin install dev-workflow@vttmlin-skills
```

插件会把 7 个 skill 和 `dev-agent` 一起装好，skill 的名称带有 `dev-workflow:` 前缀，比如 `/dev-workflow:dev-install`。装完后运行一次 `/dev-workflow:dev-install`，补齐依赖和项目配置。

## 依赖

`dev-install` 会检查并安装这些依赖：

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) CLI
- `grilling`、`domain-modeling`、`pr`、`setup-matt-pocock-skills`，来自 [mattpocock/skills](https://github.com/mattpocock/skills)
- `test-driven-development`，来自 [obra/superpowers](https://github.com/obra/superpowers)
- `ub-mode`，来自 [unclebob/ub-mode](https://github.com/unclebob/ub-mode)

## 项目配置

每个项目各自的命令和规则写在项目内的 `docs/agents/dev-workflow.md`，由 `dev-install` 生成，包括：

- 测试命令、构建命令（必须带全局锁）
- 只能由主代理修改的文件，以及可以按 union 方式合并的文件
- worktree 的位置、同时运行的 `dev-agent` 数上限
- 这个项目特有的代码审查检查项

## 使用

- 拿到一个新 issue：从 `dev-issue` 开始。
- 中途断了、不确定做到哪一步：运行 `dev-workflow`，它会判断当前阶段并转交给对应的 skill。

## 反馈

遇到问题或者有功能建议，运行 `dev-feedback`，或者直接在本仓库[提交 issue](https://github.com/vttmlin/skills/issues/new)。
