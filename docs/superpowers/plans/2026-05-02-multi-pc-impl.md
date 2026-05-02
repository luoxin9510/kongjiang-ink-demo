# 多 PC 切换实施 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 spec [`2026-05-02-multi-pc-design.md`](../specs/2026-05-02-multi-pc-design.md)：4 室友（昕/砚波/志勇/张怡）全部可玩，每 PC 视角下 demo 体验有差异化高光时刻。

**Architecture:** 8 个 PR。Phase 1 (PR 1) 基础设施 + ink var 架构 + mass rename，Phase 2 (PR 2-7) 全部 ink-only 内容增量，**测试 Gate**（5 endings × 4 PC CLI playthrough），Phase 3 (PR 8) HTML 实现（标题页 PC 选择 + HUD 切换）。每 PR 独立编译通过、可玩通关。

**Tech Stack:** ink 1.2.0（中文 identifier）+ inklecate 编译 + inkjs 浏览器 runtime；JS 层 ~110 行增量集中在 PR 8。

**前置条件：** Y 路线 PC 命名清理已完成（PR #7 merged，main HEAD `ae2ffe0`）。

---

## File Structure

**修改：**
- `src/_data.ink` — 加 PC LIST + 通用 PC stats + 4 角色关系 var + 当前PC 字符串 var（详 §spec 2.1）
- `src/_helpers.ink` — 加 `初始化PC(pc)` 函数（§spec 2.2）
- `src/kongjiang_act0.ink` — 局部 VAR 同步、mass rename、序章入口加 init、§4.1 昕 signature、§5.2 昕 minor 1、§10 boss PC-条件
- `src/kongjiang_act1.ink` — 入口加临时 init、mass rename、§5 minor
- `src/kongjiang_act2.ink` — 入口加临时 init、mass rename、§5 minor、§11 锚点 PC-aware
- `src/kongjiang_act3.ink` — 入口加临时 init、mass rename
- `src/act1_scenes.ink` — §4 砚波 signature（夜半叩门）、§5 minor、§6 PC-条件菜单
- `src/act2_scenes.ink` — §4.4 张怡 signature（走廊几何）、§6 PC-条件菜单、§11 锚点 PC-aware
- `src/act3_scenes.ink` — §4 minor、mass rename、§12 endings PC-aware 部分
- `src/act3_boss.ink` — §4.3 志勇 signature（阶段 3 警察世家闪回）、§10 boss PC-aware 攻击 menu、mass rename
- `src/kongjiang_endings.ink` — §12 endings PC 视角调整
- `src/_helpers_act3.ink` — 受 mass rename 影响（HP_昕/理智_昕）
- `src/_helpers_act1.ink` — 受 mass rename 影响（如有）
- `index.html` — PR 8：标题页 PC 选择 + HUD 切换 + PC profile 卡片渲染

**新建：**
- `src/喘息夜.ink` — §8 + §9（继承现 plan §6 PR 4 的预期，但内容按多 PC 重设计）

**编译产物（自动）：** `kongjiang_act{0,1,2,3}.json`

---

## 通用验证流程（每 task 共享，下文不重复完整描述）

### 编译验证

```bash
cd kongjiang-ink-demo
INK="/c/Users/xinlu/AppData/Local/Temp/inklecate/inklecate.exe"
for f in 0 1 2 3; do
  "$INK" -o "kongjiang_act$f.json" "src/kongjiang_act$f.ink" 2>&1 | tail -3
done
```

期望：4 个 act 全部 `Inklecate ran successfully` 无 error/warning。

### CLI 烟测

```bash
printf "1\n1\n1\n3\n" | timeout 8 "$INK" -p src/kongjiang_act0.ink 2>&1 | tail -50
```

输入序列代表"进序章 → 顶层 → 调查菜单 → 翻衣柜 → 推进"等具体路径。每 task 的 verify 步骤会指定具体输入序列。

### 切 PC 测试方法

ink-only 阶段（PR 1-7）切换不同 PC：

```bash
# 临时改 _data.ink 默认 PC
sed -i 's/VAR 当前PC = (昕)/VAR 当前PC = (砚波)/' src/_data.ink
# 重编译
"$INK" -o kongjiang_act0.json src/kongjiang_act0.ink
# 测试
printf "..." | "$INK" -p src/kongjiang_act0.ink
# 测试完恢复
sed -i 's/VAR 当前PC = (砚波)/VAR 当前PC = (昕)/' src/_data.ink
```

### Commit 规范

每 task 一 commit；message `type(scope): 中文说明`；不 push（PR 末尾汇总 push）。

---

## Phase 1 — ink var 架构 + mass rename（PR 1）

**目标：** 4 PC ink 状态架构落地，所有 stat var 从 `_昕` 后缀改成通用名。CLI 默认 PC=昕 跑通现有内容（与现 demo 行为等价），为 Phase 2 内容增量铺路。

### Task 1.1：加 PC LIST + 通用 PC stats + 4 角色关系 var

**Files:**
- Modify: `src/_data.ink` (在文件末尾追加块)

- [ ] **Step 1：在 `_data.ink` 末尾追加 var 声明**

```ink
// === 多 PC 系统（spec §2.1）===
LIST PC列表 = 昕, 砚波, 志勇, 张怡
VAR 当前PC = (昕)

// 通用 PC stats（替代原 理智_昕 / HP_昕）
VAR 理智_PC = 64
VAR HP_PC = 12
VAR 队友存活_PC = true

// PC 名字字符串（NPC 喊话 / 选项文案动态化用）
VAR 当前PC名 = "罗昕"
VAR 当前PC昵称 = "昕"

// 4 角色关系 var（self-var 闲置）
VAR 信任_昕 = 0
VAR 信任_砚波 = 0
VAR 信任_志勇 = 0
VAR 信任_张怡 = 0
VAR 恐惧_昕 = 0
VAR 恐惧_砚波 = 0
VAR 恐惧_志勇 = 0
VAR 恐惧_张怡 = 0
VAR 状态_昕 = (平静)
VAR 状态_砚波 = (平静)
VAR 状态_志勇 = (平静)
VAR 状态_张怡 = (平静)
VAR 陪伴_昕 = false
VAR 陪伴_砚波 = false
VAR 陪伴_志勇 = false
VAR 陪伴_张怡 = false
```

- [ ] **Step 2：删除 Y 路线遗留的旧 PC stats var**

`_data.ink` 中删除（这些是 PC 专属 stats，被通用化版本替代）：

```ink
// 删除这些行（如果存在）
VAR 理智_昕 = 64
VAR HP_昕 = 12
VAR 队友存活_昕 = true
```

注：Y 路线已删除 `恐惧_昕 / 信任_昕 / 状态_昕 / 陪伴_昕`。Step 1 重新添加这些（含 4 角色版本）。如果 grep 显示有残留 Y 删除版本，是 Step 1 自己加的，跳过。

- [ ] **Step 3：在 `kongjiang_act0.ink` 局部 VAR 区做对应同步**

