# 渐进式选择 + 内容扩充实施 Plan

> ⚠️ **2026-05-02 修订（Y 路线 PC 命名清理）**
>
> 在 Phase 3 实施过程中发现 PC 命名 bug：剧本里把 PC 罗昕（昕）当 NPC 互动（对话_昕 / 安抚昕 等）。用户决定走 Y 路线清理，4 室友 = PC 昕 + 3 NPC（砚波/志勇/张怡）。
>
> **影响 plan 的 task：**
> - Task 3.1（昕 早+中 flavor）→ ❌ **删除**（PC 不能跟自己 flavor）
> - Task 4.4（喘息夜 2 4 套深聊）→ 改 3 套（删除深聊_昕）
> - Task 4.5（boss 阶段 2 支援 4 个）→ 改 3 个（删除支援_昕、陪伴_昕）
> - Phase 1+2 中 [对话_昕]/[找人说话→昕] 已通过 refactor/y-pc-cleanup 分支回滚清理
>
> **未来多 PC 路线的 future-work 提醒：**
> 用户已确认其他 3 室友（砚波/志勇/张怡）也将作为可选 PC。届时 `恐惧_志勇/张怡 / 信任_志勇/张怡 / 状态_志勇/张怡` 在某 PC 视角下也变 PC 自身状态。Phase B（多 PC 重构 brainstorm）需重新设计：要么改成"`关系_<观察者>_<被观察者>`"双 PC 矩阵，要么 dynamic var 由 runtime 解析。本 plan 不实施。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 spec [`2026-05-02-progressive-choice-and-flavor-design.md`](../specs/2026-05-02-progressive-choice-and-flavor-design.md)：对 9 个高密度选项场景做渐进式收敛、新增 NPC flavor pockets（早 + 中 + 晚 9 段，3 NPC × 3 phase）与 2 个桥接喘息夜。

**Architecture:** 4 个独立可合并的 PR：(1) 基础设施 + Act0 三场景重构；(2) Act1+2+3 剩余 6 场景重构；(3) NPC 早/中期 flavor pockets；(4) 喘息夜 1+2 + boss 支援接线。每个 PR 独立编译通过、可玩通关。

**Tech Stack:** ink 1.2.0 (中文 identifier) + inklecate 编译 + inkjs 浏览器 runtime；无构建脚本，手工 `inklecate src/kongjiang_actN.ink -o kongjiang_actN.json`。

---

## File Structure

**修改：**
- `src/_data.ink` — 追加 `act_phase` 变量、`陪伴_<NPC>` 4 个 boolean
- `src/_helpers.ink` — 新增 `推进阶段()` 函数（在 Act 切换处调用）
- `src/kongjiang_act0.ink` — 重构 3 场景（场景_寝室傍晚 / 场景_夜半叩门 / 战斗循环）
- `src/act1_scenes.ink` — 重构 3 场景 + 嵌入 NPC flavor 子话题
- `src/act2_scenes.ink` — 重构 2 场景 + 嵌入 NPC flavor 子话题 + 喘息夜 1 触发
- `src/act3_scenes.ink` — 重构 1 场景 + 喘息夜 2 触发
- `src/act3_boss.ink` — 阶段 2 加 4 个条件支援选项
- `src/kongjiang_act1.ink` / `src/kongjiang_act2.ink` / `src/kongjiang_act3.ink` — 主入口可能需 `推进阶段()` 调用

**新建：**
- `src/喘息夜.ink` — 容纳两个喘息夜剧本，由 `kongjiang_act1.ink` / `kongjiang_act2.ink` 在末尾 INCLUDE 并 divert

**编译输出：** `kongjiang_act{0,1,2,3}.json`（沿用现有结构）

## 通用验证流程（每个 task 步骤共用，下文不再重复完整描述）

**编译验证：**

```bash
cd kongjiang-ink-demo
inklecate src/kongjiang_act0.ink -o kongjiang_act0.json
inklecate src/kongjiang_act1.ink -o kongjiang_act1.json
inklecate src/kongjiang_act2.ink -o kongjiang_act2.json
inklecate src/kongjiang_act3.ink -o kongjiang_act3.json
```

期望：4 个文件全部 `Inklecate ran successfully` 无 error/warning。

**手动 playthrough：** 在浏览器打开 `index.html`（或 `python -m http.server` 后访问），从相关 Act 入口跑通对应剧情，重点验证：
- 顶层 ↔ 二级菜单切换无误
- 返回按钮不消耗 tick / 调查计数（看 HUD）
- 落子（实际动作）后回到顶层而非二级
- 已选过的 `*` 选项消失，状态条件 `{xxx}` 选项按预期显隐

**Commit 规范：** 每 task 一个 commit，message `type(scope): 中文说明`（如 `refactor(act0): 寝室傍晚改渐进式 9→3`）；不 push（在 phase 末尾汇总 push）。

---

## Phase 1 — 基础设施 + Act 0 三场景重构（PR 1，~200 行）

**目标：** 渐进式模式定型，作为后续场景模板。

### Task 1.1: 基础变量与阶段推进

**Files:**
- Modify: `src/_data.ink` (末尾追加)
- Modify: `src/_helpers.ink` (末尾追加)
- Modify: `src/kongjiang_act1.ink` / `src/kongjiang_act2.ink` / `src/kongjiang_act3.ink` (各 Act 入口处调用一次 `推进阶段()`)

- [ ] **Step 1: 在 `_data.ink` 末尾追加变量**

```ink
// === 渐进式 v2 / flavor 系统 ===
VAR act_phase = 0   // 0=Act0, 1=Act1, 2=Act2, 3=喘息夜2及之后
VAR 陪伴_昕 = false
VAR 陪伴_志勇 = false
VAR 陪伴_张怡 = false
VAR 陪伴_砚波 = false
```

