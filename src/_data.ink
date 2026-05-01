// _data.ink — 全局 LIST / VAR 集中声明
// 所有 Act 共享。各 Act 主文件 INCLUDE 本文件 + _helpers.ink。

// === LIST ===
LIST 队友状态 = 平静, 紧张, 恐惧
LIST 觉知链 = 一切如常, 隐约不安, 闻到甜腥, 第一次敲门, 第二次敲门, 门外有东西
LIST 伏笔档 = 无伏笔, 一档伏笔, 二档伏笔, 三档伏笔

// 锚点 A 候选（Act 1）
LIST 锚点A候选 = npc_lujianqiao, npc_yaojunjie

// Act 1 场景 LIST
LIST Act1场景 = loc_dorm_302, loc_corridor_3f, loc_dorm_neighbor, loc_shower_3f, loc_corridor_4f, loc_stairwell_a

// 物品（背包系统）
LIST 物品 = 主厨刀, 辣椒面, 急救包, 绷带, 防疫手册, 数学草稿本, 宿管钥匙

// === PC 状态（罗昕）===
VAR 理智_昕 = 64
VAR HP_昕 = 12

// === 队友 fear / trust ===
VAR 恐惧_昕 = 35
VAR 恐惧_志勇 = 20
VAR 恐惧_张怡 = 25
VAR 信任_昕 = 70
VAR 信任_志勇 = 60
VAR 信任_张怡 = 65

// === 队友互斥状态 ===
VAR 状态_昕 = (平静)
VAR 状态_志勇 = (平静)
VAR 状态_张怡 = (平静)

// === 觉知 / 伏笔 ===
VAR 觉知 = (一切如常)
VAR 当前伏笔 = (无伏笔)

// === 计数与闸门 ===
VAR 回合数 = 0
VAR 调查数 = 0
VAR 切入解锁 = false
VAR 切入路径 = 0

// === 上次掷骰快照 ===
VAR 上次骰值 = 0
VAR 上次结果 = 0

// === 序章 / 战斗状态（保留以便跨 Act 引用）===
VAR 已进过泡面 = false
VAR 主厨刀_unlocked = false
VAR 辣椒面_used = false
VAR 敌人血量 = 8
VAR 战斗回合 = 0
VAR 战斗结局 = 0

// === Act 1 新增 ===

// Roguelike：seed 注入点（HTML 启动前可注入；为 0 则用默认 SEED）
VAR seed = 0

// 当前所在地点（位置追踪）
VAR 当前地点 = "loc_dorm_302"

// 物品背包（多值 LIST）
VAR 背包 = ()

// 已遭遇 NPC（用 list 集合）
LIST 已遇NPC列表 = enc_lujianqiao, enc_yaojunjie, enc_duanzhihao, enc_huyijia, enc_dumingcai
VAR 已遇NPC = ()

// 锚点 A 实际分配（运行时随机选）
VAR 锚点A_id = ""
VAR 锚点A_遭遇 = false

// 威胁时钟（gm_base.md 第三章）：每轮 +1，>=3 触发威胁事件
VAR 威胁钟 = 0
VAR 威胁事件触发次数 = 0

// 生态置信度（B 路线 7 步）
VAR 生态置信度 = 2  // 序章已经积累到第 2 步

// Act 1 关键标记
VAR 通风口_发现 = false
VAR 楼梯窗口_发现 = false
VAR Act1结束 = false
VAR Act1出口路径 = 0  // 1=H1通风 2=楼梯 3=fallback (储藏室格栅)
VAR 走廊3F_已访 = false
VAR 走廊4F_已访 = false

// 物品计数（简化：单数量）
VAR 急救包_数 = 0
VAR 绷带_数 = 0
