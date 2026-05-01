// Kongjiang Lockdown · Prologue (Act 0) + Horror Climax + Combat Tutorial · Ink Demo (English)
// Toolchain: inklecate v1.2.0 / Inky 0.15.1
// Encoding: UTF-8 no BOM

# theme: dark
# title: Kongjiang Lockdown · Prologue Demo
# author: trpg-bot

LIST CompanionStatus = calm, anxious, afraid
LIST AwarenessChain = aw_normal, aw_unease, aw_smell, aw_knock1, aw_knock2, aw_outside
LIST ForeshadowLevel = fs_none, fs_l1, fs_l2, fs_l3

VAR san_xin = 64
VAR hp_xin = 12

VAR fear_xin = 35
VAR fear_zhiyong = 20
VAR fear_zhangyi = 25
VAR trust_xin = 70
VAR trust_zhiyong = 60
VAR trust_zhangyi = 65

VAR status_xin = (calm)
VAR status_zhiyong = (calm)
VAR status_zhangyi = (calm)

VAR awareness = (aw_normal)
VAR foreshadow = (fs_none)

VAR round_count = 0
VAR investigation_count = 0
VAR cut_in_armed = false
VAR cut_in_path = 0

VAR last_roll = 0
VAR last_level = 0

VAR noodle_done = false
VAR knife_unlocked = false
VAR pepper_used = false
VAR enemy_hp = 8
VAR combat_round = 0
VAR combat_outcome = 0

INCLUDE _helpers_en.ink

~ SEED_RANDOM(2026)

-> prologue_start


// ============================================================
// Prologue entry
// ============================================================
=== prologue_start ===
# act:0
# scene:dorm_302
# bgm:quiet_dorm

April 2022. Shanghai. Kongjiang Road, Building 3, Room 302. The seventh evening of lockdown.
Iron sheets nailed over the windows. Through the seams a deep red searchlight bleeds in. The fluorescent lamp is dim. The air smells of expired instant noodles and sweat.
Xin and Yanbo sit on their respective lower bunks. Zhiyong leans against the wall, jiggling one leg. Zhangyi sits cross-legged on the makeshift mat, sorting through his backpack.
Today is no different from the last six days — not yet.
-> scene_dorm_evening


// ============================================================
// Dorm evening hub
// ============================================================
=== scene_dorm_evening ===
# scene:dorm_302
The room settles into silence. Each of them is waiting for the next sentence to appear.
-> choose_action

= choose_action
* Examine the column outside (Spot Hidden 80) -> look_window
* Inspect the dorm door (Spot Hidden 80) -> check_door
* Search deep in the closet (Spot Hidden 80) -> check_closet
* {not noodle_done} Tell Yanbo you want to cook noodles -> scene_noodle_contest
* Calm Xin down (Persuade 65) -> talk_xin
* Talk to Zhiyong -> talk_zhiyong
* Talk to Zhangyi -> talk_zhangyi
+ {cut_in_armed} Something is moving outside the door... -> scene_midnight_knock
+ Sit. Let time pass. -> idle_wait

= look_window
# speaker:player
~ tick_investigation()
~ tick_round()
You press up against the seam. The iron edge has rusted through; through it you can see the empty basketball court below, ringed by yellow caution tape.
~ temp ok = roll_skill(80)
# roll:Spot Hidden,80,{last_roll},{last_level}
[Spot Hidden 80 · d{last_roll} · {level_name()}]
{
- last_level == 0:
    You stare too long. Your vision blurs; when it sharpens again, the column is gone — but one of the white figures is looking up, at your window.
    ~ adjust_fear(fear_xin, status_xin, 10)
    ~ reach_awareness(aw_unease)
- ok:
    A column of figures in white hazmat suits is marching past — their cadence too uniform, too uniform to be human.
    ~ reach_awareness(aw_unease)
- else:
    Nothing visible — only a few white specks shifting in the distance.
}
-> choose_action

