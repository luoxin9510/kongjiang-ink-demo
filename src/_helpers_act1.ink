// _helpers_act1.ink — Act 1+ 共享 helpers
// 依赖 _data.ink 的 VAR/LIST 声明。Act 0 不 INCLUDE 本文件。

// Seed 注入：HTML 启动前可设 seed > 0；否则随机生成并固化
=== function 应用seed()
    { seed > 0:
        ~ SEED_RANDOM(seed)
    - else:
        ~ seed = RANDOM(1, 999999)
        ~ SEED_RANDOM(seed)
    }

// 从 LIST 随机取一项（返回 LIST 单值集合）
=== function 随机取(列表)
    ~ temp 总数 = LIST_COUNT(LIST_ALL(列表))
    ~ temp 索引 = RANDOM(1, 总数)
    ~ return LIST_RANGE(LIST_ALL(列表), 索引, 索引)

// 物品系统：加入背包（防重复）
=== function 添加物品(物品名)
    { not (背包 ? 物品名):
        ~ 背包 += 物品名
    }

// 物品系统：从背包移除
=== function 移除物品(物品名)
    ~ 背包 -= 物品名

// 位置追踪
=== function 切换地点(地点id)
    ~ 当前地点 = 地点id

// 威胁时钟：每回合 +1
=== function tick威胁钟()
    ~ 威胁钟 = 威胁钟 + 1

=== function 重置威胁钟()
    ~ 威胁钟 = 0
    ~ 威胁事件触发次数 = 威胁事件触发次数 + 1

// 生态置信度推进（单调递增）
=== function 推进生态(目标置信度)
    { 目标置信度 > 生态置信度:
        ~ 生态置信度 = 目标置信度
    }

// 标记 NPC 已遭遇
=== function 遭遇NPC(npc_id)
    ~ 已遇NPC += npc_id