`kongjiang_act0.ink` 顶部局部声明区（line 14-55 区域）—— 因为 act0 不 INCLUDE _data.ink。删除局部 `理智_昕 / HP_昕`，加局部版本：

```ink
// PC 罗昕（昕）= 默认 PC
LIST PC列表 = 昕, 砚波, 志勇, 张怡
VAR 当前PC = (昕)
VAR 理智_PC = 64
VAR HP_PC = 12
VAR 队友存活_PC = true
VAR 当前PC名 = "罗昕"
VAR 当前PC昵称 = "昕"
// 4 角色关系 var（同 _data.ink）
VAR 信任_昕 = 0
VAR 信任_砚波 = 0
VAR 信任_志勇 = 0
VAR 信任_张怡 = 0
VAR 恐惧_昕 = 0
VAR 恐惧_砚波 = 0
VAR 恐惧_志勇 = 0
VAR 恐惧_张怡 = 0
VAR 状态_昕 = (平静)
VAR 状态_砚波 = (平静)
VAR 状态_志勇 = (平静)
VAR 状态_张怡 = (平静)
VAR 陪伴_昕 = false
VAR 陪伴_砚波 = false
VAR 陪伴_志勇 = false
VAR 陪伴_张怡 = false
```

- [ ] **Step 4：编译验证**

```bash
INK="/c/Users/xinlu/AppData/Local/Temp/inklecate/inklecate.exe"
for f in 0 1 2 3; do
  "$INK" -o "kongjiang_act$f.json" "src/kongjiang_act$f.ink" 2>&1 | tail -3
done
```

期望：4 act 全部 `Inklecate ran successfully`。可能会因 Step 5 的 mass rename 还没做而仍有 `理智_昕` 调用残留报错——属预期，下 task 修。

- [ ] **Step 5：Commit**

```bash
git add src/_data.ink src/kongjiang_act0.ink
git commit -m "feat(multi-pc): 加 PC LIST + 通用 PC stats + 4 角色关系 var (架构层)"
```

### Task 1.2：加 `初始化PC(pc)` 函数

**Files:**
- Modify: `src/_helpers.ink` (末尾追加)

- [ ] **Step 1：在 `_helpers.ink` 末尾追加函数**

```ink
// === 多 PC 系统：PC 选择初始化（spec §2.2）===
// 4 PC 各自的 default stats（来自 index.html PC_DATA + COMPANIONS）
=== function 初始化PC(pc)
~ 当前PC = pc
{ pc == 昕:
    ~ 当前PC名 = "罗昕"
    ~ 当前PC昵称 = "昕"
    ~ 理智_PC = 64
    ~ HP_PC = 12
    ~ 信任_砚波 = 70
    ~ 信任_志勇 = 60
    ~ 信任_张怡 = 65
    ~ 恐惧_砚波 = 25
    ~ 恐惧_志勇 = 20
    ~ 恐惧_张怡 = 25
- pc == 砚波:
    ~ 当前PC名 = "砚波"
    ~ 当前PC昵称 = "砚波"
    ~ 理智_PC = 60
    ~ HP_PC = 12
    ~ 信任_昕 = 70
    ~ 信任_志勇 = 50
    ~ 信任_张怡 = 55
    ~ 恐惧_昕 = 30
    ~ 恐惧_志勇 = 25
    ~ 恐惧_张怡 = 30
- pc == 志勇:
    ~ 当前PC名 = "志勇"
    ~ 当前PC昵称 = "志勇"
    ~ 理智_PC = 60
    ~ HP_PC = 16
    ~ 信任_昕 = 65
    ~ 信任_砚波 = 60
    ~ 信任_张怡 = 50
    ~ 恐惧_昕 = 25
    ~ 恐惧_砚波 = 30
    ~ 恐惧_张怡 = 35
- pc == 张怡:
    ~ 当前PC名 = "张怡"
    ~ 当前PC昵称 = "张怡"
    ~ 理智_PC = 70
    ~ HP_PC = 10
    ~ 信任_昕 = 55
    ~ 信任_砚波 = 55
    ~ 信任_志勇 = 45
    ~ 恐惧_昕 = 35
    ~ 恐惧_砚波 = 30
    ~ 恐惧_志勇 = 35
}
```

- [ ] **Step 2：编译验证**（同 Task 1.1 Step 4）

预期：4 act 编译 clean（函数声明不引入新 break）。

- [ ] **Step 3：Commit**

```bash
git add src/_helpers.ink
git commit -m "feat(multi-pc): 加 初始化PC(pc) 函数 (4 PC default stats)"
```

### Task 1.3：mass rename `_昕` 通用 var

**Files:**
- Modify: `src/_data.ink` / `src/_helpers.ink` / `src/_helpers_act3.ink` / `src/_helpers_act1.ink` / `src/kongjiang_act0.ink` / `src/kongjiang_act1.ink` / `src/kongjiang_act2.ink` / `src/kongjiang_act3.ink` / `src/act1_scenes.ink` / `src/act2_scenes.ink` / `src/act3_scenes.ink` / `src/act3_boss.ink` / `src/kongjiang_endings.ink`

- [ ] **Step 1：批量替换（sed 适合此类机械批改）**

```bash
cd kongjiang-ink-demo
files="src/_data.ink src/_helpers.ink src/_helpers_act1.ink src/_helpers_act3.ink src/kongjiang_act0.ink src/kongjiang_act1.ink src/kongjiang_act2.ink src/kongjiang_act3.ink src/act1_scenes.ink src/act2_scenes.ink src/act3_scenes.ink src/act3_boss.ink src/kongjiang_endings.ink"

for f in $files; do
  [ -f "$f" ] || continue
  # 注意:不能误改 4 角色关系 var (恐惧_昕 / 信任_昕 等)
  sed -i 's/理智_昕/理智_PC/g' "$f"
  sed -i 's/HP_昕/HP_PC/g' "$f"
  sed -i 's/队友存活_昕/队友存活_PC/g' "$f"
done
```

- [ ] **Step 2：核查是否误改 4 角色关系 var**

```bash
grep -rn "恐惧_PC\|信任_PC\|状态_PC\|陪伴_PC" src/
```

期望：**0 匹配**。如有匹配，sed 误改了关系 var；恢复对应 var 名（仅 `理智_PC / HP_PC / 队友存活_PC` 是合法通用名）。

- [ ] **Step 3：编译验证 + 检查残留**

```bash
INK="/c/Users/xinlu/AppData/Local/Temp/inklecate/inklecate.exe"
for f in 0 1 2 3; do
  "$INK" -o "kongjiang_act$f.json" "src/kongjiang_act$f.ink" 2>&1 | tail -3
done
grep -rn "理智_昕\|HP_昕\|队友存活_昕" src/
```

期望：编译 clean + grep 0 匹配。

- [ ] **Step 4：Commit**

```bash
git add -A
git commit -m "refactor(multi-pc): mass rename 理智_昕→理智_PC / HP_昕→HP_PC / 队友存活_昕→队友存活_PC (~60 处)"
```

