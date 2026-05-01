# 控江隔离 ink demo · UX v2 改进设计

**Date**: 2026-05-02  
**Branch**: `feat/ux-v2`  
**Status**: approved by user, in implementation

---

## 背景

控江隔离 ink demo v1（itch.io 内测版）发布后，作者反馈 4 个 UX 痛点：

1. 调查类选项（ink `+`）选过后不消失，体验冗余
2. 没有专门的「线索」界面，玩家无法集中查阅已发现的觉知 / 生态 / NPC 信息
3. 没有专门的「地图」界面，位置追踪不可视化
4. 标题页只有 Act 0 / Act 1 入口，存档机制只覆盖 Act 0 → Act 1 转场

发布策略：渐进发布（每个 phase 独立可上线）。优先级 #4 → #1 → #2 → #3。

---

## #1 ink 选项一次性化

### 问题
ink 语法里 `*` = 一次性、`+` = 可重选。当前 ink 源码里大量「调查 / 搜寻 / 对话」类选项使用 `+`，玩家选过后选项仍在界面，体验冗余。

### 设计
**ink 源码层修复**：审查所有 4 个 Act 的 `+` 选项，按以下规则改：

| 选项类型 | 处理 |
|---|---|
| 调查 / 搜寻 / 翻找 (`〔侦察〕`、`〔聆听〕`、`〔投掷〕`等检定) | 改为 `*` |
| 对话 / 说服 / 检视 NPC | 改为 `*` |
| 移动 / 位置切换（「走向 4F」「退回 302」） | 保留 `+` |
| Hub 闲聊 / 发呆等待 | 保留 `+` |
| 阅读类（重复读纸条 / 笔记） | 改为 `*` |

### 失败死路 audit
某些 `+ → 检定 → 失败 → 留在原地` 的循环若改 `*`，玩家失败一次就永久卡死。审查规则：

- 失败分支若**纯描述**且不影响进度 → 直接改 `*`，玩家接受失败
- 失败分支若**阻断关键道具**（例：找不到主厨刀打不过 boss）→ 加 fallback：
  - 选项 A：保留 `+` 但加访问计数 limit（最多 2 次）
  - 选项 B：失败分支给安慰物（次级道具）
  - 选项 C：把检定改成自动成功（无 RNG），描述上调整

实施时具体 case-by-case 决定。

### 工时
1-2 小时全审 + 半小时测试。

---

## #2 线索面板（📋 抽屉新 tab）

### 设计
在现有 `<div id="sheet">` 的 `.tabs` 里新增「线索」按钮，对应 `<div class="tab-content" id="tab-clues">` 区域。

3 个 section：

#### A. 觉知链
- 6 节固定 list（一切如常 / 隐约不安 / 闻到甜腥 / 第一次敲门 / 第二次敲门 / 门外有东西）
- 每节左侧一个 status dot：● 已解锁 / ○ 未解锁
- 每节右侧一句短描述（已解锁亮色，未解锁灰色 `——`）
- 数据源：`story.variablesState["觉知"]`（ink LIST），用 `LIST_ALL` 检查每节是否在内

#### B. 生态置信度
- 1-7 横向进度条，已到达档位填充红色（CoC 主色）
- 当前档位下方一句文字描述（例：「5/7：感染者进食的红色肉芽」）
- 未到的档位文字显示 `???`
- 数据源：`story.variablesState["生态置信度"]`（数值 1-7）
- 各档位描述写在 JS 端的 `ECOLOGY_LEVELS` 常量里（不污染 ink）

#### C. NPC 卡
- 仅显示已遇见的 NPC（`已遇NPC` LIST 内的）
- 每张卡：头像占位（emoji） + 名字 + 一行身份 + 状态指示
- 状态指示：信任值条 + 感染征兆（如有）
- NPC 列表（潜在 6 人）：
  - 卢剑桥（学霸） — 锚点 A 候选
  - 姚俊杰（班长） — 锚点 A 候选
  - 黄兴树（富二代） — 锚点 B 候选
  - 张宝兴（卫衣男） — 锚点 B 候选
  - 胡一嘉（已感染） — Act 2 路人感染目击
  - 顾聪（已感染） — Act 3 path 2 天台
