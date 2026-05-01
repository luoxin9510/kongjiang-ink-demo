// _helpers_en.ink — state / check / foreshadow / combat helpers (English)
// Mirror of _helpers.ink

=== function set_status(ref s, new_state)
    ~ s -= LIST_ALL(s)
    ~ s += new_state

=== function adjust_fear(ref f, ref s, delta)
    ~ f = f + delta
    { f > 100:
        ~ f = 100
    }
    { f < 0:
        ~ f = 0
    }
    { f >= 50 && (s ? calm):
        ~ s -= LIST_ALL(s)
        ~ s += anxious
    }

=== function adjust_trust(ref t, delta)
    ~ t = t + delta
    { t > 100:
        ~ t = 100
    }
    { t < 0:
        ~ t = 0
    }

=== function adjust_san(ref s, delta)
    ~ s = s + delta
    { s < 0:
        ~ s = 0
    }

=== function adjust_hp(ref h, delta)
    ~ h = h + delta
    { h < 0:
        ~ h = 0
    }

=== function fear_decay_all()
    ~ adjust_fear(fear_xin, status_xin, -2)
    ~ adjust_fear(fear_zhiyong, status_zhiyong, -2)
    ~ adjust_fear(fear_zhangyi, status_zhangyi, -2)

=== function reach_awareness(target)
    ~ awareness += LIST_RANGE(LIST_ALL(target), LIST_MIN(LIST_ALL(target)), target)

=== function advance_foreshadow()
    {
    - foreshadow ? fs_none:
        ~ foreshadow -= fs_none
        ~ foreshadow += fs_l1
    - foreshadow ? fs_l1:
        ~ foreshadow -= fs_l1
        ~ foreshadow += fs_l2
    - foreshadow ? fs_l2:
        ~ foreshadow -= fs_l2
        ~ foreshadow += fs_l3
    }

=== function roll_skill(skill_value)
    ~ last_roll = RANDOM(1, 100)
    {
    - last_roll == 1:
        ~ last_level = 5
    - last_roll <= skill_value / 5:
        ~ last_level = 4
    - last_roll <= skill_value / 2:
        ~ last_level = 3
    - last_roll <= skill_value:
        ~ last_level = 2
    - skill_value < 50 && last_roll >= 96:
        ~ last_level = 0
    - last_roll == 100:
        ~ last_level = 0
    - else:
        ~ last_level = 1
    }
    ~ return last_level >= 2

=== function level_name()
    {
    - last_level == 0:
        Fumble!
    - last_level == 1:
        Fail
    - last_level == 2:
        Success
    - last_level == 3:
        Hard Success
    - last_level == 4:
        Extreme Success
    - last_level == 5:
        Critical!
    }

=== function tick_round()
    ~ round_count = round_count + 1
    ~ fear_decay_all()
    { (investigation_count >= 3 || round_count >= 5) && cut_in_armed == false:
        ~ cut_in_armed = true
    }

=== function tick_investigation()
    ~ investigation_count = investigation_count + 1
    { (investigation_count >= 3 || round_count >= 5) && cut_in_armed == false:
        ~ cut_in_armed = true
    }
