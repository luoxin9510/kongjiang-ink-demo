# 控江隔离 · 序章 Ink Demo

Act 0 序章的可玩 Ink 脚本（中文 identifier）。

## 运行

### Inky GUI（推荐）
1. 下载 [Inky 0.15.1+](https://github.com/inkle/inky/releases)
2. `File → Open` 选择 `kongjiang_act0.ink`
3. 右栏即时播放；左栏编辑

### inklecate CLI
```bash
INKLE=path/to/inklecate

# 编译
"$INKLE" -o out.json kongjiang_act0.ink

# 交互运行
"$INKLE" -p kongjiang_act0.ink

# 喂选项跑主路径（开门结局）
printf "1\n1\n1\n1\n1\n1\n2\n2\n1\n" | "$INKLE" -p kongjiang_act0.ink
```

工具链最低版本：inklecate v1.2.0 / Inky 0.15.1（CJK identifier 自 v1.1.1 起支持）。

## 文件

| 文件 | 内容 |
|---|---|
| `kongjiang_act0.ink` | 主脚本：状态声明 + 场景 knot + cut_in |
| `_helpers.ink` | INCLUDE：状态/检定/伏笔 helper 函数 |
| `test-run-results.md` | inklecate -p 实测产出归档 |

## 状态系统速览

| 系统 | 类型 | 范围 | helper |
|---|---|---|---|
| 队友 fear | VAR int | 0–100 | `调整恐惧` |
| 队友 trust | VAR int | 0–100 | `调整信任` |
| 队友 status | VAR LIST `(平静)` | 平静/紧张/恐惧 | `切换状态` |
| 觉知链 | VAR LIST 多值 | 6 节 fact | `推进觉知` |
| 伏笔档 | VAR LIST | 无→一→二→三 | `推进伏笔` |
| PC 理智 | VAR int | 0–99 | （cut_in 后扣） |

## 切入触发

```
(调查数 >= 3 || 回合数 >= 5) && !切入解锁  →  切入解锁 = true
```

切入后玩家可选「门外似乎有动静……」进入主线 mini_goal「夜半叩门」。

## 引擎接入 tag schema

| Tag | 用途 |
|---|---|
| `# scene:dorm_302` | 场景切换（对齐 `scenes.json`） |
| `# speaker:zhiyong` | 发话者（对齐 `characters.json`） |
| `# state:fear_xin+5` | 状态副作用旁路声明（与 `~` 真改双轨） |
| `# act:0` / `# act:1` | act 切换 |
| `# sfx:knock_3x` / `# bgm:quiet_dorm` / `# image:...` | 媒体 |
| `# debug:roll=72/60 fail` | 检定透明度（玩家不可见） |

所有 tag 在 Inky 裸跑下被忽略，不影响功能。引擎侧自行解析。

## 调试

- 顶部 `~ SEED_RANDOM(2026)` 做确定性回放，发布前移除。
- `# debug:` tag 仅 CLI / 引擎调试栏可见。

## 已知限制

- 序章模式不真扣 SAN（设计如此）。
- `panicking` 失控逻辑未实现（序章模式禁用，按 gm_base.md）。
- 仅 1 个铺垫 mini_goal（泡面之争）+ 主敲门，其他 4 个 mini_goal 暂未实现。