- NPC 元数据放 JS 端 `NPC_CARDS` 常量；ink 端用 `已遇NPC` LIST + 单独 `感染NPC_目击` 等 flag 判定

### 工时
半天（HTML / CSS / 渲染函数 / 数据接线）。

---

## #3 地图面板（同抽屉再加 tab）

### 设计
在 `.tabs` 里加「地图」按钮，对应 `<div class="tab-content" id="tab-map">` 区域。

按楼层分组的房间列表，无连线：

```
5F  ⭐ 走廊  · 值班室  · 天台
4F     走廊
3F     302  · 走廊  · 楼梯A  · 楼梯B
2F     走廊  · 宿管室
1F     走廊  · 储藏室  · 采样大厅
B1     母核大厅
```

样式规则：
- 当前位置 ⭐ 前缀 + 高亮边框
- 已访问房间：亮色文字
- 未访问房间：灰色文字
- 楼层标签固定宽（如 `5F`），房间用 `·` 分隔

数据源：
- 当前：`story.variablesState["当前地点"]`（字符串如 `"loc_dorm_302"`）
- 已访问 flag：11 个 `*_已访` 布尔（302 隐含 act 0 起就已访）
- JS 端维护 location_id → 显示名 + 楼层 的映射

### 工时
1 天（含设计 + 数据映射 + 测试）。

---

## #4 开始界面 / 存档 / 章节选择

### 4.1 标题页 3 入口

替换现有 `.acts` 容器为：

```
┌────────────────────────┐
│   控 江 隔 离          │
│   一座楼，七个夜晚      │
│                        │
│   ▶ 开始（新游戏）      │
│   ▶ 继续（最近场景）    │  [无档时灰显]
│   ▶ 章节选择            │
│                        │
│   ⚙ 设置                │
│   🏆 成就 0/30          │
│   English / 中文        │
│   BUILD 2026-05-02-?   │
└────────────────────────┘
```

#### 「开始」逻辑
- 检查现有存档：若有，弹原生 `confirm("发现已有存档，开始新游戏会清空。继续？")` 二次确认
- 确认后：`clearSave()` + `location.href = "?act=0"`

#### 「继续」逻辑
- 检查存档：无 → 按钮 disabled + 灰显
- 有 → 显示元信息（`Act N · YYYY-MM-DD HH:MM · 上次场景`）
- 点击 → 跳到对应 act + 注入 saved state（见 4.3）

#### 「章节选择」按钮
- 点击展开 4 个 Act 列表（modal 或 sub-screen）
- 每个 Act 显示：编号 / 标题 / 时长 / 状态（未解锁 / 已解锁 / 已通关）
- 已解锁可点 → 跳到该 Act 头开始（清掉旧档？或保留？见 4.5）
- 未解锁灰显 + 「需通关 Act N-1 解锁」提示
- `?dev=1` URL 全开（dev 模式下所有 Act 可点）

### 4.2 存档颗粒度

每次场景切换写一次。具体钩子：

- 监听 ink `currentPathString`
- 当 `currentPathString` 跨越 knot 边界时 trigger save
  - 检测方法：每次 `Continue()` 后比对前后 path，path 头部 segment 变化即视为 knot 切换

### 4.3 存档结构

```typescript
interface Save {
  v: 2,                    // schema version (v1 是旧版只 act0→1)
  act: number,             // 0 | 1 | 2 | 3
  knot: string,            // ink path string，如 "a1_寝室302"
  state_json: string,      // story.state.toJson() — 完整 ink 运行时状态
  ts: number,              // Date.now()
  scene_label: string,     // 人类可读的场景名，用于「继续」按钮 metadata
  ach_unlocked: string[],  // 成就 id 数组
  chapter_progress: { 0: 'done'|'none', 1: 'done'|'none', 2: ..., 3: ... }
}
```

`v` 字段允许后续 schema 演进。读档时检测：
- `v === 2`：直接用
- `v === 1` 或缺失：尝试兼容（仅 act/vars 字段）；不能完全恢复时降级为「从 act 头开始 + 注入 vars」

### 4.4 读档流程

```
1. 读 localStorage[SAVE_KEY] → save
2. 加载 act{save.act}.json → storyJson
3. story = new Story(storyJson)
4. story.state.LoadJson(save.state_json)  // 一步到位恢复完整状态
5. 渲染当前 knot 的 currentChoices（无需 Continue）
```