### Task 1.4：4 act 入口加临时 CLI init

**Files:**
- Modify: `src/kongjiang_act0.ink` (序章入口前)
- Modify: `src/kongjiang_act1.ink` (入口处)
- Modify: `src/kongjiang_act2.ink` (入口处)
- Modify: `src/kongjiang_act3.ink` (入口处)

每个 act 的入口 free-code 区，**在 `~ 应用seed()` 之后**追加临时 init 块：

- [ ] **Step 1：act0 加临时 init**

修改 `src/kongjiang_act0.ink` line 59-61 区域（在 `~ SEED_RANDOM(2026)` 之后）：

```ink
~ SEED_RANDOM(2026)

// TEMP: ink-only 烟测用,PR 8 HTML 实现时移除
~ 初始化PC(当前PC)

-> 序章入口
```

- [ ] **Step 2：act1 加临时 init**

修改 `src/kongjiang_act1.ink` 入口（`~ 应用seed()` 之后，已有 `~ 推进阶段(1)`，在它之前或之后）：

```ink
~ 应用seed()

// TEMP: ink-only 烟测用,PR 8 HTML 实现时移除
{ 当前PC == 昕: ~ 初始化PC(当前PC) }
// 注:Act 1 入口默认假设 act0 已 init (HTML 阶段会跨 act 注入),
//    临时阶段如 CLI 直接跑 act1 需手动 init

~ 推进阶段(1)
```

实际逻辑：HTML 阶段会通过 `variablesState["当前PC"]` 跨 act 注入。CLI 单跑 act1 时，act1 的 `当前PC` 就是 `_data.ink` 默认值 `(昕)`。Step 2 的 init 仅在 `当前PC == 昕` 时强制 init（防御性）。

更简洁的做法是 act1/act2/act3 入口都不加 init（依赖 _data.ink 默认值已经 init 过）。Step 2 直接跳过。

- [ ] **Step 2-alt（推荐）：act1 / act2 / act3 入口不加 init**

依赖 _data.ink 默认值。但 _data.ink 默认值是变量声明默认（理智_PC=64 等），可能跟 `初始化PC(昕)` 不完全一致——init 函数还设置了 NPC 关系 var 和当前PC名/昵称。

**最终方案：** 在 `_data.ink` 末尾加一个 INCLUDE-time 自动 init：

```ink
// _data.ink 末尾
// TEMP: 默认 PC 自动 init (ink-only 阶段 + 跨 act 默认值)
// PR 8 HTML 实现时由 PC 选择 menu 显式调 初始化PC(),此 INCLUDE 自动 init 仍合理保留作为 fallback
```

但 ink VAR 声明区不能调用 function。需在 act 入口调。

最终决定：**只在 act0 入口调 `~ 初始化PC(当前PC)`**（act1-3 通过跨 act var 注入获取 PC 状态；CLI 直接跑 act1-3 时依赖 _data.ink VAR 默认值已经够用）。

回到 Step 1，仅 act0 加 init 即可。Step 2-3-4 跳过。

- [ ] **Step 5：编译验证**（同 Task 1.1 Step 4）

期望：4 act 编译 clean。

- [ ] **Step 6：CLI 烟测**

```bash
printf "1\n1\n1\n3\n" | timeout 8 "$INK" -p src/kongjiang_act0.ink 2>&1 | head -30
```

期望：序章入口正常显示 → 进入寝室傍晚 → 调查菜单 → 选项可玩。

- [ ] **Step 7：Commit**

```bash
git add src/kongjiang_act0.ink
git commit -m "feat(multi-pc): act0 入口加 初始化PC(当前PC) 临时 init (PR 8 HTML 时移除)"
```

### Task 1.5：恢复 Y 路线删除的 var 调整调用（部分回退）

⚠️ Y 路线删除了"昕作为 NPC"的 50+ 处 `调整恐惧(恐惧_昕,...) / 调整信任(信任_昕,...)`。多 PC 路线下这些**仍要保持删除**——因为剧本里"昕"的语境是 PC 自己（`理智_PC` / SAN），不是 NPC 关系。

但 Y 路线没考虑"PC=砚波/志勇/张怡 时，昕 是 NPC，需要新增对昕的关系调整调用"。这是新增工作，**留到 PR 2/3 内容编写时按需添加**（哪些场景"现在 PC 看到昕在抖" → 加 `~ 调整恐惧(恐惧_昕, 状态_昕, +N)`）。

- [ ] **本 task 无代码改动**，仅文档说明：

PR 1 不补充对昕的关系调整调用。各 PR 内容编写时遇到合适场景再加。

### PR 1 收尾

- [ ] **Step 1：新分支 push + 开 PR**

```bash
git checkout -b feat/multi-pc-phase1-infra
git push -u origin feat/multi-pc-phase1-infra
gh pr create --base main --head feat/multi-pc-phase1-infra \
  --title "feat(multi-pc): Phase 1 — ink var 架构 + mass rename + 临时 init" \
  --body "落地 spec §2.1-2.4。4 act 编译 clean,默认 PC=昕 行为与现 demo 等价。"
```

- [ ] **Step 2：等用户 review，merge 后回 main pull**

---

## Phase 2 — ink-only 内容增量

### PR 2：PC-条件菜单 + 4 PC × 1 signature scene

**目标：** 4 PC 各自的不可错过的高光时刻 + 每场景里 PC-条件解锁选项的骨架。

**写作量预警：** 本 PR 含 ~500 行新创作内容（4 signature × ~80 行 + 8-10 PC-条件选项 × ~20 行）。**写作类 task 用户必须 review prose 后再 commit**（按之前 Phase 3 沟通约定）。

#### Task 2.1：昕 signature — act0 翻衣柜厨师梦内心戏

**Files:**
- Modify: `src/kongjiang_act0.ink` (`= 调查_衣柜` stitch)

- [ ] **Step 1：读取当前 `调查_衣柜` stitch 内容**

定位 act0 line ~148-167（Y 路线后行号约值，编辑时确认）。

- [ ] **Step 2：在 `ok:` 分支末尾（主厨刀解锁后）追加 PC=昕 内心戏块**

```ink
// 现有的 ok 分支,主厨刀解锁逻辑保留:
- ok:
    一把主厨刀，包在油纸里。还有一袋花椒辣椒面。你把它们悄悄塞进床底下伸手就能够到的位置。
    ~ 主厨刀_unlocked = true
    （你的工具栏更新：主厨刀 / 辣椒面）

    // 新增 PC=昕 signature 内心戏 (~40 行)
    { 当前PC == 昕:
        // [WRITING BRIEF: PC=昕 才可见,40 行 prose]
        // 主题:厨师梦 + 主厨刀的来历 + 偷藏菜谱本回忆
        // 关键 beat:
        //   1. 你看着这把刀,想起当时挑刀的时候 (具象化:在哪买/什么型号)
        //   2. 厨师学校的菜谱本,你从枕头下摸出来又塞回去
        //   3. 你妈那次哭/你爸"让她别管" 的回忆
        //   4. 现在不是想这些的时候——但你又收回去看了一眼
        // 风格:第二人称内心独白,40 字/段 × ~5 段
        // 黑名单:不写信/不溯及童年(spec §plan.5 P5)
    }
- else:
```

