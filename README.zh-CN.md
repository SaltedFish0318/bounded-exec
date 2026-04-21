# bounded-output Codex Skill

面向 Codex 的全局低输出执行 skill 和辅助脚本。它的目标不是限制工作，而是避免构建、测试、日志、搜索等高输出命令把大量无效文本灌进当前上下文。

完整输出会写入本地日志文件，对话里只返回紧凑摘要和少量候选片段，从而保留排查和验证闭环，同时降低 token 消耗。

## 覆盖场景

- 构建、编译、测试、lint、benchmark、CI 类命令
- 依赖安装或更新命令
- Docker、Kubernetes、systemd、journal 日志
- 大文件和大日志预览
- 大范围搜索和目录扫描
- 长时间运行或带大量进度输出的命令

## 安装

在项目目录中执行：

```sh
./install.sh
```

安装脚本会创建这些软链接：

- `~/.agents/skills/bounded-output -> ./skill`
- `~/.codex/skills/bounded-output -> ./skill`
- `~/.codex/bin/bounded-exec -> ./bin/bounded-exec`
- `~/.codex/bin/bounded-preview -> ./bin/bounded-preview`
- `~/.codex/bin/bounded-output-hook -> ./bin/bounded-output-hook`

这样可以只维护项目目录里的源码，同时保持 Codex 全局入口稳定。

## 基本用法

高输出命令通过 `bounded-exec` 执行：

```sh
~/.codex/bin/bounded-exec --scope "focused test" -- pytest tests/test_api.py -q
~/.codex/bin/bounded-exec --scope "targeted build" -- bash -lc 'make check'
```

大文件、日志和搜索结果通过 `bounded-preview` 查看：

```sh
~/.codex/bin/bounded-preview tail app.log
~/.codex/bin/bounded-preview grep "ERROR|FAILED" app.log
~/.codex/bin/bounded-preview sed 120:180 src/file.c
~/.codex/bin/bounded-preview scan app.log "timeout|denied"
~/.codex/bin/bounded-preview rg "SomeSymbol" src tests
```

注意：

- `sed START:END` 会拒绝超过 `--lines` 的范围，防止误输出大段内容。
- `scan FILE [QUERY...]` 是搜索失败时的兜底方式：完整扫描报告落盘，只在对话里打印受控候选；如果没有命中，会打印小段 head/tail 样本。

完整日志默认写到：

```text
~/.codex/logs/bounded-output/
```

## 可选 Hook

`bin/bounded-output-hook` 是轻量的 Codex `PreToolUse` 兜底。默认会阻止明显高输出风险的裸命令，并提示改用 bounded wrapper。

Codex hooks 需要在 `~/.codex/config.toml` 中启用：

```toml
[features]
codex_hooks = true
```

然后把 `docs/codex-hooks-example.json` 里的 `PreToolUse` 配置合并到 `~/.codex/hooks.json`。如果你已经有 Bash PreToolUse hook，把 `~/.codex/bin/bounded-output-hook` 追加到现有 hook 后面，不要直接覆盖整个文件。

临时完全绕过：

```sh
BOUNDED_OUTPUT_DISABLE_HOOK=1
```

只提示不阻止：

```sh
export BOUNDED_OUTPUT_HOOK_MODE=warn
```

## 设计原则

默认工作流：

1. 先用最小有用范围执行
2. 完整输出落盘
3. 对话里只返回紧凑摘要
4. 根据摘要继续推进
5. 只有必要时才扩大范围

这套机制减少大输出带来的 token 消耗，同时不牺牲常规的编辑、验证、排查连续性。
