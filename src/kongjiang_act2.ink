// 控江隔离 · Act 2「探窟」· Ink Demo
// 第二天中午至傍晚。1F/2F 探索 + 锚点 B + 决定性生态线索 + 路人感染目击 + 嘴炮决策。
// 工具链：inklecate v1.2.0+ / Inky 0.15.1+

# theme: dark
# title: 控江隔离·Act 2 探窟
# author: trpg-bot

INCLUDE _data.ink
INCLUDE _helpers.ink
INCLUDE _helpers_act1.ink
INCLUDE act2_scenes.ink

// === Act 2 启动序列 ===

~ 应用seed()

// 推进 act_phase 至 2（解锁中期 flavor pockets）
~ 推进阶段(2)

// 随机分配 锚点 B NPC
~ temp 选中B = 随机取(锚点B候选)
{
- 选中B ? npc_huangxingshu:
    ~ 锚点B_id = "npc_huangxingshu"
- else:
    ~ 锚点B_id = "npc_zhangbaoxing"
}

// HTML 端可在故事启动前注入 Act 1 末状态（vars: 理智_昕/HP_昕/恐惧_志勇张怡/信任_志勇张怡/seed/...）

-> a2_序幕


// ============================================================
// Act 2 序幕
// ============================================================
=== a2_序幕 ===
# act:2
# scene:stairwell_a
# bgm:descent

二楼楼梯口。第二天中午前后。
你们刚下来。空气比 3 楼重——带潮、带甜。应急灯的红光把每个人的脸照得不像活人。
你贴墙喘气。志勇靠墙站，盯着楼梯下面通向 1 楼的铁门。砚波弯腰扶膝。张怡仰头看楼上："3 楼那个声音……还在追吗？"
没人回答。

+ [→]

- 走廊那头是宿管室——你们从 3 楼能听见，里面有钥匙。
张怡推了推不存在的眼镜："二楼宿管室。我们要进去。"
~ 切入解锁 = false
~ 回合数 = 0
~ 调查数 = 0
~ 威胁钟 = 0

+ [→] -> a2_走廊2F