⚠️ **WRITING BRIEF**：上述注释块不是占位符，是给 ink 创作者的明确简报：4-5 段 × 40 字内心独白 = 40 行 ink，含 5 个具体 beat。Plan 不预写 prose；execution 时按 brief 写并让用户 review。

- [ ] **Step 3：编译验证**（同上）

- [ ] **Step 4：CLI 烟测**

切 PC=昕（默认）触发翻衣柜：

```bash
printf "1\n1\n3\n" | timeout 8 "$INK" -p src/kongjiang_act0.ink 2>&1 | tail -50
```

期望：进入调查菜单 → 翻衣柜 → 看到主厨刀解锁 + 厨师梦内心戏（昕的 PC 视角）。

- [ ] **Step 5：用户 review prose**（写作 task 强制点）

- [ ] **Step 6：Commit**

```bash
git add src/kongjiang_act0.ink
git commit -m "feat(multi-pc): 昕 signature scene — act0 翻衣柜 + 主厨刀 + 厨师梦内心戏 (~40 行)"
```

#### Task 2.2：砚波 signature — act0 夜半叩门早觉知

**Files:**
- Modify: `src/kongjiang_act0.ink` (`场景_夜半叩门` knot 的 3 个反应选项)

- [ ] **Step 1：定位 `场景_夜半叩门` knot**（act0 ~line 251）

- [ ] **Step 2：在 3 个反应选项内分别加 `{当前PC == 砚波}` 早觉知块**

```ink
// 例:大声问 "谁" 选项内
* [大声问 "谁"]
    你的声音在寝室里回荡了一下。门外没有任何回应。
    { 当前PC == 砚波:
        // [WRITING BRIEF: 15 行 PC=砚波 早觉知]
        // 主题:砚波最先看清"它不是人"
        // beat:
        //   1. 你的声音回响时,你已经看见门后阴影下的形状不对
        //   2. 你心想"那不是人,那是什么穿着衣服"
        //   3. 但你不说出来——说了也没用
        ~ 推进觉知(门外有东西)
    }
```

类似处理 〔聆听〕 + 让志勇过去看 两个选项。

- [ ] **Step 3：编译 + 切 PC 烟测**

```bash
sed -i 's/VAR 当前PC = (昕)/VAR 当前PC = (砚波)/' src/_data.ink
"$INK" -o kongjiang_act0.json src/kongjiang_act0.ink
printf "..." | "$INK" -p src/kongjiang_act0.ink   # 触发夜半叩门
sed -i 's/VAR 当前PC = (砚波)/VAR 当前PC = (昕)/' src/_data.ink
```

期望：PC=砚波 时夜半叩门触发砚波早觉知 prose；PC=昕 时不触发（保留原 check-based 流程）。

- [ ] **Step 4：用户 review + Commit**

```bash
git add src/kongjiang_act0.ink
git commit -m "feat(multi-pc): 砚波 signature — act0 夜半叩门早 1 拍触发觉知 (~45 行)"
```

#### Task 2.3：志勇 signature — act3_boss 阶段 3 警察世家闪回

**Files:**
- Modify: `src/act3_boss.ink` (阶段 3 入口)

- [ ] **Step 1：定位 act3_boss 阶段 3**（搜 `阶段3` 或 `Boss阶段 == 3`）

- [ ] **Step 2：阶段 3 入口加 PC=志勇 闪回触发**

```ink
=== a3_boss_阶段3 ===
// 现有阶段 3 narrative
{ 当前PC == 志勇:
    -> 志勇_警察世家闪回
}
// ... 原有阶段 3 内容继续

=== 志勇_警察世家闪回 ===
// [WRITING BRIEF: 80 行 PC=志勇 signature 闪回]
// 主题:警察世家父亲眼里"我应该顶得住"
// beat:
//   1. boss 扑过来的瞬间,你脑子里闪了一下 (15 行)
//   2. 6 岁第一次被你爸打 (因为哭)、9 岁、12 岁、15 岁的训练画面 (30 行)
//   3. 你爸的话:"你这种身板,这种时候不顶谁顶" (15 行)
//   4. 你睁眼,boss 还在面前。但你的手不抖了。 (10 行)
//   5. ~ 调整理智(理智_PC, +3) // 闪回让志勇 PC 反而稳住
//   6. 推进到原阶段 3 主流程
-> a3_boss_阶段3.原入口   // 或具体阶段 3 stitch 名,plan 阶段确认
```

- [ ] **Step 3：编译 + 切 PC=志勇 + 模拟 boss 战到阶段 3 + 验证**

由于 boss 战到阶段 3 需要长链路操作，CLI 烟测可能复杂。建议**测试 gate 时（PR 7 后）统一验证**，本 task 仅做编译 + grep 检查 stitch 引用正确。

- [ ] **Step 4：用户 review + Commit**

```bash
git add src/act3_boss.ink
git commit -m "feat(multi-pc): 志勇 signature — act3_boss 阶段 3 警察世家闪回 (~80 行)"
```

#### Task 2.4：张怡 signature — act2 走廊几何节奏 + 提前解锁母核

**Files:**
- Modify: `src/act2_scenes.ink` (`a2_走廊2F` 观察菜单)
- 新增 stitch：`= 张怡_算节奏`

- [ ] **Step 1：定位 act2_scenes.ink `a2_走廊2F.观察菜单`**

- [ ] **Step 2：观察菜单加 PC=张怡 条件项**

```ink
= 观察菜单
你想看清这条走廊的什么？
* 〔聆听 65〕侧耳听走廊尽头的动静 -> a2_听走廊尽头
+ {当前PC == 张怡} 〔神秘学+数学〕看出节奏 -> 张怡_算节奏
+ [← 还是先做点别的] -> 内2F

= 张怡_算节奏
// [WRITING BRIEF: 80 行 PC=张怡 signature 走廊几何]
// 主题:张怡看出菌丝几何分布,算出母核位置
// beat:
//   1. 你蹲下来看墙缝里的菌丝 (20 行)
//   2. 一段计算:6 个迭代,每次旋转 360/7 度,中心在...... (25 行,可参考 act3:472 现有"6 个迭代"对白)
//   3. 你心里冒出坐标:1F 东南角,地面以下 (15 行)
//   4. 设置母核_位置已知 = true (新 var,用于 act3 boss 减回合)
//   5. 推进觉知 + 推进生态(7) (确定性最高)
//   6. 回到走廊 (~ tick回合())
~ 母核_位置已知 = true
~ 推进觉知(门外有东西)
~ 推进生态(7)
~ tick回合()
-> 内2F
```

- [ ] **Step 3：在 `_data.ink` 加 var**

```ink
VAR 母核_位置已知 = false   // 张怡 signature 解锁,act3 boss 战减 1 回合
```