- [ ] **Step 2: 在 `_helpers.ink` 末尾追加函数**

```ink
=== function 推进阶段(到) ===
~ act_phase = 到
```

注：函数本质是单行赋值的薄封装。保留函数形式（而非散落各处的 `~ act_phase = N`）便于将来加日志 / 统一 hook。不支持自增形态——所有调用必须显式传 phase 编号。

- [ ] **Step 3: 在 Act 1 / Act 2 主入口调用 `推进阶段()`**

`kongjiang_act1.ink` 入口处加 `~ 推进阶段(1)`，`kongjiang_act2.ink` 入口加 `~ 推进阶段(2)`。

**Act 3 入口不调用** —— `act_phase=3` 由 Task 4.3 喘息夜 2 进入时设置（玩家进 Act 3 必经喘息夜 2，避免重复调用）。

**stitch 化场景的放置位置（重要）：** act 入口 knot 通常是 `=== Act1 ===` 形态。若 Phase 2 已把入口 stitch 化（如 `= 顶层`），`~ 推进阶段(N)` 必须放在第一个 stitch **之前**的 knot-level 行（紧跟 `=== ActN ===` 的下一行），不能放进 stitch 内 —— 否则只在玩家进入该 stitch 时才执行，从其他 stitch 直接 divert 时会漏触发。读各文件前 10 行定位到主 knot 起始处。

- [ ] **Step 4: 编译 4 个 act 验证**（命令见上）

- [ ] **Step 5: Commit**

```bash
git add src/_data.ink src/_helpers.ink src/kongjiang_act1.ink src/kongjiang_act2.ink
git commit -m "feat: 加 act_phase 变量与陪伴标记 (渐进式 v2 基础设施)"
```

### Task 1.2: 重构 `场景_寝室傍晚` (act0:~69-150)

**Files:** Modify `src/kongjiang_act0.ink`

- [ ] **Step 1: 读取当前 `=== 场景_寝室傍晚 ===` knot 完整内容**（~80 行），保留所有 divert 目标 knot 名（`调查_看窗外` / `调查_查门` / `调查_衣柜` / `场景_泡面之争` / `对话_昕` / `对话_志勇` / `对话_张怡` / `场景_夜半叩门` / `发呆等待`）。

- [ ] **Step 2: 替换为新结构**

```ink
=== 场景_寝室傍晚 ===
= 顶层
  // 保留原有进入旁白 / scene tag / tick 调用
  铁皮缝里渗进微光，寝室像个铁罐头。你蹲在床边，捏着拳头想下一步怎么走。

  * [调查寝室] -> 调查菜单
  * [找人说话] -> 对话菜单
  + {切入解锁} 门外似乎有动静…… -> 场景_夜半叩门
  + {not 切入解锁} 发呆，让时间过去 -> 发呆等待

= 调查菜单
  你环顾四周，决定从哪儿入手……
  * 〔侦察 80〕看窗外的列队 -> 调查_看窗外
  * 〔侦察 80〕检查寝室门 -> 调查_查门
  * 〔侦察 80〕翻一下衣柜深处 -> 调查_衣柜
  + [← 还是先做点别的] -> 顶层

= 对话菜单
  你想找谁聊聊……
  * 〔说服 65〕安抚昕 -> 对话_昕
  * 和志勇说话 -> 对话_志勇
  * 和张怡说话 -> 对话_张怡
  * {not 已进过泡面} 和砚波聊聊 -> 场景_泡面之争
  + [← 还是先做点别的] -> 顶层
```

- [ ] **Step 3: 改"动作完成回顶层"指向**

确认 `调查_看窗外` / `调查_查门` / `调查_衣柜` / `对话_昕` / `对话_志勇` / `对话_张怡` 这 6 个 knot 末尾的 `-> 场景_寝室傍晚` 改成 `-> 场景_寝室傍晚.顶层`。`场景_泡面之争` 末尾如果回到 `场景_寝室傍晚` 也改 `.顶层`。

- [ ] **Step 4: 编译 act0**

```bash
inklecate src/kongjiang_act0.ink -o kongjiang_act0.json
```

- [ ] **Step 5: 手动 playthrough**

打开 `index.html` → 序章。验证：
- 进入"调查寝室"看到 3 个侦察选项 + 返回
- 点返回回顶层，HUD 调查数 / 回合数 **不变**
- 实际点"看窗外"消耗 1 tick + 调查 +1，动作完后回顶层（4 选项中"调查寝室"仍可进，但"看窗外"内已消失）
- "和砚波聊聊" 进入泡面剧情，触发后该选项消失

- [ ] **Step 6: Commit**

```bash
git add src/kongjiang_act0.ink
git commit -m "refactor(act0): 寝室傍晚改渐进式 9 选项 → 3 顶层"
```

### Task 1.3: 重构 `场景_夜半叩门` (act0)

✅ **Skipped** — 场景实际是 3+3 顺序结构（ink gather `-` 分隔两段菜单），任意 render 时刻 ≤4 选项，已合规渐进式原则。Brainstorm scan 阶段用 `awk` 数 `*`/`+` 总数 = 6 没意识到 gather 把它们分成两次渲染，是 false positive。原 3+3 结构保留——敲门#1（反应）和敲门#2（决断）是两个不同戏剧拍点，合并会破坏剧情节奏。

**Files:** Modify `src/kongjiang_act0.ink`

- [ ] **Step 1: 读取当前 `=== 场景_夜半叩门 ===` 完整内容**，记录 6 个原 divert 目标。

- [ ] **Step 2: 替换为新结构**