= check_door
# speaker:player
~ tick_investigation()
~ tick_round()
You step to the door. The door is cold — colder than usual. There is a thin film of moisture on the handle.
~ temp ok = roll_skill(80)
# roll:Spot Hidden,80,{last_roll},{last_level}
[Spot Hidden 80 · d{last_roll} · {level_name()}]
{
- last_level == 0:
    You lean too close. The tip of your nose almost touches the door. From the other side comes a faint, brief "huff" — an exhale. You jerk back.
    ~ adjust_fear(fear_xin, status_xin, 12)
    ~ reach_awareness(aw_unease)
- ok:
    A dark smear is seeping in beneath the door, the color of diluted soy sauce. You touch it with a fingertip — viscous, faintly sweet.
    ~ reach_awareness(aw_unease)
- else:
    The handle is cool. Nothing else seems wrong.
}
-> choose_action

= check_closet
# speaker:player
~ tick_investigation()
~ tick_round()
You crouch beside your bunk, in front of the small cabinet. At the very back is something that doesn't belong — something you bought freshman summer break and never told anyone about.
~ temp ok = roll_skill(80)
# roll:Spot Hidden,80,{last_roll},{last_level}
[Spot Hidden 80 · d{last_roll} · {level_name()}]
{
- last_level == 0:
    The cabinet door bangs against the wall. Zhiyong turns his head. "What the hell are you digging for?" In your panic you shove the thing back in.
    ~ adjust_fear(fear_zhiyong, status_zhiyong, 5)
- ok:
    A chef's knife, wrapped in oilpaper. And a small bag of pepper-and-Sichuan-pepper powder. You slip them under the bed where you can reach them in a hurry.
    ~ knife_unlocked = true
    (Inventory updated: chef knife / pepper powder.)
- else:
    A jumble of old textbooks and two pairs of stinking socks. None of what you came for.
}
-> choose_action

= talk_xin
# speaker:xin
~ tick_round()
Xin curls up at the head of his bed, twisting his fingers. "I... I think the building is especially quiet today... never mind, it's nothing."
~ temp ok = roll_skill(65)
# roll:Persuade,65,{last_roll},{last_level}
[Persuade 65 · d{last_roll} · {level_name()}]
{
- last_level == 0:
    "I'm fine, really, don't worry about me..." But his voice gets smaller and faster, until he is pressed flat against the wall.
    ~ adjust_fear(fear_xin, status_xin, 10)
- ok:
    You sit beside him and tell a stupid noodle joke. He laughs once. His shoulders drop.
    ~ adjust_fear(fear_xin, status_xin, -10)
    ~ adjust_trust(trust_xin, 10)
    # state:fear_xin-10
- else:
    You say "don't think about it too much." He nods, but his fingers grip each other tighter.
    ~ adjust_trust(trust_xin, 2)
}
-> choose_action

= talk_zhiyong
# speaker:zhiyong
~ tick_round()
Zhiyong clicks his tongue. "Tch. What's the holdup. If we were going to break out we'd have done it already. If we're going to lie around, then keep lying around." His leg pauses, then resumes its jiggling.
~ adjust_trust(trust_zhiyong, 3)
# state:trust_zhiyong+3
-> choose_action

= talk_zhangyi
# speaker:zhangyi
~ tick_round()
Zhangyi pushes up the bridge of nonexistent glasses. "I'm inclined to first list out everything we know for certain... wait. That sound just now — was it from upstairs?"
~ adjust_trust(trust_zhangyi, 3)
~ reach_awareness(aw_unease)
# state:trust_zhangyi+3
-> choose_action

= idle_wait
~ tick_round()
The room goes quiet again. Zhiyong shifts position and keeps jiggling. The searchlight sweeps across the iron sheet outside; the bright stripe crawls across the wall.
-> choose_action


// ============================================================
// Mini-goal · Noodle contest
// ============================================================
=== scene_noodle_contest ===
# scene:dorm_302
# speaker:yanbo
~ noodle_done = true
~ tick_round()