- [ ] **Step 4：act3_boss 阶段 1 入口加 `母核_位置已知` reduce 回合**

```ink
=== a3_boss_阶段1 ===
{ 母核_位置已知:
    // PC=张怡 提前算出母核位置,boss 阶段 1 直接进入
    张怡指着东南角:"那里。"
    ~ Boss战_回合 = Boss战_回合 + 1   // 提前 1 回合
}
// 原阶段 1 内容继续
```

- [ ] **Step 5：编译 + 切 PC=张怡 + 走廊 trigger 烟测**

- [ ] **Step 6：用户 review + Commit**

```bash
git add src/act2_scenes.ink src/act3_boss.ink src/_data.ink
git commit -m "feat(multi-pc): 张怡 signature — act2 走廊几何节奏 + 提前解锁母核位置 (~80 行)"
```

#### Task 2.5：8-10 处 PC-条件菜单选项

**Files:**
- Modify: `src/kongjiang_act0.ink` / `src/act1_scenes.ink` / `src/act2_scenes.ink` / `src/act3_scenes.ink`

具体位置（待 spec §6.2 列表，plan 阶段细化为 8-10 个）：

1. act0 寝室傍晚.调查菜单 — `+ {当前PC == 张怡} 〔数学预判〕推算今晚有事 -> 张怡_预判`
2. act0 战斗循环.攻击菜单 — `+ {当前PC == 砚波} 〔格斗 65〕直接迎面 -> 攻击_砚波_迎面`
3. act1 寝室302.内302 — `+ {当前PC == 砚波} 〔危机解析〕看一眼门 -> 砚波_看门`
4. act1 走廊3F.观察菜单 — `+ {当前PC == 砚波} 〔聆听 50〕察觉前方异响 -> 砚波_异响`
5. act1 锚点 A — `+ {当前PC == 张怡} 〔数学共鸣〕和卢剑桥聊数学 -> 张怡_卢_共鸣`
6. act2 走廊2F.内2F — 已含张怡 signature(Task 2.4),不重复
7. act2 锚点 B — `+ {当前PC == 砚波} 〔危机解析〕识破黄兴树假笑 -> 砚波_黄_识破`
8. act3 共识抉择 — `+ {当前PC == 志勇} 〔体能〕"我顶得住" -> 志勇_顶`
9. act3_boss 攻击菜单（已 Task 2.3 部分覆盖,本 task 完善）— 详 PR 6
10. （可选）act0 对话菜单 — 各 PC 对其他 NPC 1 句独特反应

每选项 + 对应 stitch（~20 行）：

- [ ] **Step 1：逐个位置实施（建议拆 8-10 sub-task,每个一 commit）**

每个 sub-task 模式：
1. 定位场景 menu
2. 加 PC-条件 + 选项行
3. 新建 stitch（~20 行 prose）
4. 编译 + 切 PC 验证
5. 用户 review + commit

- [ ] **Step 2：合并 commit 或逐个**

- [ ] **每选项 commit message：`feat(multi-pc): PC-条件选项 — <场景> <PC> <动作> (~20 行)`**

#### PR 2 收尾

- [ ] **新分支 push + 开 PR `feat/multi-pc-phase2-signature`**
- [ ] **review + merge + main pull**

---

### PR 3：4 PC × 2 minor 高光 + NPC flavor pockets

**目标：** 12 minor 高光 + 6 NPC flavor 段，全部 ink-only。

**写作量预警：** 12 minor × 40 行 + 6 flavor × 50 行 = ~780 行新创作。**写作类 task 强制 review。**

#### Task 3.1：4 PC × 2 minor 高光（拆 8 sub-tasks）

8 个 minor 高光（spec §5.2 草案）：

1. **昕 minor 1** — act0 安抚他人时社交核心 buff（〔说服〕成功率 +5）
2. **昕 minor 2** — act2 锚点 B 黄兴树吃货 vs 富二代价值观对话
3. **砚波 minor 1** — act1 走廊菌丝异常最先发现 + 〔聆听〕buff
4. **砚波 minor 2** — act2 储藏室体能优势（撞门/扛物）
5. **志勇 minor 1** — act0 战斗第一拍 1.9 米巨汉先扑（DB +1D6 加成）
6. **志勇 minor 2** — act2 锚点内心独白：其实我超怕（外强内怯）
7. **张怡 minor 1** — act0 寝室傍晚 〔数学预判〕菜单选项
8. **张怡 minor 2** — act2 走廊 充电宝 buff（队友神秘学 +15）

**每 minor sub-task 模式：**
- [ ] 定位场景
- [ ] 加 PC-条件 stitch + 内容（~40 行 WRITING BRIEF）
- [ ] 编译 + 切 PC 烟测
- [ ] 用户 review prose + commit

#### Task 3.2：6 NPC flavor pockets（早+中期）

3 NPC × 2 phase = 6 段 flavor。模式参考现 plan §5（Y 路线后的 3 NPC 版）。

⚠️ Y 路线 PR #7 已删除原 plan Task 3.1 (昕 flavor)。本 task 实施剩余 3 NPC flavor：

- 砚波 早 + 中
- 志勇 早 + 中
- 张怡 早 + 中

每段 flavor ~50 字 prose，嵌入 NPC 对话 knot 子话题菜单。

⚠️ **依赖：** 需要先有 NPC 对话 knot。Y 路线删除了 `对话_昕 / a1_对话_昕`，但 `对话_砚波 / 对话_志勇 / 对话_张怡` 在 act0 / act1 现状不存在或仅 act0 有 stub。本 task 包含**新建 a1_对话_砚波 / a1_对话_志勇 / a1_对话_张怡 knot + 把它们接入 a1_寝室302 对话菜单**（参考现 plan Task 3.4 P3 fix 的兜底逻辑）。

**Step 详（共 3 NPC + 入口接入）：**

- [ ] **Step 1：在 a1_寝室302 加 [找人说话] 子菜单（如不存在）**
- [ ] **Step 2：3 NPC × 新建 a1_对话_X knot + 嵌入 早+中 flavor 子话题**
- [ ] **Step 3：act2 走廊2F 加 [找人聊聊] 子菜单（spec §plan §3 双锚点）**
- [ ] **Step 4：3 NPC × 新建 a2_对话_X knot + 嵌入中期 flavor**
- [ ] **Step 5：编译 + 4 PC 切换烟测进对话菜单（PC=自己时 self 对话不可见，验证 sub-menu gate）**
- [ ] **Step 6：用户 review prose + commit**

#### PR 3 收尾

---

### PR 4：喘息夜 1（4 PC 内心独白 + 3 NPC 心里话）

**目标：** spec §8 完整实施。

**Files:**
- Create: `src/喘息夜.ink`
- Modify: `src/kongjiang_act1.ink`（终幕加 `INCLUDE 喘息夜.ink` + divert 喘息夜1）
- Modify: `src/kongjiang_act2.ink`（入口从喘息夜1 进入）

#### Task 4.1：创建 `喘息夜.ink` 骨架