```ink
=== 场景_夜半叩门 ===
= 顶层
  // 保留原氛围旁白
  门外的脚步停了。然后是布料蹭过铁皮的声音。

  * [试探] -> 试探菜单
  * [应对] -> 应对菜单
  * [退守] -> 退守菜单

= 试探菜单
  你想先弄清楚外面是谁……
  * 大声问 "谁" -> 探_问谁
  * 〔聆听 65〕屏住呼吸听 -> 探_听
  + [← 我再想想] -> 顶层

= 应对菜单
  你需要做点什么……
  * 让志勇过去看 -> 应_志勇
  * 开门 -> 应_开门
  + [← 我再想想] -> 顶层

= 退守菜单
  撤退方案……
  * 不开门，往后退 -> 退_后退
  * 试图叫宿管 -> 退_宿管
  + [← 我再想想] -> 顶层
```

注：原 6 个 divert 目标可能名字不同，按当前文件实际名重命名上述 stitch 末端的 `-> 探_问谁` 等占位，与现有 knot 名对齐。

- [ ] **Step 3: 改各动作 knot 末尾回顶层** — 与 Task 1.2 Step 3 同模式。

- [ ] **Step 4: 编译 + playthrough** — 重点试 3 个二级菜单的返回 / 落子流程。

- [ ] **Step 5: Commit**

```bash
git add src/kongjiang_act0.ink
git commit -m "refactor(act0): 夜半叩门改渐进式 6 选项 → 3 顶层"
```

### Task 1.4: 重构 `战斗循环` (act0)

**Files:** Modify `src/kongjiang_act0.ink`

- [ ] **Step 1: 读取当前 `=== 战斗循环 ===`**（5 选项：拔刀挥砍 / 徒手反击 / 扔辣椒面 / 闪避 / 逃跑）。

- [ ] **Step 2: 替换为新结构**

```ink
=== 战斗循环 ===
= 顶层
  // 保留原 round 计数 / 状态显示
  你必须做点什么……

  + [攻击] -> 攻击菜单
  + 〔幸运 75〕侧身贴墙闪开 -> 闪避
  + 〔幸运 75〕往门外冲 -> 逃跑

= 攻击菜单
  挥出去的那一下……
  + {主厨刀_unlocked} 〔格斗 45〕拔出主厨刀挥砍 -> 攻击_刀
  + {not 主厨刀_unlocked} 〔格斗 45〕徒手反击 -> 攻击_拳
  * {not 辣椒面_used && 主厨刀_unlocked} 〔投掷 50〕扔辣椒面 -> 攻击_辣椒
  + [← 我再想想] -> 顶层
```

注：保留原 `*` / `+` 修饰符语义。"扔辣椒面"用 `*`（一次性），其他用 `+`（可重复直到状态变化）。

- [ ] **Step 3: 改动作 knot 末尾** — 攻击/闪避/逃跑 各自完成后视具体 knot 现有逻辑。攻击类回到 `战斗循环.顶层`；闪避/逃跑按原跳转。

- [ ] **Step 4: 编译 + playthrough** — 触发 act0 战斗，确认多回合可以反复进入"攻击菜单"。

- [ ] **Step 5: Commit**

```bash
git add src/kongjiang_act0.ink
git commit -m "refactor(act0): 战斗循环改渐进式 5 选项 → 3 顶层"
```

### Phase 1 收尾

- [ ] **Step 1: Push 到新分支**

```bash
git checkout -b feat/progressive-v2-phase1
git push -u origin feat/progressive-v2-phase1
```

- [ ] **Step 2: 开 PR**

```bash
gh pr create --base main --head feat/progressive-v2-phase1 --title "feat(progressive-v2): Phase 1 — 基础设施 + Act 0 三场景重构" --body "落地 spec docs/superpowers/specs/2026-05-02-progressive-choice-and-flavor-design.md Phase 1。"
```

- [ ] **Step 3: 等用户 review，merge 后回 main pull**

---

## Phase 2 — Act1+2+3 6 场景重构（PR 2，~300 行）

**目标：** 9 个 ≥5 选项场景全部完成。

每个 task 模式同 Task 1.2-1.4：**读 → 替换为顶层+二级 stitch 结构 → 改动作 knot 末尾 → 编译 → playthrough → commit**。

### Task 2.1: 重构 `a1_寝室302` (act1, 5 选项)

**Files:** Modify `src/act1_scenes.ink`

- [ ] **Step 1: 读取 `=== a1_寝室302 ===` 完整内容**，记录所有选项目的 knot。
- [ ] **Step 2: 套用模板**

```ink
=== a1_寝室302 ===
= 顶层
  // 保留原 scene tag 与 tick
  // [场景描述]

  * [清点状况] -> 清点菜单
  * [找人说话] -> 对话菜单
  + [推进选项-视当前进度] -> ...

= 清点菜单
  你想清楚自己手上有什么……
  * [选项1] -> ...
  * [选项2] -> ...
  + [← 还是先做点别的] -> 顶层

= 对话菜单
  你想找谁聊聊……
  // 4 NPC 对话入口（昕 / 志勇 / 张怡 / 砚波，按当前场景实际可见的填）
  + [← 还是先做点别的] -> 顶层
```

具体分组按当前 5 个选项的语义归纳——大体上 1-2 调查类 + 2-3 对话类 + 1 推进。

- [ ] **Step 3: 改动作 knot 末尾 → `a1_寝室302.顶层`**
- [ ] **Step 4: 编译 act1 + playthrough**
- [ ] **Step 5: Commit `refactor(act1): 寝室302 改渐进式 5 → 3 顶层`**

### Task 2.2: 重构 `a1_走廊3F` (act1, 5 选项)

**Files:** Modify `src/act1_scenes.ink`

模板同 Task 2.1。**建议顶层：** `[观察走廊]` / `[行动]` / `[回退]`。

- [ ] **Step 1-5: 同 Task 2.1 模式，commit `refactor(act1): 走廊3F 改渐进式 5 → 3 顶层`**

### Task 2.3: 重构 `a1_锚点A遭遇` (act1, 5 选项)