Yanbo sees it first. The last cup of pickled-cabbage instant noodles, wedged at the back of the snack shelf — the very last cup of lockdown day seven. He reaches in and clutches it to his chest.
"This is mine," he says, completely serious.
Zhiyong clicks his tongue. "Come on, who was the one who said he wasn't hungry just now?"
Zhangyi straightens. "I'm inclined to settle this by drawing lots."
Xin, quietly: "What about... we split it four ways and cook it together? I mean, just in case..."

* [Side with drawing lots]
    ~ adjust_trust(trust_zhangyi, 5)
    The lot falls to Zhangyi. Yanbo grumbles and surrenders the noodles, but Zhangyi pushes them back into the pot. "Four-way split."
* [Side with sharing]
    ~ adjust_trust(trust_xin, 5)
    Xin exhales. Zhiyong, cursing under his breath, takes over the cooking.
* [Let Yanbo have it]
    ~ adjust_fear(fear_xin, status_xin, 5)
    Yanbo carries the noodles smugly to his desk. Xin stares at the empty pot, says nothing.

- The water boils. Steam rises and merges with the dim yellow of the fluorescent light.
~ advance_foreshadow()
~ reach_awareness(aw_smell)

{
- foreshadow ? fs_l1:
    A strange sweet-rotten note drifts up through the steam — must be the seasoning packet getting damp.
- foreshadow ? fs_l2:
    The corridor light at the far end dips by a fraction, as if for a single beat, then steadies.
- foreshadow ? fs_l3:
    Rummaging in the shelf, your fingers brush a slip of paper that wasn't there before. Scrawled across it: "Don't open the door."
}

-> scene_dorm_evening


// ============================================================
// Mini-goal · Midnight knock
// ============================================================
=== scene_midnight_knock ===
# scene:dorm_302
# sfx:knock_3x
~ tick_round()
~ reach_awareness(aw_knock1)

At some point — none of you noticed when — everyone has stopped moving.
From outside the door, three knocks. Even, steady. Knock — knock — knock.
Then the pause.
The blood drains from Xin's face; he presses against the wall. Zhiyong stands up but does not move. Zhangyi, low: "Wait —"

* [Call out: "Who's there?"]
    ~ adjust_fear(fear_xin, status_xin, 10)
    # state:fear_xin+10
    Your voice rings off the walls. From the other side of the door, no answer.
* Hold your breath and listen (Listen 65)
    ~ temp heard = roll_skill(65)
    # roll:Listen,65,{last_roll},{last_level}
    [Listen 65 · d{last_roll} · {level_name()}]
    {
    - heard:
        There is breathing on the other side — slow, wet, pulsing in a rhythm that does not belong to anything alive.
        ~ reach_awareness(aw_outside)
    - else:
        On the other side, absolute silence. A silence too clean to be real.
    }
* [Send Zhiyong to check]
    Zhiyong scoffs. "Fine, I'll look." He walks to the door, presses his ear against it — and then, immediately, steps back. He says nothing.
    ~ adjust_fear(fear_zhiyong, status_zhiyong, 8)
    # state:fear_zhiyong+8

- Three more knocks. Knock — knock — knock.
~ reach_awareness(aw_knock2)
~ advance_foreshadow()
This time, after the third knock, no fourth comes. But the breathing on the other side does not move away.

* [Open the door]
    ~ cut_in_path = 1
    -> horror_climax