```ink
// 喘息夜.ink — 桥接场景 (Act1↔Act2 / Act2↔Act3)
// 全程免费 (不消耗 tick)

=== 喘息夜1 ===
// spec §8 大纲
TODO  // 在 Task 4.2-4.6 填充

=== 喘息夜2 ===
// spec §9 大纲
TODO  // 在 PR 5 填充
```

- [ ] act1 终幕末尾 divert 喘息夜1
- [ ] act2 入口 divert 喘息夜1.过场 → Act2 主入口
- [ ] 编译 + smoke
- [ ] commit `feat(喘息夜): 创建 喘息夜.ink 骨架 + Act1↔Act2 接入`

#### Task 4.2：写喘息夜 1 共享外壳

```ink
=== 喘息夜1 ===
// [WRITING BRIEF: ~40 行 共享外壳]
// 1. 场记开头 (深夜 2 点,铁皮缝里漏进路灯,302 室内,15 行)
// 2. 4 PC 内心独白 gate (5 行 ink 控制流)
// 3. 共享 NPC 心里话节 (gate 跳过 PC 自己,15 行 ink 控制流)
// 4. 沉默 + 玩家选择 (5 行)
// 5. 过场到 Act 2 (5 行)

[场记开头]

{ 当前PC == 昕: -> _昕独白
- 当前PC == 砚波: -> _砚波独白
- 当前PC == 志勇: -> _志勇独白
- 当前PC == 张怡: -> _张怡独白 }

= _3NPC心里话
{ 当前PC != 砚波: 砚波片段 }
{ 当前PC != 志勇: 志勇片段 }
{ 当前PC != 张怡: 张怡片段 }
[沉默选择]
-> Act2_主入口
```

- [ ] commit

#### Task 4.3-4.6：4 PC 内心独白 stitch + 3 NPC 心里话片段

每 stitch ~20 行 WRITING BRIEF（spec §8.2 主题表）：

- Task 4.3：`= _昕独白`（高三压力 / 数学错题，PC=昕 触发）
- Task 4.4：`= _砚波独白`（最能打的人的责任 / 怎么把人都护住）
- Task 4.5：`= _志勇独白`（警察世家 / 我应该顶得住）
- Task 4.6：`= _张怡独白`（数字让我冷静 / 自我催眠）
- Task 4.7：3 NPC 心里话片段（砚波 旧事 / 志勇 想吃的 / 张怡 死亡观伏笔）

每 task 写 + 用户 review prose + commit。

#### PR 4 收尾

---

### PR 5：喘息夜 2（4 NPC 深聊 + PC-relative 头尾）

**目标：** spec §9 完整实施。**最长 PR**（~440 行）。

#### Task 5.1：写喘息夜 2 外壳 + 入口接入

```ink
=== 喘息夜2 ===
~ 推进阶段(3)
[氛围铺垫:明天就要冲了,~30 行]
-> 选谁

= 选谁
你想多陪谁一会儿？
* {当前PC != 昕} 多陪昕一会儿 -> 深聊_昕
* {当前PC != 砚波} 多陪砚波一会儿 -> 深聊_砚波
* {当前PC != 志勇} 多陪志勇一会儿 -> 深聊_志勇
* {当前PC != 张怡} 多陪张怡一会儿 -> 深聊_张怡

= 第二轮选谁
夜更深了。还有时间,再陪一个人？
+ {当前PC != 昕 && not 陪伴_昕} 多陪昕 -> 深聊_昕
+ {当前PC != 砚波 && not 陪伴_砚波} 多陪砚波 -> 深聊_砚波
+ {当前PC != 志勇 && not 陪伴_志勇} 多陪志勇 -> 深聊_志勇
+ {当前PC != 张怡 && not 陪伴_张怡} 多陪张怡 -> 深聊_张怡
+ 不陪了,闭眼睡 -> 天亮

= 天亮
[过场到 Act 3,~20 行]
-> Act3_主入口
```

- [ ] act2 终幕 divert 喘息夜2
- [ ] act3 入口从喘息夜2.天亮 进入（删除原 Y 路线 act3 入口的 `~ 推进阶段(3)`）
- [ ] commit

#### Task 5.2-5.5：4 NPC 深聊 stitch（每个 ~110 行）

每 stitch 包含：
- PC-relative 头部（10 行 × 3 visiting PC = 30 行）
- 主体内心独白（60 行，所有 visiting PC 共享）
- PC-relative 尾部（10 行 × 3 visiting PC = 30 行）
- ~ 陪伴_X = true
- 总计 ~120 行/stitch

**Task 5.2：深聊_昕**（PC=砚波/志勇/张怡 visit）—— 主题"最害怕的事·独自一个人"
**Task 5.3：深聊_砚波**（PC=昕/志勇/张怡 visit）—— 主题"他对你最想说的话"（昕视角是 3 选 1 听；其他 PC 视角是不同 NPC 心声）
**Task 5.4：深聊_志勇** —— 主题"和家人的关系"（电话片段记忆，spec §plan.5 黑名单不写信）
**Task 5.5：深聊_张怡** —— 主题"对死亡的看法"

每 task 写 + 用户 review prose + commit。

#### PR 5 收尾

---

### PR 6：boss + 锚点 PC-aware

**目标：** spec §10 + §11 实施。

#### Task 6.1：boss 阶段 1/2 攻击 menu PC-条件分流

**Files:** `src/act3_boss.ink`

```ink
= 攻击菜单
+ {当前PC == 昕 && 主厨刀_unlocked} 〔格斗 45〕拔刀挥砍 -> 攻击_刀
+ {当前PC == 砚波} 〔格斗 65〕徒手反击 -> 攻击_拳_砚波
+ {当前PC == 志勇} 〔格斗 55〕扛起哑铃砸下 -> 攻击_哑铃_志勇
+ {当前PC == 张怡} 〔神秘学+数学〕念出菌丝几何弱点 -> 攻击_神秘_张怡
* {not 辣椒面_used && 主厨刀_unlocked} 〔投掷 50〕扔辣椒面 -> 攻击_辣椒
+ [← 我再想想] -> 顶层
```

新增 3 个 PC-attack stitch（每 ~30 行 WRITING BRIEF + dice 逻辑）：

- 攻击_拳_砚波（高 STR 65 hit + DB 描写）
- 攻击_哑铃_志勇（SIZ 90 + DB +1D6 大伤害）
- 攻击_神秘_张怡（神秘学 check + 智力描写）

- [ ] 4 个 sub-task，每个 stitch + commit

#### Task 6.2：boss 支援选项 gate 排除 self

```ink
+ {当前PC != 昕 && 陪伴_昕} 让昕替你挡 -> 支援_昕
+ {当前PC != 砚波 && 陪伴_砚波} 让砚波撞过来 -> 支援_砚波
+ {当前PC != 志勇 && 陪伴_志勇} 让志勇主动挡刀 -> 支援_志勇
+ {当前PC != 张怡 && 陪伴_张怡} 让张怡冷静递来 X -> 支援_张怡
```