✅ **Skipped (auto, scan false positive)** — 5 个 `*`/`+` 选项分布在卢剑桥/姚俊杰二选一互斥分支的不同 stitch（由 `锚点A_id` runtime 决定）。任意 render 时刻最多 3 选项，且内部语义已清晰（追问 / 技能 check / 拒绝）。沿用 Task 1.3 跳过原则（user-set policy: render ≤4 + 内部语义清晰自动跳过）。

**Files:** Modify `src/act1_scenes.ink`

锚点遭遇是 NPC 互动场。**建议顶层：** `[对话]` / `[行动]` / `[应急 / 离开]`。"对话"二级承载技能 check（说服/聆听/威吓等）。

- [ ] **Step 1-5: 同上模式，commit `refactor(act1): 锚点A遭遇 改渐进式 5 → 3 顶层`**

### Task 2.4: 重构 `a2_走廊2F` (act2, 5 选项)

**Files:** Modify `src/act2_scenes.ink`

**建议顶层：** `[观察]` / `[接近某门/物]` / `[推进]`。注意 2F 有张宝兴（锚点 B），可能含锚点遭遇前置。

- [ ] **Step 1-5: 同上模式，commit `refactor(act2): 走廊2F 改渐进式 5 → 3 顶层`**

### Task 2.5: 重构 `a2_锚点B_huang` (act2, 5 选项)

✅ **Skipped (auto, scan false positive)** — 5 个 `+` 选项分布在 2 段 gather-separated menu（首问 3 + 后续 2，line 289-308 / 318-329）。任意 render 时刻最多 3 选项，内部语义已清晰（外面情况 / 〔说服〕；为何躲 / 〔侦察〕看袖子）。沿用 user-set policy。

**Files:** Modify `src/act2_scenes.ink`

黄兴树（富二代学生）说服场。**建议顶层：** `[对话]` / `[施压]` / `[离开]`。"施压"二级承载多个说服角度（〔说服〕/〔威吓〕/〔心理〕/物品威慑等，按当前实际选项归类）。

- [ ] **Step 1-5: 同上模式，commit `refactor(act2): 锚点B 黄兴树改渐进式 5 → 3 顶层`**

### Task 2.6: 重构 `a3_共识抉择` (act3, 5 选项) — 特殊处理

✅ **Skipped (auto)** — 经 Step 0 全文调查后判断：
- 5 个选项是 5 个互斥 ending 入口（战斗/牺牲/同化/撤退/秘密结局），不是同类调查动作
- 多数路径 render ≤ 3-4（牺牲/同化/秘密结局都有强条件 gating），5 同时显示是极少数玩家路径
- 现版本**无"听 NPC 立场"实现可对接**（narrative 形式描述 NPC 反应：line 530-533 张怡呼吸/志勇手抖/砚波出汗/昕沉默，非交互菜单）
- 终幕决策板形态本身就是 5 endings 选项板的预期 UX，强加 [听谁先说] 二级会损失"看到所有可能出路"的戏剧紧迫感
- 引入 listening 二级需写 ~120 行 NPC 立场创作内容，超出 Phase 2 重构 PR 范围

沿用 user-set policy: render-compliant 多数路径 + 内部语义清晰 + 影响主线节奏的边界 → 跳过。

**Files:** Modify `src/act3_scenes.ink`

⚠️ **优先做读取调查：**

- [ ] **Step 0: 读 `=== a3_共识抉择 ===` 全文**。判断当前 5 选项是 (a) 直接拍板 3 路径 + 2 听立场 / (b) 5 个并排听立场+决定 / (c) 其他形态。**如果当前已有"听 NPC 立场"逻辑**，本 task 改为"轻度收敛"（顶层 4 个：听志勇 / 听张怡 / 听砚波 / 拍板，且"听"是 `+`-sticky 可重复）；**如果当前是直接 5 选项**，按下面套用渐进式。

- [ ] **Step 1: 替换为新结构（默认场景 c）**

```ink
=== a3_共识抉择 ===
= 顶层
  // 保留原氛围旁白
  你必须做最后的决定。

  + [听谁先说] -> 听菜单
  * [自己拍板] -> 拍板菜单

= 听菜单
  你想先听谁的想法？
  * 听志勇说 -> 立场_志勇 -> 顶层
  * 听张怡说 -> 立场_张怡 -> 顶层
  * 听砚波说 -> 立场_砚波 -> 顶层
  + [← 我自己想] -> 顶层

= 拍板菜单
  你拍板……
  * 走一楼出口 -> a3_path1_突围
  * 走天台 -> a3_path2_天台
  * 走地下 -> a3_path3_地下
```

注：`立场_志勇` 等 stitch（或 knot）若不存在，需要写 — 读现有"听立场"内容（如有），抽取并放入。如果完全没有"听立场"逻辑则当前 5 个选项很可能就是 3 路径+2 其他，那只需要加分组顶层而不是新写立场内容。

- [ ] **Step 2-5: 编译 act3 + playthrough Act3 终幕共识场 + commit `refactor(act3): 共识抉择改渐进式 5 → 2 顶层`**

### Phase 2 收尾

- [ ] **Step 1: 新分支 push + 开 PR `feat(progressive-v2): Phase 2 — Act1+2+3 6 场景重构`**
- [ ] **Step 2: review + merge + main pull**

---

## Phase 3 — NPC 早 + 中期 Flavor Pockets（PR 3，~300 行）

**目标：** 4 个 NPC 在日间对话 knot 内嵌入早 + 中期 flavor 子话题（共 8 段，每段 ~30-50 字）。

**通用模式：** 每个 NPC 的 `对话_<NPC>` knot 改为顶层 + 子话题菜单。**进入 `对话_<NPC>` 仍消耗 1 tick**（保持现状），子话题菜单中的话题点击免费。