注意：ink 的 `state.LoadJson` 在 inkjs 里也叫 `state.LoadJsonObj`，需要 verify API 名。

### 4.5 章节选择 vs 存档冲突

玩家在 Act 2 中途按「章节选择 → Act 1」会清掉 Act 2 进度吗？

**设计选择**：章节选择 = 从该 Act 起点新开始，**清掉当前存档**，二次 confirm。

理由：
- 玩家在 Act 2 进度中途想跳回 Act 1 = 强烈意愿换路线
- 留双存档槽（一个章选 / 一个续游）会让 UI 复杂，违反 YAGNI
- Act 完成进度（`chapter_progress`）单独存，不被存档清掉影响

### 4.6 解锁逻辑

`chapter_progress` 由 ink 终幕 hook 写入：
- Act N 终幕（`-> END` 或终幕 knot）触发 `setChapterDone(N)`
- 解锁规则：Act N 可玩 ⟺ `chapter_progress[N-1] === 'done'`（Act 0 永远可玩）
- `?dev=1` 下绕过解锁检查

### 工时
1 天（含 modal / state.LoadJson 接线 / chapter_progress / dev mode）。

---

## 实现顺序

| Phase | 任务 | 预估 | 部署 |
|---|---|---|---|
| 1 | #4 标题页 / 存档 / 章节选择 | 1 天 | 独立部署 ✓ |
| 2 | #1 ink audit `+` → `*` | 半天 | 独立部署 ✓ |
| 3 | #2 线索 tab | 半天 | 独立部署 ✓ |
| 4 | #3 地图 tab | 1 天 | 独立部署 ✓ |

每 phase 完成后：编译 → 重打 zip → 上传 itch.io → BUILD 标识递增（A/B/C/D）。

---

## 跨仓库同步

ink 源码上游在 `trpg-bot/worlds/modules/kongjiang-isolation/ink_demo/`，demo 仓库的 `src/` 是镜像。

**Phase 2 完成后**，把改动同步到 trpg-bot 主仓库（单独 PR），保持上游一致。

其他 phase 都是 demo 仓库纯前端改动，无需同步上游。

## EN 版本同步（推迟）

`en/index.html` 是 Act 0 简化 demo（806 行 vs 主版 1500+），没有标题页 / 存档系统 / 多章结构。

Phase 1 的特性（跨幕续游、章节选择、章节解锁）依赖多 Act 架构，对单 Act 的 EN demo 没有意义。

**决定**：Phase 1-4 暂不同步 EN 版。后续如需国际化发布，单开一个「EN 版完整重写」spec。

---

## 测试策略

- Phase 1：手动跑 4 个 Act 流程，验证每个场景边界都写档；杀进程 / 关浏览器后「继续」能恢复
- Phase 2：跑现有 16 个自动化测试（`runtest.cjs`）确保没破坏路径；手动玩 Act 0/1 看是否还有冗余选项
- Phase 3：每 Act 跑一遍，确保线索 tab 数据准确
- Phase 4：访问每个房间，确保地图 tab 即时更新

---

## 兼容性

旧存档（v1，仅 `act=1` 转场用）：

- v2 启动后检测 `v` 字段：缺失 → 当 v1 处理
- v1 → v2 迁移：保留 `act` 字段；vars 数据无法完整恢复（缺 ink runtime 状态）→ 降级为「从 Act 1 头开始 + 注入旧 vars」
- 玩家影响：v1 存档可继续但失去精确场景定位，从 Act 头开始

可接受。

---

## 风险 / 未决问题

1. **inkjs 的 state.LoadJson API 命名**：要 verify 是 `LoadJson` / `LoadJsonObj` 还是别的；如不存在等价 API，需用 fallback 方案（注入 vars + jump to knot）
2. **ink `+` audit 工作量可能超估**：实际写起来如果发现单 act 就 50+ 个 `+`，可能要分两次 commit
3. **localStorage 上限（5MB / domain）**：`state.toJson()` 输出可能很大（每个 Act 的 ink 状态 JSON 可能 50-200KB）；单存档槽不会爆，但要监控
4. **chapter_progress 的写入时机**：ink 终幕 knot 没有显式 hook；只能靠 JS 端检测 `Act3结束` / `最终结局` 等 var 变化触发