新增支援_昕 stitch（~30 行）+ 复用 Y 路线 spec 既存的支援_志勇/张怡/砚波 设计。

- [ ] commit

#### Task 6.3：锚点 PC-aware（4-6 个 PC-条件解锁选项）

参考 spec §11：
- 卢剑桥（act1 锚点 A）：PC=张怡 多 〔数学共鸣〕选项 → ~20 行 stitch
- 黄兴树（act2 锚点 B）：PC=砚波 多 〔危机解析〕选项 → ~20 行 stitch
- （Task 2.5 已含部分锚点 PC-条件，本 task 补全）

- [ ] commit

#### PR 6 收尾

---

### PR 7：endings PC 视角调整

**目标：** spec §12 实施。最后一 ink-only PR。

#### Task 7.1：PC 名字动态化（"罗昕" → `{当前PC名}`）

15 处 NPC 喊"罗昕"对白 + var literal `牺牲对象 = "罗昕"` / `同化对象 = "罗昕"` 改用 `{当前PC名}` 写入。

```ink
// 例:
张怡："{当前PC名}——这是终点。"
~ 牺牲对象 = 当前PC名
```

- [ ] grep 定位 15 处
- [ ] 逐处替换
- [ ] commit

#### Task 7.2：E5 崩溃"你看了一眼 X"系列 PC-aware

`endings.ink:161` 现在是"你看了一眼张怡—...然后是志勇—...然后是砚波"（Y 路线已改）。多 PC 后：
- PC=张怡 时，"你看了一眼张怡" 就是看自己 → 需要 gate

```ink
{ 当前PC != 张怡:
    你看了一眼张怡——他的脖子上出现了白色的纹路。
}
{ 当前PC != 志勇:
    然后是志勇——他的瞳孔形状不对。
}
{ 当前PC != 砚波:
    然后是砚波。
}
{ 当前PC != 昕:
    然后是昕。
}
```

类似 endings:117 4 人列表 / endings:122 / endings:229 / endings:18 等多处。

- [ ] grep + 逐处加 gate
- [ ] commit

#### Task 7.3：5 年后 endings 电话 PC-relative gate

```ink
// endings.ink:54
{ 当前PC != 张怡:
    五年后某个深夜，你接到张怡的电话。他在哭。"{当前PC名}。我又梦见门外的呼吸了。"
- else:
    五年后某个深夜，你接到砚波的电话。他在哭。"{当前PC名}。我又梦见门外的呼吸了。"
}
```

- [ ] commit

#### Task 7.4：E3 牺牲自己 PC-relative 闪回小语

每 PC 1 句标志性话（spec §12.2）：
- 昕："万一……我是说万一啊……"（已有）
- 砚波：（待写）
- 志勇：（待写）
- 张怡：（待写）

```ink
- 牺牲对象 == 当前PC名:
    { 当前PC == 昕:
        你说过一句话："万一……我是说万一啊……"
    - 当前PC == 砚波:
        // [WRITING BRIEF: 砚波牺牲闪回 1 句]
    - 当前PC == 志勇:
        // [WRITING BRIEF: 志勇牺牲闪回 1 句]
    - 当前PC == 张怡:
        // [WRITING BRIEF: 张怡牺牲闪回 1 句]
    }
```

- [ ] 用户 review 4 句 prose + commit

#### PR 7 收尾

---

## 测试 Gate（PR 7 完成后，PR 8 启动前）

### Gate 1：4 act 编译 clean

```bash
INK="/c/Users/xinlu/AppData/Local/Temp/inklecate/inklecate.exe"
for f in 0 1 2 3; do
  echo "=== act$f ==="
  "$INK" -o "kongjiang_act$f.json" "src/kongjiang_act$f.ink" 2>&1 | tail -3
done
```

### Gate 2：5 endings × 4 PC = 20 路径 CLI playthrough

每 PC 跑 5 endings：

```bash
# PC=昕 (默认)
sed -i 's/VAR 当前PC = (.*)/VAR 当前PC = (昕)/' src/_data.ink
"$INK" -o kongjiang_act0.json src/kongjiang_act0.ink
# 跑 5 endings,每个不同选择序列

# PC=砚波
sed -i 's/VAR 当前PC = (.*)/VAR 当前PC = (砚波)/' src/_data.ink
"$INK" -o kongjiang_act0.json src/kongjiang_act0.ink
# 跑 5 endings

# PC=志勇 / PC=张怡 同上
```

**妥协方案（如果 20 路径太重）：**
- 5 endings × 1 PC（昕，完整）+ 4 PC × 1 signature scene CLI 触发验证（共 9 路径）
- 至少必做：5 endings × 昕 完整 + 砚波/志勇/张怡 各自 signature 触发验证

### Gate 3：用户手动 review

用户在浏览器手玩 1 PC × 1 ending 验证 ink runtime 与 inkjs 集成无 regression。

---

## Phase 3 — HTML 实现

### PR 8：标题页 PC 选择卡片 + HUD 切换 + 视角片段预览

**Files:**
- Modify: `index.html` (~110 行 JS + 适量 HTML)
- Modify: `src/kongjiang_act0.ink`（移除 Task 1.4 的临时 init）

#### Task 8.1：标题页 4 PC 选择卡片 UI

**Files:** `index.html` (HTML/CSS 部分)

- [ ] **Step 1：在标题页加 PC 选择卡片 HTML 结构**

```html
<div id="pc-select-screen" class="screen">
  <h1>选择你的角色</h1>
  <div class="pc-cards-grid">
    <div class="pc-card" data-pc="昕">
      <h3>罗昕</h3>
      <p class="pc-occupation">高三学生（吃货/社交核心）</p>
      <p class="pc-stats">理智 64 / HP 12 / 主厨刀</p>
      <p class="pc-hook">"我有主厨刀，藏在床底。"</p>
      <button class="pc-select-btn">扮演罗昕</button>
    </div>
    <!-- 砚波 / 志勇 / 张怡 同模式 -->
  </div>
</div>
```

- [ ] **Step 2：CSS 卡片样式**（约 30 行 CSS）

- [ ] **Step 3：commit**

```bash
git commit -m "feat(html): 标题页 4 PC 选择卡片 UI 框架"
```

#### Task 8.2：PC 选择 click handler → set ink var + 进入剧本

```js
document.querySelectorAll(".pc-select-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    const card = btn.closest(".pc-card");
    const pcName = card.dataset.pc;
    // 启动 story
    initStory();
    // set 当前PC + 调用 初始化PC
    story.variablesState["当前PC"] = pcName;   // 注:LIST var 赋值需用 inkjs 兼容方式
    // ink 端 ~ 初始化PC(当前PC) 在 act0 入口自动调
    // 渲染剧本
    document.getElementById("pc-select-screen").style.display = "none";
    renderStory();
  });
});
```

- [ ] **Step 1：写 click handler**
- [ ] **Step 2：测试 4 PC 都能正确启动剧本**
- [ ] **Step 3：commit**