```ink
=== 对话_昕 ===
~ tick回合()  // 现有 tick，进入对话本身付的代价
= 顶层
  // 保留原对白主线（必读，不分子话题）
  // 然后给子话题菜单

= 子话题
  你还想多问什么？
  * {act_phase >= 1} 高三压力 · 错题 -> flavor_昕_早
  * {act_phase >= 2} 厨师梦 · 和家里僵 -> flavor_昕_中
  + [← 该走了] ->->   // tunnel 返回到调用 `对话_<NPC>` 的场景

= flavor_昕_早
  // 30-50 字内容（无 tick）
  -> 子话题

= flavor_昕_中
  // 30-50 字内容（无 tick）
  -> 子话题
```

**关键 ink 细节：**
- 子话题用 `*` 一次性消失（"看过即消失"决策）
- 子话题菜单返回用 `->->` （tunnel 返回）。**前置约束**：`对话_<NPC>` 必须由调用方用 tunnel 语法 `-> 对话_昕 ->`（末尾两个 dash）调用，而不是普通 divert `-> 对话_昕`。**Task 3.x Step 3 实施时必须先 grep 当前 `对话菜单` 中对 NPC knot 的调用方式**：若是普通 divert，要么改为 tunnel 形式，要么 `+ [← 该走了]` 改为 `-> 上层场景.顶层` 显式回跳（不能用 `->->`，会编译报 "No tunnel to return from"）
- `{act_phase >= 1}` / `{act_phase >= 2}` 控制显隐

### Task 3.1: 嵌入 `对话_昕` 子话题

❌ **DELETED (Y 路线)** — 昕 是 PC（罗昕），不是 NPC。PC 不能跟自己 flavor 对话。本 task 整体废弃。
PC 内心戏（高三压力 / 厨师梦）由现有 SAN 系统（`理智_昕` 消耗 + `# state:san_xin` tag）和场景叙述自然承担。
原 `=== 对话_昕 ===` / `=== a1_对话_昕 ===` 已在 refactor/y-pc-cleanup branch 删除。Phase 3 实际只覆盖 3 NPC（Task 3.2/3.3/3.4）。

**Files:** Modify `src/act1_scenes.ink`（或 `_helpers.ink` / 其他承载该 knot 的文件 — 先 grep 定位）

- [ ] **Step 1: `Grep "=== 对话_昕"` 定位文件与行号**
- [ ] **Step 2: 读现有 `对话_昕` 完整内容**
- [ ] **Step 3: 重构成 顶层 + 子话题 stitch 模式（见上述模板）**
- [ ] **Step 4: 写两段 flavor 内容（参考 spec §5 主题表）：**

  - **早期 flavor — 高三压力 / 错题反复**（~40 字）
    主题：他翻数学错题本，自言自语"这道我做过三遍了还错"，笔尖压在纸上不动。短场景，不推进剧情。
  - **中期 flavor — 厨师梦 / 和家里僵持**（~50 字）
    主题：他从枕头下摸出一本菜谱本（手抄的），说他想读烹饪学校，跟家里吵过一次再没提，看到 PC 主厨刀时反应不一样。
  - **主厨刀 payoff（伏笔回收，spec §5 承诺）**：若 PC 已持有主厨刀（条件 `{主厨刀_unlocked}`），在 `flavor_昕_中` 末尾加 1-2 行——昕瞟了一眼 PC 腰间那把刀，又移开视线。这是 spec §5 主题表"看到主厨刀时反应不一样"的承诺回收。

- [ ] **Step 5: 编译 + playthrough**（Act1 起进入对话_昕、Act2 起再进一次确认中期话题出现，验证主厨刀条件下昕的目光戏出现）
- [ ] **Step 6: Commit `feat(flavor): 昕 早+中期 flavor pockets`**

### Task 3.2: 嵌入 `对话_志勇` 子话题

**Files:** Modify 承载 `对话_志勇` 的文件

- [ ] **Step 1-3: 同 Task 3.1**
- [ ] **Step 4: 写两段 flavor：**

  - **早期 — 想吃的东西**（~40 字）
    他认真讨论汉堡 vs 烤冷面，谁更适合"逃出去第一顿"，说着说着安静下来。
  - **中期 — 暗恋 / 篮球梦**（~50 字）
    他给 PC 看手机锁屏（隔壁班女生合照碎片），半承认半否认，转头说他其实想打 CBA 但被家里压着读高三。

- [ ] **Step 5-6: 编译 + playthrough + commit `feat(flavor): 志勇 早+中期 flavor pockets`**

### Task 3.3: 嵌入 `对话_张怡` 子话题

- [ ] **Step 1-3: 同上**
- [ ] **Step 4: 写两段 flavor：**

  - **早期 — 小时候的事**（~40 字）
    他说一段他奶奶院子的小动物（一只总来偷食的麻雀），语气罕见温和。
  - **中期 — 对未来的冷感**（~50 字）
    他承认他从来没真的想过 18 岁以后；不是叛逆，是"想了也想不出"。

- [ ] **Step 5-6: 编译 + playthrough + commit `feat(flavor): 张怡 早+中期 flavor pockets`**

### Task 3.4: 嵌入 `对话_砚波` 子话题（特殊：含 PC 旧友视角）

**Files:** Modify 承载 `对话_砚波` 的文件 — 注意：现有可能是 `场景_泡面之争` 承担砚波互动，需读全文判断 flavor 嵌入位置。

- [ ] **Step 1: Grep 砚波相关 knot**（如 `对话_砚波`、`场景_泡面之争` 等），可能不止一个。
- [ ] **Step 2: 读相关 knot**