* [Don't open. Back away.]
    ~ cut_in_path = 2
    -> horror_climax
* [Try to call the dorm-mom]
    ~ cut_in_path = 3
    -> horror_climax


// ============================================================
// Horror climax (3 beats + SAN -3 reveal)
// ============================================================
=== horror_climax ===
# act:1
# scene:dorm_302
# bgm:cut_in_horror

{
- cut_in_path == 1:
    Your fingers haven't yet touched the handle — the door pushes itself open.
- cut_in_path == 2:
    You've just backed against the wall — and the handle begins to turn on its own.
- cut_in_path == 3:
    The signal hasn't connected — the door is already opening.
}

-> beat_one

= beat_one
The room goes uncannily silent. The fluorescent lamp's hum is twice as loud as before.
You can hear your own heartbeat — but it's wrong. The intervals are wrong.
As if something is squeezing in half-beats, between the gaps of your pulse.

+ [→] -> beat_two

= beat_two
The door opens a third of the way and stops. From that gap —
The temperature comes first: cold and damp, like pressing your face against meat that's been left in a basement for three days.
Then the smell: what was sweet-rot through the door now floods straight up your nose — a live sweetness, like mushrooms rotting on day seven.
Xin can no longer speak. Zhangyi's fingers grip the desk edge.

+ [→] -> beat_three

= beat_three
It is wearing a filthy white hazmat suit.
But you realize — that isn't being worn. The hazmat suit is part of its body.
It's tall, taller than Zhiyong, bent forward to fit through the doorframe. Its face — it has no face. Beneath the mask is a clump of grey, fuzzed-over flesh; the fuzz is rising and falling slowly, as if breathing.
You look down so as not to see it, but your gaze catches its feet — its shoes are empty. Inside each boot is only a milky-white, mushroom-stalk-like thing holding it upright.
~ adjust_san(san_xin, -3)
~ reach_awareness(aw_outside)
# state:san_xin-3

Sanity -3.

+ [→] -> combat_loop


// ============================================================
// Combat loop (max 3 rounds)
// ============================================================
=== combat_loop ===
~ combat_round = combat_round + 1

{ hp_xin <= 0:
    -> combat_resolve.knockdown
}
{ enemy_hp <= 0:
    -> combat_resolve.victory
}
{ combat_round > 3:
    -> combat_resolve.timeout
}

# scene:dorm_302
{
- combat_round == 1:
    Zhiyong grabs one dumbbell and steps in front of you. "Look at me. Look at me!"
- combat_round == 2:
    Zhangyi shrinks behind the desk. Yanbo crouches and feels for something. Its lower body is still wedged in the doorframe — it isn't all the way in yet.
- combat_round == 3:
    Xin's breathing is faster. One more lunge and your line breaks.
}

It lunges. The smell is sweet, and damp.

+ {knife_unlocked} Slash with the chef knife (Fighting 45) -> attack_knife
+ {not knife_unlocked} Strike bare-handed (Fighting 45) -> attack_fist
* {not pepper_used && knife_unlocked} Throw the pepper powder (Throw 50) -> attack_pepper
+ Side-step against the wall (Luck 75) -> dodge
+ Bolt for the door (Luck 75) -> flee

= attack_knife
# speaker:player
~ temp hit = roll_skill(45)
# roll:Fighting,45,{last_roll},{last_level}
[Fighting (Brawl) 45 · d{last_roll} · {level_name()}]
{
- last_level == 0:
    The knife flies from your grip and hits the wall. It seizes your forearm — fingers sink into your skin.
    ~ adjust_hp(hp_xin, -3)
- hit:
    ~ temp dmg = RANDOM(2, 7)
    The blade cuts across its shoulder; grey-green fluid spurts. The smell deepens.
    ~ enemy_hp = enemy_hp - dmg
- else:
    The knife passes through air. It is faster than you expected.
    ~ adjust_hp(hp_xin, -2)
}
-> combat_loop

= attack_fist
# speaker:player
~ temp hit = roll_skill(45)
# roll:Fighting,45,{last_roll},{last_level}
[Fighting (Brawl) 45 · d{last_roll} · {level_name()}]
{
- last_level == 0:
    Your fist sinks into the fleshy mass beneath the mask — and sticks. You can't pull it free.
    ~ adjust_hp(hp_xin, -4)
    ~ adjust_san(san_xin, -2)
    # state:san_xin-2
- hit:
    ~ temp dmg = RANDOM(1, 3)
    You hit its chest. It steps back half a pace — but your wrist is wrenched.
    ~ enemy_hp = enemy_hp - dmg
- else:
    It does not move. It seems to have no concept of "being hit".
    ~ adjust_hp(hp_xin, -2)
}
-> combat_loop

= attack_pepper
# speaker:player
~ pepper_used = true
~ temp hit = roll_skill(50)
# roll:Throw,50,{last_roll},{last_level}
[Throw 50 · d{last_roll} · {level_name()}]
{
- hit:
    Pepper powder coats its face — but it has no eyes. It pauses for half a second; spores in the fuzz are scattered.
    ~ enemy_hp = enemy_hp - 2
    It steps back. Zhiyong slams it with a dumbbell.
    ~ enemy_hp = enemy_hp - 2
- else:
    The powder scatters wide. It steps closer.
    ~ adjust_hp(hp_xin, -1)
}
-> combat_loop

= dodge
# speaker:player
~ temp dodged = roll_skill(75)
# roll:Luck,75,{last_roll},{last_level}
[Luck 75 · d{last_roll} · {level_name()}]
{
- last_level >= 4:
    You slip past, against the wall. It misses, crashes into the desk. Yanbo seizes the moment, brings a dumbbell down on its lower back.
    ~ enemy_hp = enemy_hp - 3
- dodged:
    You twist aside; it crashes into the desk.
- else:
    You're half a beat slow. Its fingertip grazes the side of your face — a burning, vinegar-soaked-wound pain.
    ~ adjust_hp(hp_xin, -3)
    ~ adjust_san(san_xin, -2)
    # state:san_xin-2
}
-> combat_loop

= flee
# speaker:player
~ temp got_out = roll_skill(75)
# roll:Luck,75,{last_roll},{last_level}
[Luck 75 · d{last_roll} · {level_name()}]
{
- last_level >= 4:
    You yank Xin up; Zhiyong shoves Yanbo, Zhangyi follows — the four of you push past it into the corridor.
    ~ combat_outcome = 4
    -> combat_resolve.escape
- got_out:
    You make it to the doorway — but Zhiyong falls behind. It turns toward Zhiyong.
    ~ adjust_fear(fear_zhiyong, status_zhiyong, 30)
- else:
    It blocks the door. You're flung back against the desk.
    ~ adjust_hp(hp_xin, -2)
}
-> combat_loop


// ============================================================
// Combat resolve
// ============================================================
=== combat_resolve ===
# scene:dorm_302
-> victory

= victory
~ combat_outcome = 1
It makes a sound that isn't a sound, curls into the corner, and slowly, slowly retreats from the doorway.
The footsteps that aren't footsteps fade. You collapse to the floor. Zhiyong is still gripping the dumbbell. His arm is shaking.
-> finale

= knockdown
~ combat_outcome = 3
Your vision blacks out.
When you open your eyes, Zhiyong is pressing your shoulder. "You're up. You're up." His voice is hoarse.
Daylight. The doorway is empty. It's gone.
~ hp_xin = 1
~ adjust_san(san_xin, -2)
# state:san_xin-2
-> finale

= timeout
~ combat_outcome = 2
It does not advance. It just stands at the doorway and looks at you — and you don't know what it's looking at, because it has no eyes.
Then it turns and leaves. The door hangs half-open. From deeper in the corridor comes another set of footsteps — same gait, but heavier than this one.
-> finale

= escape
~ combat_outcome = 4
You push past it, into the corridor.
Zhiyong drags Xin up; Zhangyi follows last; Yanbo runs ahead, calls back:
"The stairs — the stairs are still open —"
-> finale


// ============================================================
// Finale
// ============================================================
=== finale ===
{ awareness ? aw_smell:
    The sweet-rotten smell is denser now. It is coming from something alive, growing from inside this building.
}
{ awareness ? aw_outside:
    What you saw was no illusion. It exists. It will come back.
}
{
- combat_outcome == 1:
    You drove it back. But the footsteps deeper in the corridor tell you this was only the first.
- combat_outcome == 2:
    It is gone. But it is waiting.
- combat_outcome == 3:
    You blacked out. When you woke, the building was even quieter than before.
- combat_outcome == 4:
    You escaped 302. But nothing in this building is safer than here.
}

— End of Prologue — # CLASS:end
Act 1 "The Cage" begins. # CLASS:end
-> END