#### Task 8.3：HUD 切换显示当前 PC + 3 NPC（skip self）

修改现有 HUD 渲染逻辑（index.html ~line 1475 `renderPanel()`）：

```js
function renderPanel() {
  const v = story.variablesState;
  const pc = v["当前PC"];   // LIST value, 取 string name
  const pcName = v["当前PC名"];

  document.getElementById("pc-name").textContent = pcName;
  document.getElementById("pc-stats").textContent =
    "理智 " + v["理智_PC"] + " / HP " + v["HP_PC"];

  // 3 NPC (skip self)
  const npcs = ["昕", "砚波", "志勇", "张怡"].filter(n => n !== pc);
  npcs.forEach((npc, i) => {
    document.getElementById("npc-slot-" + i + "-name").textContent = npc;
    document.getElementById("npc-slot-" + i + "-trust").textContent = v["信任_" + npc];
    document.getElementById("npc-slot-" + i + "-fear").textContent = v["恐惧_" + npc];
  });
}
```

- [ ] **Step 1：HUD HTML 改为 3 个动态 slot**
- [ ] **Step 2：renderPanel 改为 PC-aware**
- [ ] **Step 3：commit**

#### Task 8.4：移除 Task 1.4 临时 init

`src/kongjiang_act0.ink` 删除：

```ink
// TEMP: ink-only 烟测用,PR 8 HTML 实现时移除
~ 初始化PC(当前PC)
```

由 PR 8 Task 8.2 的 JS click handler 设置 `当前PC`，再让 ink 内部的 `~ 初始化PC(当前PC)` 在合适位置（如 序章入口 顶部）调用。

实际上 init 调用还是需要，只是触发源从"act0 入口默认"变成"PC 选择 click 后 + 跨 act 注入"。具体流程：

1. 标题页 click "扮演砚波" → JS set `当前PC = (砚波)`
2. JS 调用 ink 入口（story.ChoosePathString("序章入口") 或类似）
3. ink 序章入口处 `~ 初始化PC(当前PC)` 自动调用
4. 跨 act：act0 终幕末尾 `state.LoadJson` 时把 PC 状态传到 act1

最终 ink 端保留 `~ 初始化PC(当前PC)` 调用，仅修改触发条件。

- [ ] **Step 1：检查实际需要的 ink 改动**（可能不删，仅调整位置）
- [ ] **Step 2：跨 act 注入逻辑**（参考 act1.ink 现有 line 28-29 注入注释）
- [ ] **Step 3：commit**

#### Task 8.5：浏览器手玩 4 PC × 5 endings 测试

- [ ] 4 PC 各跑 1 完整 ending（共 4 路径）
- [ ] PC=昕 跑全 5 endings 完整验证
- [ ] 验证 HUD 切换、PC 卡片、视角片段、跨 act 状态保留
- [ ] 报 bug + 修

#### PR 8 收尾

---

## Self-Review（writing-plans skill 协议）

### 1. Spec 覆盖 check

| Spec 章节 | 落实 PR / Task |
|---|---|
| §0 8 题决策汇总 | 全 plan 贯穿 |
| §1 PC 角色定义 | Task 1.2 初始化PC default stats |
| §2.1 ink var 架构 | Task 1.1 |
| §2.2 PC 选择 init | Task 1.2 |
| §2.3 mass rename | Task 1.3 |
| §2.4 临时 CLI init | Task 1.4 |
| §3 主体共线骨架 | Phase 2 整体 |
| §4 4 signature | Task 2.1-2.4 |
| §5 4 PC × 2 minor | Task 3.1 |
| §6 PC-条件菜单 | Task 2.5 |
| §7 NPC flavor pockets | Task 3.2 |
| §8 喘息夜 1 | PR 4 |
| §9 喘息夜 2 | PR 5 |
| §10 boss PC-aware | PR 6 (Task 6.1, 6.2) |
| §11 锚点 PC-aware | PR 6 (Task 6.3) |
| §12 endings PC 视角 | PR 7 |
| §13 实施 PR 顺序 | 本 plan PR 1-8 章节顺序对应 |
| §14.2 测试 Gate | 测试 Gate 章节 |
| §14.3 itch.io OOS | OUT-OF-SCOPE 已在风险章节标注 |

### 2. Placeholder scan

- 所有 `[WRITING BRIEF: ...]` 块**不是占位符** —— 是给 ink 创作者的明确简报（主题 / 字数 / beat / 黑名单）。Plan 阶段不预写 600+ 行 prose；execution 时按 brief 写并让用户 review。
- 所有 ink 代码块都是完整模板（VAR 声明 / function / stitch 骨架）。
- Task 7.4 4 句牺牲闪回小语标注待写——属合理 brief（每句 1 行内容由创作者填）。

### 3. Type / 命名一致性

- `当前PC` (LIST) / `当前PC名` (string) / `当前PC昵称` (string) 全 plan 一致
- `理智_PC / HP_PC / 队友存活_PC` 全 plan 一致
- `信任_X / 恐惧_X / 状态_X / 陪伴_X`（X = 昕/砚波/志勇/张怡）全 plan 一致
- `初始化PC(pc)` 函数签名 全 plan 一致

### 4. Task 依赖

- PR 1 → PR 2-7 (var 架构前置)
- Task 2.4 (张怡 signature) 依赖 `母核_位置已知` var → 在 Task 2.4 Step 3 加（合理）
- Task 3.2 (NPC flavor) 依赖 a1_寝室302 / a2_走廊2F 加 [找人说话] 子菜单 → 该 task 内含
- PR 5 (喘息夜2) 依赖 PR 4 (喘息夜.ink 文件存在) → Task 4.1 创建骨架
- PR 6 boss 支援 依赖 PR 5 喘息夜2 设置 `陪伴_X` → 顺序正确
- PR 8 (HTML) 依赖 测试 Gate 通过 → 序列正确

### 5. 工作量估算 vs 实际

总盘子 ~2670 行（spec §13 表）。Plan tasks 总和（含 WRITING BRIEFs）应等同。可能差异：
- 部分 minor 高光会因实施时发现冗余而合并
- PR 5 喘息夜 2 的 PC-relative 头尾实际可能比预计 120 行更多/更少（创作 dependent）

⚠️ 风险已在 spec §14.1 标注。

---

## Out-of-Scope

- itch.io 部署（spec §14.3）
- 中途 PC 切换 / 多周目继承（spec §14.4）
- 砚波/志勇/张怡 编"姓"（spec §14.5 沿用现状）

---

**Plan 完成。**

执行选择见下方（writing-plans skill 协议）：
1. **Subagent-Driven（推荐）** —— 我用 superpowers:subagent-driven-development 派 fresh subagent 每 task 执行 + 两阶段 review
2. **Inline Execution** —— 我用 superpowers:executing-plans 在当前 session batch 执行 + checkpoints

写作类 task（WRITING BRIEFs）：每个 prose stitch 写完都让用户 review 才 commit（per Phase 3 沟通约定）。