- [ ] **Step 3: 决定 flavor 嵌入点（按 grep 结果分两种情况）：**

  **情况 A：已存在专属 `对话_砚波` knot**（少见）
  - 直接按 Task 3.1 模板嵌入子话题菜单
  - 入口已在 `对话菜单` 中接好，跳到 Step 4

  **情况 B：不存在专属 knot，砚波互动分散在 `场景_泡面之争` 等场景**（更可能）
  - 新建 `=== 对话_砚波 ===` knot，结构同 Task 3.1 模板（顶层 + 子话题）
  - knot 顶部加 `~ tick回合()` 付 1 tick（与其他 NPC 对话一致）
  - 在 Task 1.2 重构后的 `场景_寝室傍晚.对话菜单` 末尾追加：
    ```ink
    * {act_phase >= 1 && 已进过泡面} 找砚波聊聊 -> 对话_砚波
    ```
    （`已进过泡面` 保证泡面之争先发生，砚波互动有铺垫；`act_phase >= 1` 保证 Act 1 起才出现）
  - 同步在 Phase 2 重构后的各 Act 1 / Act 2 寝室场景 `对话菜单` 中也加上同条目（`a1_寝室302.对话菜单`、相关 act2 场景）。**注意**：因 Phase 2 早于 Phase 3 执行，Phase 2 重构这些场景时本身可能没有"对话_砚波" 概念；最简方案是**在执行 Task 3.4 时回头补 Phase 2 已重构的对话菜单**

- [ ] **Step 4: 写两段 flavor：**

  - **早期 — 你和他的旧事**（~40 字）
    他不经意提起你们高一一起翻栏杆抓过的那只猫；让 PC 一愣。
  - **中期 — 共同回忆里没说出口的话**（~50 字）
    他说那次他帮 PC 瞒了什么事（具体可省，留白），从没提过；语气是闲聊但眼神不一样。

- [ ] **Step 5-6: 编译 + playthrough + commit `feat(flavor): 砚波 早+中期 flavor pockets`**

### Phase 3 收尾

- [ ] **Step 1: 新分支 push + 开 PR `feat(progressive-v2): Phase 3 — NPC 早+中期 flavor pockets`**
- [ ] **Step 2: review + merge + main pull**

---

## Phase 4 — 喘息夜 1+2 + boss 支援接线（PR 4，~450 行）

**目标：** 完整新内容交付。

### Task 4.1: 创建 `src/喘息夜.ink` 骨架 + Act1→Act2 接入

**Files:**
- Create: `src/喘息夜.ink`
- Modify: `src/kongjiang_act1.ink`（末尾 INCLUDE 喘息夜.ink + 终幕 divert 喘息夜1）
- Modify: `src/kongjiang_act2.ink`（开头从喘息夜1 进入 Act2 主线）

- [ ] **Step 1: 创建 `src/喘息夜.ink`**

```ink
// 喘息夜.ink — 桥接场景：Act1↔Act2 / Act2↔Act3
// 全程免费（不消耗 tick）

=== 喘息夜1 ===
// Act1 → Act2 之间，线性短章
// 详 §3.大纲，~100 行
TODO  // 在 Task 4.2 填充

=== 喘息夜2 ===
// Act2 → Act3 之间，4 套深聊 + 共享外壳
// 详 §4，~300 行
TODO  // 在 Task 4.3-4.4 填充
```

- [ ] **Step 2: `kongjiang_act1.ink` 末尾 `INCLUDE 喘息夜.ink`，Act1 终幕 knot 末尾改 divert 喘息夜1**
- [ ] **Step 3: `kongjiang_act2.ink` 入口处删去原 Act1→Act2 直接 divert（如有），改由喘息夜1 末尾 divert 进入 Act2 主 knot**
- [ ] **Step 4: 编译 act1 + act2**（此时是占位，会在 Task 4.2 补内容；可临时让喘息夜1 直接 `-> Act2 主 knot` 以通过编译）
- [ ] **Step 5: Commit `feat(喘息夜): 创建喘息夜.ink 骨架 + Act1↔Act2 接入`**

### Task 4.2: 写喘息夜 1 内容（~100 行）

**Files:** Modify `src/喘息夜.ink`

- [ ] **Step 1: 替换 `=== 喘息夜1 ===` 占位为完整剧本**

按 spec §3 大纲（7 段）：
1. 场记开头：深夜 2 点，铁皮缝里漏进路灯
2. 昕开口（高三压力主题，1-2 屏）
3. 志勇插一句（想吃的东西主题，1-2 屏）
4. 沉默 + 玩家选择（"你先开口" / "等他们先"，无后果）
5. 张怡的一句（"如果出不去，可能也行"，对未来冷感主题）
6. 砚波收尾（你和他的旧事主题，~2 屏，他熄灯）
7. divert 到 Act2 主 knot

格式骨架：

```ink
=== 喘息夜1 ===
// [场记开头：~50 字环境]

// === 昕（高三压力）===
// [对白 + 旁白，~80 字]

// === 志勇（想吃的东西）===
// [~80 字]

// === 沉默 / 玩家选择 ===
* "你先开口" -> _沉默后续A
* "等他们先" -> _沉默后续B

= _沉默后续A
  // [~40 字]
  -> _张怡段

= _沉默后续B
  // [~40 字]
  -> _张怡段

= _张怡段
  // [对白：如果出不去，可能也行 + 反应，~80 字]
  -> _砚波段

= _砚波段
  // [对白 + 熄灯，~100 字]
  -> Act2_主入口   // 实际 knot 名见 act2 主入口
```

- [ ] **Step 2: 编译 + playthrough（跑通 Act1 终→喘息夜1→Act2 启）**
- [ ] **Step 3: Commit `feat(喘息夜1): 4 NPC 心里话集体氛围片段`**

### Task 4.3: 写喘息夜 2 共享外壳（~60 行）+ Act2→Act3 接入

**Files:**
- Modify `src/喘息夜.ink`
- Modify `src/kongjiang_act2.ink`（终幕 divert 喘息夜2）
- Modify `src/kongjiang_act3.ink`（开头从喘息夜2 进入）

- [ ] **Step 1: 写 `=== 喘息夜2 ===` 外壳**

```ink
=== 喘息夜2 ===
~ 推进阶段(3)  // 解锁晚期 flavor

// [入夜氛围铺垫 ~80 字：明天就要冲了。今晚是最后一夜。]
-> 选谁

= 选谁
  你想多陪谁一会儿？
  * 多陪昕一会儿 -> 深聊_昕
  * 多陪志勇一会儿 -> 深聊_志勇
  * 多陪张怡一会儿 -> 深聊_张怡
  * 多陪砚波一会儿 -> 深聊_砚波

= 第二轮选谁
  夜更深了。还有时间，再陪一个人？
  + {not 陪伴_昕} 多陪昕 -> 深聊_昕
  + {not 陪伴_志勇} 多陪志勇 -> 深聊_志勇
  + {not 陪伴_张怡} 多陪张怡 -> 深聊_张怡
  + {not 陪伴_砚波} 多陪砚波 -> 深聊_砚波
  + 不陪了，闭眼睡 -> 天亮

= 天亮
  // [过场旁白 ~40 字，divert 到 Act3 主入口]
  -> Act3_主入口

= 深聊_昕
  TODO -> Task 4.4

= 深聊_志勇
  TODO -> Task 4.4

= 深聊_张怡
  TODO -> Task 4.4

= 深聊_砚波
  TODO -> Task 4.4
```

- [ ] **Step 2: `kongjiang_act2.ink` 终幕改 divert 喘息夜2**
- [ ] **Step 3: `kongjiang_act3.ink` 入口删除原直入逻辑（如有），改由喘息夜2.天亮 divert 进入**
- [ ] **Step 4: 临时让 4 个 `深聊_<NPC>` 各 divert `-> 第二轮选谁` 以通过编译**
- [ ] **Step 5: 编译 + playthrough（Act2 终 → 喘息夜2 选谁 → 直接到天亮 → Act3 启）**
- [ ] **Step 6: Commit `feat(喘息夜2): 外壳 + Act2↔Act3 接入 (深聊待补)`**

### Task 4.4: 写喘息夜 2 四套深聊（~280 行 = 4 × 60-70 行）

**Files:** Modify `src/喘息夜.ink`

⚠️ 写作量较大，建议拆成两次 commit（4.4a 写昕+志勇，4.4b 写张怡+砚波），但 task 概念上仍归为一组。

每段深聊结构：

```ink
= 深聊_昕
  ~ 陪伴_昕 = true
  // [~60-70 行内容，触达"最害怕的事 · 独自一个人"主题]
  // 触达点：高一被锁宿舍的回忆、至今怕黑、想被人记得而不只是被陪
  -> 第二轮选谁
```

❌ **Step 1 (深聊_昕) DELETED (Y 路线)** — 昕 是 PC，不深聊自己。喘息夜 2 改为 3 套深聊（志勇/张怡/砚波）。

⚠️ **黑名单约束（spec §5）适用于剩余 3 段深聊：**
- ❌ 禁止主题"童年阴影" —— 勿溯及童年（小学以前）
- ❌ 禁止载体"家信 / 写信" —— 家庭主题用电话片段记忆、看到合照、做梦、放假回家场景等替代

- [ ] **Step 1: 写 `深聊_志勇`（~70 行）**

主题：和家人的关系。
载体：电话片段记忆 / 看到他爸送他来学校时的场景（**不写信**）。
情绪频道：硬气表面、深处的委屈、用打篮球替代沟通。

- [ ] **Step 3: Commit `feat(喘息夜2): 深聊昕 + 深聊志勇`**

- [ ] **Step 4: 写 `深聊_张怡`（~70 行）**

主题：对死亡的看法。
情绪频道：平静、哲学化、反而怕"身边人的死"。

- [ ] **Step 5: 写 `深聊_砚波`（~70 行）**

主题：他对你最想说的话。
结构：玩家可选 1 句听（"对不起" / "谢谢" / "其实那时候……"），各对应一段简短回忆。
情绪频道：旧友的低声、克制的真诚。

```ink
= 深聊_砚波
  ~ 陪伴_砚波 = true
  // [~30 字铺垫]

  * 听他说"对不起" -> 砚波_对不起
  * 听他说"谢谢" -> 砚波_谢谢
  * 听他说"其实那时候……" -> 砚波_其实

= 砚波_对不起
  // [~30 行回忆]
  -> 第二轮选谁

= 砚波_谢谢
  // [~30 行回忆]
  -> 第二轮选谁

= 砚波_其实
  // [~30 行回忆]
  -> 第二轮选谁
```

- [ ] **Step 6: 编译 + playthrough — 跑通喘息夜2 完整路径，验证陪伴标记 set**
- [ ] **Step 7: Commit `feat(喘息夜2): 深聊张怡 + 深聊砚波`**

### Task 4.5: boss 阶段 2 支援选项接线

**Files:** Modify `src/act3_boss.ink`

⚠️ **风险：** boss 阶段 2 现有 4 选项扁平，加 4 条件支援可能超过上限。**预先排查并选取最小入侵方案。**

- [ ] **Step 1: 读 `=== a3_boss_阶段2 ===` 全文**，确认现有 4 选项内容。

- [ ] **Step 1.5: 判定常驻基础选项数量（决定走方案 A 还是 B）**

  逐一检查现有 4 选项，按"必须保留" / "可拿掉/合并"分类。判定标准：
  - 战斗机制必需（如：攻击、防御、关键道具）→ 常驻
  - 失去后会破坏战斗张力或可玩性 → 常驻
  - 与陪伴支援功能重叠（如：呼叫盟友等） → 可被支援选项替代

  统计常驻基础数：
  - **常驻 ≤ 2 个** → 走方案 A（Step 2 + Step 3）
  - **常驻 ≥ 3 个** → **强制走方案 B**（Step 3-alt），不能走 A，否则会牺牲战斗设计

- [ ] **Step 2: 走方案 A（仅当常驻 ≤ 2 时）**

  保留现有常驻 ≤ 2 + 4 个条件支援（`{陪伴_X}` 修饰）。同时显隐让总可见数 ≤4：玩家如果只陪了 1 人，看到 2 基础 + 1 支援 = 3 选项；陪 2 人则 2 基础 + 2 支援 = 4 选项。

  ⚠️ **未来扩展约束**：方案 A 留的余地很小（陪 2 人时已满 4）。如未来想新增第 3 基础选项，需重评——可能要把基础选项二级抽屉化。

- [ ] **Step 3: 套用方案 A 实现**

```ink
=== a3_boss_阶段2 ===
// 保留原氛围 / 状态显示
// 基础选项 2 个（保留现有最核心 2 个）
+ [基础选项 1] -> ...
+ [基础选项 2] -> ...
// 4 个条件支援
+ {陪伴_志勇} 志勇主动挡刀 -> 支援_志勇
+ {陪伴_张怡} 张怡冷静递来 X -> 支援_张怡
+ {陪伴_砚波} 砚波从背后撞过来 -> 支援_砚波
```

- [ ] **Step 3-alt: 套用方案 B 实现（仅当 Step 1.5 选了方案 B）**

在 boss 阶段 2 主菜单底部加"盟友支援"入口（不挤压现有 4 基础选项）：

```ink
=== a3_boss_阶段2 ===
// 保留原 4 选项扁平（不动）
+ [基础选项 1] -> ...
+ [基础选项 2] -> ...
+ [基础选项 3] -> ...
+ [基础选项 4] -> ...
+ {陪伴_昕 || 陪伴_志勇 || 陪伴_张怡 || 陪伴_砚波} [盟友支援] -> 支援菜单

= 支援菜单
  谁在身边？
  + {陪伴_志勇} 让志勇上 -> 支援_志勇
  + {陪伴_张怡} 让张怡递东西 -> 支援_张怡
  + {陪伴_砚波} 让砚波撞上去 -> 支援_砚波
  + [← 自己来] -> a3_boss_阶段2
```

- [ ] **Step 4: 写 4 个支援 knot（每个 ~20 行，含小骰判定 + 后续 divert）**

```ink
=== 支援_昕 ===
// 描述昕的支援动作（约 20 行）
// 给玩家小奖励（如减少阶段3难度 / 解锁额外结局对白）
-> a3_boss_阶段3   // 或当前 boss 阶段推进逻辑
```

- [ ] **Step 5: 编译 + playthrough**

按 Step 1.5 选定的方案对照测试：

**方案 A：**
- 喘息夜2 不陪任何人 → boss 阶段 2 看到 2 基础选项（验证向后兼容）
- 喘息夜2 陪昕 + 志勇 → boss 阶段 2 看到 2 基础 + 2 条件支援（验证标记生效）

**方案 B：**
- 喘息夜2 不陪任何人 → boss 阶段 2 看到原 4 基础选项（无"盟友支援"入口）
- 喘息夜2 陪昕 + 志勇 → boss 阶段 2 看到 4 基础 + "盟友支援" 入口；进入支援菜单看到 2 个具体支援条目

- [ ] **Step 6: Commit `feat(boss): 阶段 2 加 4 条件支援选项 (陪伴_X 触发)`**

### Phase 4 收尾

- [ ] **Step 1: 新分支 push + 开 PR `feat(progressive-v2): Phase 4 — 喘息夜 1+2 + boss 支援`**
- [ ] **Step 2: review + merge + main pull**

---

## Self-Review

### Spec coverage check

| Spec 章节 | 落实 task |
|---|---|
| §0 6 决策 | 全 plan 贯穿 |
| §1.1 ink 写法 | Task 1.2-1.4, 2.1-2.6 |
| §1.2 时间成本规则 | Task 1.2 Step 3, 3.1 模板 |
| §1.3 选项数限制 | 顶层 / 二级 各 task 验证步骤 |
| §1.4 文案规范 | Task 1.2 范例文案 |
| §2.1-2.9 9 场景重构清单 | Task 1.2-1.4, 2.1-2.6 |
| §3 喘息夜 1 大纲 | Task 4.2 |
| §4 喘息夜 2 结构 | Task 4.3-4.4 |
| §5 NPC flavor 主题表 | Task 3.1-3.4（早中）+ 4.4（晚） |
| §5 phase 门槛 | Task 1.1 (Act1/Act2 入口) + 4.3 (喘息夜2 进入时推进至 3) |
| §6 4 PR 顺序 | Phase 1-4 |
| §7.1 boss 支援超额风险 | Task 4.5 Step 2 评估方案 |
| §7.1 a3_共识抉择 | Task 2.6 Step 0 调查 |

无遗漏。

### Placeholder scan

- 仅一处刻意留白：Task 4.1 的 `TODO  // 在 Task 4.2 填充`，是阶段性占位，下一 task 必填，可接受。
- 无 "TBD" / "implement later" / "如适用" / "适当处理" 等模糊词。

### Type / 命名一致性

- `act_phase`, `陪伴_昕/志勇/张怡/砚波`, `推进阶段()` 全 plan 命名一致。
- `场景_寝室傍晚.顶层` 等 stitch 引用全 plan 一致用 `.顶层` / `.菜单_xxx` 格式。

---

## 不在本次范围

- 不引入"陪伴度数值"系统（spec §7.3 明确否决）
- 不写第三周目专属内容
- 不动 demo 整体结局分支结构
- 不修改 `index.html` / inkjs 调用层（纯 ink 内容工作）
