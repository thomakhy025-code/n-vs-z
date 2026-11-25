class_name Tr
extends RefCounted

const CJK_FONT: Font = preload("res://fonts/NotoSansTC-Regular.otf")

static var lang: String = "en"
static var _installed: bool = false
static var _cache: Dictionary = {}
static var _pat_rx: Array[RegEx] = []
static var _pat_zh: PackedStringArray = PackedStringArray()
static var _built: bool = false

const MAP := {
	"Sword Soldier": "劍士",
	"Sword": "劍",
	"Archer": "弓箭手",
	"Shield-Bearer": "盾衛",
	"Shield": "盾",
	"Saber": "彎刀",
	"Lancer": "槍兵",
	"Berserker": "狂戰士",
	"Berserk": "狂戰",
	"Horse Rider": "騎手",
	"Rider": "騎",
	"Horse": "馬",
	"Suicide Squad": "爆彈隊",
	"Bomb": "爆彈",
	"Assassin": "刺客",
	"Healing Caster": "治療術士",
	"Heal": "治療",
	"Leveling Caster": "升級術士",
	"Level": "升級術",
	"War Boss": "戰將",
	"Walker": "行者",
	"Runner": "奔者",
	"Howler": "嚎者",
	"Viper": "蝮",
	"Storm": "雷暴",
	"Herald": "號手",
	"Shell": "厚殼",
	"Reaver": "掠者",
	"Oni": "鬼",
	"Moth": "蛾",
	"Elder": "老者",
	"Glut": "饕",
	"Brood": "巢",
	"Ling": "幼",
	"Knives": "短刃",
	"Firebow": "火弓",
	"Fan": "扇",
	"Ward": "大盾",
	"Javelin": "投槍",
	"Drum": "鼓",
	"Crow": "鴉",
	"Cow": "牛",
	"Smog": "煙",
	"Buck": "霰",
	"Scope": "瞄",
	"Aria": "詠",
	"Bomber": "爆者",
	"General": "將軍",
	"Hits one enemy at short range for 20 every second.": "近距離每秒對一名敵人造成 20 傷害。",
	"Shoots one enemy from long range for 40 every second.": "從遠處每秒對一名敵人射出 40 傷害。",
	"A thick gate of armor. 200 blood, 15 damage, short reach, one target.": "一道厚厚的甲門。200 血，15 傷害，近距離，一個目標。",
	"Slow to call. Cuts one enemy for 50 every second.": "召喚得慢。每秒對一名敵人斬下 50。",
	"The spear reaches mid range and hits one enemy for 20 every second.": "槍伸到中距離，每秒打中一名敵人 20。",
	"Rushes in from mid distance and stands across all three roads. Every 3 seconds, every enemy in short range on every road takes 80. Enemies on every road can strike back.": "從中距離衝入，橫站在三條路上。每 3 秒，每一條路上近距離內的每個敵人受到 80。每一條路上的敵人都能反擊。",
	"Fast. Hits one enemy for 30 every second.": "很快。每秒打中一名敵人 30。",
	"Rushes from mid distance. The blast hits everyone in short range for 100, and 40 of that blood is their own.": "從中距離衝來。爆炸對近距離內的每個人造成 100，其中 40 血是他們自己的。",
	"She blinks past every other enemy, as many times as she needs, and crosses roads to reach her mark. She only kills an archer, a leveling caster, or a healing caster. The cut is 50.": "她按需要的次數閃過其他每一個敵人，並跨路去到她的目標。她只殺弓手、升級術士或治療術士。那一刀是 50。",
	"Heals the ally in front of her with the least blood, 40 blood each second, at long range.": "每秒治療她前面血最少的盟友 40 血，距離很遠。",
	"The ally in front with the highest damage gains 20% damage and 20% blood. A second caster can add another 20%. The same caster does not stack twice.": "前面傷害最高的盟友得到 20% 傷害和 20% 血。第二名術士可以再加 20%。同一名術士不會疊兩次。",
	"Black hood, silver bands, and a silver sword.": "黑兜帽，銀環，一把銀劍。",
	"Green scarf, green eyes, bow, and a quiver.": "綠圍巾，綠眼睛，弓，和一個箭袋。",
	"Brown coat and a round gold shield.": "棕外套，一面圓的金盾。",
	"Black hood, red scarf, and a dark curved sword.": "黑兜帽，紅圍巾，一把暗色彎劍。",
	"Blue hood and a blue spear.": "藍兜帽，一桿藍槍。",
	"Red armor, bare arms, and a gold axe.": "紅甲，露臂，一把金斧。",
	"Black rider, red saddle, and a gold sword.": "黑騎手，紅鞍，一把金劍。",
	"Black hood, red sash, and a lit bomb.": "黑兜帽，紅腰帶，一顆點著的爆彈。",
	"Purple hood and a purple dagger.": "紫兜帽，一把紫短刃。",
	"White robe and a teal crystal staff.": "白袍，一柄青水晶法杖。",
	"Gold hood and an open scroll.": "金兜帽，一卷打開的卷軸。",
	"White hood, red scarf, and a silver sword.": "白兜帽，紅圍巾，一把銀劍。",
	"Walker. It strikes one fighter at short range.": "行者。它在近距離打一名戰士。",
	"Runner. It is faster than a walker, and it strikes sooner.": "奔者。它比行者更快，也更早出手。",
	"Herald. It calls two other monsters every few seconds.": "號手。它每隔幾秒召喚兩隻其他怪物。",
	"Viper. Its bite holds a fighter. For a short time they cannot move or attack, and they hold the hurt pose until it ends.": "蝮。它的咬困住一名戰士。有一小段時間他們不能移動或攻擊，並保持受傷的姿勢，直到結束。",
	"Shell. It is slow, hits softly, and carries a great deal of blood.": "厚殼。它很慢，打得很輕，帶著很多血。",
	"Howler. A short blade cannot reach it. It swings onto an archer or a caster, and an archer can shoot it.": "嚎者。短刃夠不到它。它盪向弓手或術士，弓手可以射它。",
	"Reaver. It hits harder, and it strikes one fighter.": "掠者。它打得更重，打一名戰士。",
	"Storm. Lightning hits one fighter, then jumps to four others, one by one.": "雷暴。閃電打中一名戰士，然後一個一個跳到另外四個身上。",
	"Oni. A heavy blow hits everyone in range on its road.": "鬼。沉重的一擊打中它那條路上範圍內的每個人。",
	"Moth. It flies on one road. A short blade cannot reach it.": "蛾。它在一條路上飛。短刃夠不到它。",
	"Elder. It appears on the road, strikes whoever is nearest, and then it fades.": "老者。它出現在路上，打最近的人，然後消失。",
	"Glut. It eats the fighter in front, then sits and heals.": "饕。它吃掉前面的戰士，然後坐下並治療。",
	"Brood. It bites one fighter. When it dies, three Lings crawl out.": "巢。它咬一名戰士。它死去時，三隻幼爬出來。",
	"Ling. A small fast biter that crawls out of Brood.": "幼。從巢裡爬出的小而快的咬者。",
	"Knives. It matches the sword soldier, and it strikes one fighter at short range.": "短刃。它對應劍士，在近距離打一名戰士。",
	"Firebow. A hard shot, then fire stays on that spot.": "火弓。一記重射，然後火留在那個位置。",
	"Fan. It blows its road and pushes the fighters in front back.": "扇。它吹自己的路，把前面的戰士往後推。",
	"Ward. A great shield, and a great deal of blood.": "大盾。一面大盾，很多血。",
	"Javelin. It throws long shots, then fights up close.": "投槍。它丟出遠射，然後近身打。",
	"Drum. It deals no damage. It lifts three allies at once.": "鼓。它不造成傷害。它一次抬起三名盟友。",
	"Crow. It waits, then the first strike is heavy. After that it fights up close.": "鴉。它等候，然後第一擊很重。之後它近身打。",
	"Cow. It waits, then it charges. After that it fights up close, slower than the crow.": "牛。它等候，然後衝鋒。之後它近身打，比鴉更慢。",
	"Smog. It deals no damage. Smoke hides the road where it walks.": "煙。它不造成傷害。煙霧藏起它走過的路。",
	"Buck. It fires a shotgun, then it reloads.": "霰。它開霰彈槍，然後裝填。",
	"Scope. One long heavy shot, and it has little blood.": "瞄。一發長而重的槍，血很少。",
	"Aria. The song lifts every ally on every road.": "詠。歌聲提升每一條路上的每一個盟友。",
	"Bomber. It is fragile, and the hit is heavy.": "爆者。它很脆，一擊很重。",
	"General. It walks out when the gate breaks. The level ends when the general dies.": "將軍。城門破時它走出來。將軍死去，這一關就結束。",
	"Walks one road and strikes one fighter at short range.": "走一條路，在近距離打一名戰士。",
	"Faster than a walker, and the next blow comes sooner.": "比行者更快，下一擊也來得更早。",
	"The bite holds one fighter still for 2 seconds. For a short time they cannot move or attack, and they hold the hurt pose until it ends. A healing caster can clear it. If two fighters are in front, it bites the one who hits harder and does not hold them. Most blows miss the viper.": "這一咬讓一名戰士停住 2 秒。有一小段時間他們不能移動或攻擊，並保持受傷的姿勢，直到結束。治療術士可以解除。如果前面有兩名戰士，它咬打得較重的那一個，並不困住他們。大多數攻擊打不中蝮。",
	"Waits, then lightning hits the fighter in front and jumps to four others, one by one. For a short time they cannot move or attack, and they hold the hurt pose until it ends.": "它等候，然後閃電打中前面的戰士，再一個一個跳到另外四個身上。有一小段時間他們不能移動或攻擊，並保持受傷的姿勢，直到結束。",
	"Calls two other monsters every few seconds. Those calls pay no value when they fall.": "每隔幾秒召喚兩隻其他怪物。那些召喚倒下時不給價值。",
	"Slow, hits softly, and carries a great deal of blood.": "很慢，打得很輕，帶著很多血。",
	"A harder hitter for a moderate call. One target.": "中等召喚裡打得較重。一個目標。",
	"A heavy blow that hits everyone in range on its road. Slow, and very hard to bring down.": "沉重的一擊打中它那條路上範圍內的每個人。很慢，也很難打倒。",
	"Flies on one road. A short weapon cannot hit it, and those fighters stop beneath it, though they still fight a closer fighter on the ground.": "在一條路上飛。短兵器打不到它，那些戰士停在它下面，不過他們仍會打地面上更近的戰士。",
	"Appears somewhere on the road, strikes whoever is nearest, friend or foe, and fades after 15 seconds. Many blows miss Elder.": "出現在路上某處，打最近的人，無論友敵，15 秒後消失。許多攻擊打不中老者。",
	"Bites one fighter. When it dies, three quick Lings crawl out.": "咬一名戰士。它死去時，三隻快的幼爬出來。",
	"A small fast biter that crawls out of Brood. It does not split again.": "從巢裡爬出的小而快的咬者。它不會再分裂。",
	"Matches the sword soldier. One target, at short range.": "對應劍士。一個目標，近距離。",
	"Fragile. The hit is heavy, and it strikes the berserker when one is alive.": "很脆。一擊很重，若有狂戰士活著就打狂戰士。",
	"A great shield and a great deal of blood. The hit stays at 5.": "一面大盾，很多血。傷害停在 5。",
	"Deals no damage. It lifts three allies at once, the way a leveling caster lifts one.": "不造成傷害。它一次抬起三名盟友，就像升級術士抬起一個。",
	"Deals no damage. Smoke follows where it walks and hides that stretch for 10 seconds.": "不造成傷害。煙跟著它走，把那一段藏起 10 秒。",
	"Fires a shotgun once a second, four times, then reloads for 2 seconds. The shot reaches 100.": "每秒開一槍，四次，然後裝填 2 秒。這一槍達到 100。",
	"Fires one long heavy shot every 3 seconds, and has little blood.": "每 3 秒開一發長而重的槍，血很少。",
	"Deals no damage. The song lifts every ally on every road at once, at half the strength of a leveling caster. A second song does not stack.": "不造成傷害。歌聲一次提升每一條路上的每一個盟友，強度是升級術士的一半。第二首歌不會疊加。",
	"Strikes one fighter on its own road.": "在自己的路上打一名戰士。",
	"Nine of these walk out when the gate breaks, three on each road. Kill all nine and this call is yours. The numbers above are what those nine have.": "城門破時，九個走出來，每條路三個。殺掉全部九個，這個召喚就是你的。上面的數字是那九個的數值。",
	"Walks out when the gate breaks. The level ends when this one dies.": "城門破時走出來。這一個死去，這一關就結束。",
	"First road": "第一條路",
	"The spears": "那些槍",
	"Still they come": "他們仍來",
	"The shield wall": "盾牆",
	"Thick mist": "濃霧",
	"The ridge": "山脊",
	"The riders": "騎手們",
	"Two at once": "一次兩條",
	"The blink": "閃現",
	"Night watch": "夜哨",
	"A fast one": "一個快的",
	"The long cut": "長斬",
	"Cold stone": "冷石",
	"The blast": "爆炸",
	"Shut gate": "閉門",
	"The staff": "法杖",
	"White cloud": "白雲",
	"The scroll": "卷軸",
	"Last lull": "最後的間歇",
	"The axe": "那把斧",
	"Banners": "旗幟",
	"The lower road": "下路",
	"Red sashes": "紅腰帶",
	"Shield line": "盾列",
	"The drum": "鼓",
	"Uphill": "上坡",
	"Crossbows": "弩",
	"The gate they want": "他們要的城門",
	"Heavy boots": "重靴",
	"Halfway": "一半",
	"Night banners": "夜旗",
	"Paired ranks": "成對的隊列",
	"Iron": "鐵",
	"The push": "推進",
	"Broken steps": "斷階",
	"Their purse": "他們的錢袋",
	"Close ranks": "收攏隊列",
	"The horn": "號角",
	"Last banner": "最後的旗",
	"The general": "將軍",
	"They return": "他們回來",
	"Same horns": "同樣的角",
	"The same hour": "同一個時辰",
	"No scatter": "沒有潰散",
	"Who sent them": "誰派他們來",
	"A maker": "一個製造者",
	"Ash on the road": "路上的灰",
	"Counted out": "點過數",
	"The guess": "那個猜測",
	"Halfway back": "回來的一半",
	"No chain": "沒有鎖鏈",
	"Still the soldiers": "仍是那些士兵",
	"Three roads": "三條路",
	"A workshop": "一座工坊",
	"A person could": "人也能",
	"Buried horns": "埋掉的角",
	"Send and break": "派來與打破",
	"No new soldier": "沒有新兵",
	"Tired of guessing": "厭倦猜測",
	"Long enough": "夠久了",
	"The old road": "舊路",
	"Soldiers on the path": "路上的士兵",
	"Horns again": "角又來了",
	"Red on the road": "路上的紅",
	"The descent": "下行",
	"A human gate": "人的城門",
	"Monsters below": "下方的怪物",
	"The last sash": "最後的腰帶",
	"Above the village": "村子之上",
	"The two armies": "兩支軍隊",
	"Break their gate. Nine come out, three on each road. Kill them all.": "打破他們的城門。九個走出來，每條路三個。全部殺掉。",
	"Break their gate. A general walks out. The level ends when the general dies.": "打破他們的城門。一名將軍走出來。將軍死去，這一關就結束。",
	"On the road to the village where they were born.": "在通往他們出生的村子的路上。",
	"Monsters again. The clan still thinks the soldiers made them.": "又是怪物。一族仍然認為是士兵造了他們。",
	"Human soldiers on the mountain road.": "人類士兵在山路上。",
	"Monsters on the three roads. Hold the clan gate.": "怪物在三條路上。守住一族的城門。",
	"The monsters do not leave. The sword is still the only call.": "怪物沒有離開。劍仍是唯一的召喚。",
	"Mist on the ridge. There are more of them than yesterday.": "山脊上有霧。他們比昨天更多。",
	"They hold the gate. No new weapon today.": "他們守著城門。今天沒有新的兵器。",
	"Two roads fill at once. The clan does not break.": "兩條路同時湧滿。一族沒有潰散。",
	"Night on the mountain. The horns keep coming.": "山上的夜。角一直湧來。",
	"A fast one slips through. The hero runs it down.": "一個快的溜了過去。英雄追上去了結它。",
	"Cold stone, and another wave.": "冷石，又一波。",
	"The gate holds. They learn nothing new.": "城門守住了。他們沒有學到新的東西。",
	"White cloud hides the road. The shapes still find it.": "白雲遮住了路。那些形影還是找得到。",
	"A last quiet between the blows. Then they come again.": "打擊之間最後的安靜。然後他們又來了。",
	"The new monsters keep rank. The clan says a human hand sent them.": "新的怪物保持隊列。一族說，是一隻人的手派他們來的。",
	"They arrive at the same hour the soldiers once did.": "他們在士兵從前抵達的同一個時辰到來。",
	"Wild things do not wait for a drum. These do.": "野獸不等鼓聲。這些會等。",
	"The clan looks at the horns and still sees a maker.": "一族看著那些角，仍看見一個製造者。",
	"No scatter, no hunger. They come to the gate and stop.": "沒有潰散，沒有飢餓。他們來到城門前就停下。",
	"Ash on the road, and the same number as yesterday.": "路上有灰，數目和昨天一樣。",
	"Someone is counting them out.": "有人在點著他們的數目。",
	"The mountain asks who. The clan answers: the soldiers.": "山問是誰。一族回答：那些士兵。",
	"Half of these attacks are done. The guess has not changed.": "這些攻擊過了一半。猜測沒有變。",
	"They hold a broken horn up to the light and see no chain.": "他們把一隻斷角舉到光裡，看不見鎖鏈。",
	"Still they say the soldiers built these bodies.": "他們仍然說，是士兵造了這些身體。",
	"A quiet hour, then the same three roads.": "安靜了一個時辰，然後還是同樣的三條路。",
	"The gate shakes. They talk of a workshop in the low country.": "城門在震。他們說起低地裡的一座工坊。",
	"If a person can call a sword, a person could call a monster.": "人若能召喚一把劍，人也就能召喚一隻怪物。",
	"They bury the dead horns away from the huts.": "他們把死掉的角埋到屋舍遠處。",
	"The pattern holds. Send, break, send.": "這個樣子一直如此。派來，打破，再派來。",
	"No new soldier walks out of these gates. Only the same beasts.": "沒有新的士兵從這些門裡走出來。只有同樣的野獸。",
	"One more night of horns. The clan is tired of guessing.": "又是一夜的角。一族厭倦了猜測。",
	"They have lived with the guess long enough.": "他們帶著這個猜測活得夠久了。",
	"The gate breaks. Nine archers step out, three on each road.": "城門破了。九名弓手走出來，每條路三個。",
	"The clan lives through the arrows.": "一族從箭下活了下來。",
	"They pick up the bows and learn the shot.": "他們拾起弓，學會了射擊。",
	"Nine lancers come off the broken gate, three on each road.": "九名槍兵從破門裡出來，每條路三個。",
	"The spears stop short of the clan.": "那些槍停在一族之前。",
	"They take the spear and learn its reach.": "他們拿起槍，學會它的距離。",
	"Nine shield-bearers plant themselves, three on each road.": "九名盾衛立定，每條路三個。",
	"The wall holds, and then it breaks.": "那道牆守住了，然後破了。",
	"They lift the shields and learn to stand.": "他們舉起盾，學會站住。",
	"Nine riders pour out, three on each road.": "九名騎手湧出，每條路三個。",
	"The clan meets the charge and stays.": "一族迎上衝鋒，留了下來。",
	"They take the horses and learn the speed.": "他們牽過馬，學會那速度。",
	"Nine assassins slip out, three on each road.": "九名刺客溜出，每條路三個。",
	"One blinks behind the line. The clan turns in time.": "一個閃到隊列後面。一族及時轉身。",
	"They learn the blink, and the cut that follows.": "他們學會閃現，以及隨後的那一刀。",
	"Nine sabers walk out, three on each road.": "九把彎刀走出來，每條路三個。",
	"The long cuts are slow, and the clan answers them.": "那些長斬很慢，一族回應了它們。",
	"They take up the long blade.": "他們拿起長刃。",
	"Nine bombers rush out, three on each road.": "九名爆者衝出，每條路三個。",
	"The blasts take blood from both sides. The clan remains.": "爆炸取走兩邊的血。一族還在。",
	"They learn the bomb, and what it costs.": "他們學會爆彈，以及它的代價。",
	"Nine healing casters step out, three on each road.": "九名治療術士走出來，每條路三個。",
	"They mend the monsters. The clan cuts them down anyway.": "他們修補怪物。一族還是砍倒了他們。",
	"They learn the staff, and how to give blood back.": "他們學會法杖，以及如何把血還回去。",
	"Nine leveling casters come out, three on each road.": "九名升級術士出來，每條路三個。",
	"The monsters grow stronger beside them. The clan ends it.": "怪物在他們身旁變強。一族了結了這一切。",
	"They learn the scroll, and how to raise one of their own.": "他們學會卷軸，以及如何抬起自己人裡的一個。",
	"Nine axe fighters come out, three on each road.": "九名斧士出來，每條路三個。",
	"They are heavy, and they fall one road at a time.": "他們很重，一條路一條路地倒下。",
	"The clan learns the axe. One berserker will stand across all three roads.": "一族學會了斧。一名狂戰士將橫站在三條路上。",
	"They were small, and the village was not kind.": "他們很小，而村子並不仁慈。",
	"Get out.": "出去。",
	"There was no place for them there.": "那裡沒有他們的地方。",
	"Leave.": "離開。",
	"They took the thin road into the cloud.": "他們走上那條細路，進入雲裡。",
	"The mountain did not know their names. That was enough.": "山不知道他們的名字。這就夠了。",
	"For a while, the wind was the only visitor.": "有一陣子，風是唯一的來客。",
	"Then shapes came up the lower road.": "然後形影從下路走上來。",
	"We only know this.": "我們只知道這些。",
	"The sword.": "那把劍。",
	"The mountain learned their names too.": "山也學會了他們的名字。",
	"Months pass. The monsters stop coming.": "幾個月過去。怪物不再來。",
	"Other clans have heard of the mountain. One ninja can meet one ninja.": "別的一族聽說過這座山。一個忍者可以遇見一個忍者。",
	"Then banners show on the lower road.": "然後旗幟出現在下路上。",
	"The monsters come back up the mountain.": "怪物又爬上山來。",
	"The clan asks why monsters and human soldiers have both come for them.": "一族問，為什麼怪物和人類士兵都來找他們。",
	"They cannot prove it. They say the soldiers made the monsters and sent them.": "他們證明不了。他們說是士兵造了怪物，並派他們來。",
	"A human hand.": "一隻人的手。",
	"They will not wait for the next wave to explain itself.": "他們不會等下一波自己解釋。",
	"They leave their gate, to see the world, and walk toward the village where they were born.": "他們離開自己的城門，去看世界，走向他們出生的村子。",
	"On that road, both armies find them.": "在那條路上，兩支軍隊都找到了他們。",
	"They stand on a cliff above the old country.": "他們站在舊地之上的懸崖上。",
	"Below them, monsters and human soldiers fight each other.": "在他們下方，怪物和人類士兵彼此交戰。",
	"It is a war between the two sides. The clan still does not know who started it.": "這是兩邊之間的戰爭。一族仍然不知道是誰起的頭。",
	"Tap": "輕點",
	"Continue": "繼續",
	"Play": "開始",
	"Quit": "結束",
	"1 vs 1": "一對一",
	"Home": "首頁",
	"Back": "返回",
	"Shop": "商店",
	"Skin": "造型",
	"Upgrade": "強化",
	"Code": "兌換碼",
	"Name": "名字",
	"Ranking": "排行",
	"diamonds": "鑽石",
	"Full screen": "全螢幕",
	"How to play": "怎麼玩",
	"Choose a level": "選擇關卡",
	"The clan gate, after dark.": "入夜後的一族城門。",
	"Sign out": "登出",
	"Sign in with Google": "用 Google 登入",
	"Play as guest": "以訪客遊玩",
	"Your account": "你的帳號",
	"Your name": "你的名字",
	"Opening your account.": "正在開啟你的帳號。",
	"Playing as guest. Progress stays on this device.": "以訪客遊玩。進度留在這台裝置。",
	"Saved to Google · ": "已存到 Google · ",
	"Profile": "個人",
	"Favourite": "最愛",
	"Favourites": "最愛",
	"Set favourites": "設定最愛",
	"Change favourite": "更換最愛",
	"Choose a favourite. If you own its skin, the profile wears it.": "選一個最愛。若你擁有它的造型，個人頁會穿上。",
	"No favourite yet.": "還沒有最愛。",
	"Redeem": "兌換",
	"Type": "輸入",
	"Enter letters and numbers.": "輸入英文字母與數字。",
	"Tap the white box, type letters and numbers, then press Redeem.": "輕點白框，輸入英文字母與數字，然後按兌換。",
	"Choose a name of 2 to 16 letters and numbers.": "取一個 2 到 16 個英文字母與數字的名字。",
	"Tap the white box, type 2 to 16 letters and numbers, then press Set name.": "輕點白框，輸入 2 到 16 個英文字母與數字，然後按設定名字。",
	"Set name": "設定名字",
	"Use 2 to 16 letters and numbers.": "請用 2 到 16 個英文字母與數字。",
	"This save is a tester. 1 vs 1 is open.": "這個存檔是測試者。一對一已開啟。",
	"That code does not pay.": "這個兌換碼沒有獎勵。",
	"That code is already used.": "這個兌換碼已經用過。",
	"A new level pays %d diamonds. Each skin is %d. Wear it from the home porch.": "新開一關給 %d 顆鑽石。每套造型 %d 顆。到首頁的廊上穿上。",
	"%s skin": "%s造型",
	"Unlock for %d diamonds": "用 %d 顆鑽石解開",
	"Wear a skin you own. Nothing puts the old clothes back.": "穿上你擁有的造型。原本會把舊衣服換回來。",
	"New skin": "新造型",
	"Wearing this": "穿著這套",
	"In the shop": "在商店裡",
	"Wear this": "穿上這套",
	"Owned": "已擁有",
	"Nothing": "原本",
	"Locked": "未開啟",
	"These fighters are on the other road. Press a name to read one.": "這些戰士在對面的路上。按一個名字來讀。",
	"Choose 6": "選 6 人",
	"Call who you have learned": "召喚你已學會的人",
	"The sword holds the road. A lesson adds the soldier you just survived.": "劍守著路。一課會加上你剛活下來的那個士兵。",
	"Tap a soldier to read what they do.": "輕點一名士兵，讀他們做什麼。",
	"Tap a soldier to read what they do. Tap a chosen soldier again to remove them.": "輕點一名士兵，讀他們做什麼。再輕點已選的士兵，就能移除。",
	"Chosen %d / 6": "已選 %d / 6",
	"Chosen %d": "已選 %d",
	"Waiting for the other ninja.": "正在等另一位忍者。",
	"Favourites cleared.": "已清除最愛。",
	"Favourites saved.": "已儲存最愛。",
	"No favourites can join this fight.": "沒有最愛能加入這一戰。",
	"Start battle": "開始戰鬥",
	"Ready": "準備好",
	"Leave": "離開",
	"Host": "開房",
	"Join": "加入",
	"Find opponent": "尋找對手",
	"Your ranks": "你的等級",
	"Maximum": "最高",
	"Your ranks  ·  on": "你的等級  ·  使用中",
	"Maximum  ·  on": "最高  ·  使用中",
	"Both sides are the clan. Each ninja chooses 6. Value, calls, roads, wind, and the hero are the same on both sides.": "兩邊都是一族。每個忍者選 6 人。價值、召喚、路、風和英雄兩邊一樣。",
	"Press Find opponent. The game looks for one other ninja and connects. Each ninja then chooses 6.": "按尋找對手。遊戲尋找另一個忍者並連上。然後每個忍者選 6 人。",
	"The host chooses your ranks or maximum. You can leave.": "房主選擇你的等級或最高。你可以離開。",
	"Maximum. Both sides fight at rank 20. You can leave.": "最高。兩邊都在第 20 級戰鬥。你可以離開。",
	"Your ranks. Each side uses the ranks saved on that account. You can leave.": "你的等級。每一邊用那個帳號存下的等級。你可以離開。",
	"Pause": "暫停",
	"Paused": "已暫停",
	"Resume": "繼續",
	"SWORD": "斬擊",
	"SHOOT": "射擊",
	"FULL": "已滿",
	"Field is full": "場上已滿",
	"WIND": "風",
	"NINE": "九人",
	"GENERAL": "將軍",
	"clear": "解除",
	"miss": "未中",
	"DOWN": "倒下",
	"RETURN": "歸來",
	"eat": "吞食",
	"CLAN": "一族",
	"ARMY": "軍",
	"CURSE": "咒",
	"Skill": "技能",
	"Unlocked": "已解開",
	"Congratulations": "恭喜",
	"1 vs 1 is open": "一對一已開啟",
	"Rematch": "再戰",
	"Next level": "下一關",
	"Change the call": "更換召喚",
	"Change the six": "更換六人",
	"The road waits. Your soldiers hold still until you return.": "路在等。你的士兵停著，直到你回來。",
	"The stick moves your hero. The match runs until a gate falls.": "搖桿移動你的英雄。比賽直到一座城門倒下。",
	"Press the field. The stick appears under that hand. Calls sit along the bottom. Sword and Shoot are on the right.": "按住場地。搖桿出現在那隻手下。召喚沿底部排列。斬擊和射擊在右邊。",
	"Their gate is open. Kill the nine.": "他們的城門開了。殺掉那九個。",
	"The general walks. The level ends when the general dies.": "將軍在走。將軍死去，這一關就結束。",
	"Their gate breaks": "他們的城門破了",
	"Your gate has fallen": "你的城門倒下了",
	"Your gate broke. Call them again, or choose who you bring.": "你的城門破了。再召喚他們，或重新選擇帶來的人。",
	"The cursed gate breaks": "咒門破了",
	"Their gate falls": "他們的城門倒下",
	"The other clan is broken.": "另一族潰了。",
	"Your gate broke. Fight the same six, or choose again.": "你的城門破了。用同樣的六人再打，或重新選擇。",
	"The clan learns": "一族學會了",
	"A new soldier": "一名新兵",
	"The general falls": "將軍倒下",
	"The soldiers fall back.": "士兵退了。",
	"The war": "戰爭",
	"Monsters and soldiers fight each other. The road stops on the cliff.": "怪物和士兵彼此交戰。路停在懸崖上。",
	"The road is clear.": "路清了。",
	"Explosion": "爆炸",
	"Light smashing": "光之重擊",
	"Freezing": "冰凍",
	"Enhancement": "強化",
	"Castle blood": "城堡血量",
	"Value each second": "每秒價值",
	"Rank up": "升級",
	"Full": "已滿",
	"Rank 20. Nothing left to pay.": "第 20 級。沒有剩下要付的。",
	"Reset upgrades": "重置強化",
	"Reset upgrades · 500 diamonds": "重置強化 · 500 顆鑽石",
	"You need 500 diamonds.": "你需要 500 顆鑽石。",
	"Returns the coins spent on ranks and sets every rank to 1.": "退回花在等級上的金幣，並把每一級設回 1。",
	"Choose a skill": "選擇技能",
	"Each fighter rank adds 5% blood and damage. Castle blood rises by 200 a time. Value rises by 0.1 each second. Rank 20 is the last. Skills you own rank the same way. Each rank row pays the coins below.": "每一級戰士加上 5% 的血和傷害。城堡的血每次提高 200。價值每次提高每秒 0.1。第 20 級是最後。你擁有的技能也這樣升級。每一列等級付出下面的金幣。",
	"Within 6 minutes: the base amount": "六分鐘以內：基本額",
	"Within 3 minutes: double": "三分鐘以內：雙倍",
	"Within 5 minutes: half again": "五分鐘以內：再加一半",
	"Over 6 minutes: half": "超過六分鐘：一半",
	"5 return now.": "現在回來 5 次。",
	"Automatic finish": "自動結算",
	"Choose fighters": "選擇戰士",
	"from your last clear": "依你上次過關",
	"of this level": "依這一關",
	"Special skill": "特殊技能",
	"When Brood dies": "巢死去時",
	"When their gate breaks": "對方城門破時",
	"the whole road": "整條路",
	"long": "遠",
	"mid": "中",
	"short": "近",
	"slow": "慢",
	"steady": "穩",
	"quick": "快",
	"fast": "極快",
	"Long reach · one target": "遠距離 · 一個目標",
	"Stands across every road": "橫站在每一條路",
	"Short blast · hits everyone there": "近距離爆炸 · 打中那裡的每個人",
	"Rushes, then blasts short range": "衝上前，然後近距離爆炸",
	"Blinks past the line. Kills archers, healers, and level casters": "閃過隊列。殺死弓手、治療者和升級術士",
	"Heals the weakest ally in front": "治療前面最弱的盟友",
	"Raises the strongest ally by 20%": "把前面最強的盟友提高 20%",
	"Mid reach · one target": "中距離 · 一個目標",
	"Short reach · one target": "近距離 · 一個目標",
	"No.1": "第1名",
	"No.2": "第2名",
	"No.3": "第3名",
	"Top 5": "前 5",
	"Top 10": "前 10",
	"No level yet": "還沒有關卡",
	"no time": "沒有時間",
	"Not ranked yet": "尚未排行",
	"No names yet.": "還沒有名字。",
	"Loading the ranking.": "正在載入排行。",
	"A higher level ranks first. The same level ranks the shorter time first.": "較高的關卡排在前面。同一關以較短的時間為先。",
	"Hero": "英雄",
	"Google sign-in is not connected yet.": "還沒接上 Google 登入。",
	"Could not read the saved game.": "讀不到已存的遊戲。",
	"Could not read the profile.": "讀不到個人資料。",
	"Could not load the ranking.": "載入不了排行。",
	"Could not read the ranking.": "讀不到排行。",
	"Could not reach Google.": "連不上 Google。",
	"Google sign-in is not ready.": "Google 登入還沒準備好。",
	"Sign in with Google to see the ranking.": "用 Google 登入才能看排行。",
	"Google sign-in did not finish.": "Google 登入沒有完成。",
	"Could not load the profile.": "載入不了個人資料。",
	"Could not load the saved game.": "載入不了已存的遊戲。",
	"Could not sign out.": "無法登出。",
	"Could not save to Google.": "無法存到 Google。",
	"Could not save the profile.": "無法儲存個人資料。",
	"Still connecting. Try again in a moment.": "還在連線。請稍後再試。",
	"Host a match, or join one.": "開一場，或加入一場。",
	"Press Find opponent. The game looks for one other ninja and connects.": "按尋找對手。遊戲尋找另一個忍者並連上。",
	"This build cannot host a match.": "這個版本不能開房。",
	"This build joins with a code, not an address.": "這個版本用兌換碼加入，不用位址。",
	"Could not join.": "無法加入。",
	"On this computer, press Host, then Join with the address.": "在這台電腦上，按開房，再用位址按加入。",
	"Looking for an opponent...": "正在尋找對手……",
	"Both ninjas are here. Choose 6.": "兩位忍者都到了。選 6 人。",
	"The other ninja left.": "另一個忍者離開了。",
	"Could not reach an opponent. Press Find opponent to try again.": "連不上對手。按尋找對手再試。",
	"Matches are full right now. Press Find opponent to try again.": "現在比賽已滿。按尋找對手再試。",
	"The match service did not load. Refresh the page and press Find opponent again.": "比賽服務沒有載入。重新整理頁面，再按尋找對手。",
	"Could not reach the match service. Press Find opponent to try again.": "連不上比賽服務。按尋找對手再試。",
	"Waiting for one opponent.": "正在等一位對手。",
	"Coins  %d": "金幣  %d",
	"◆  %d": "◆  %d",
	"◆  %d diamonds": "◆  %d 顆鑽石",
	"◆  %d diamonds added.": "已加入 ◆  %d 顆鑽石。",
	"Next level · %s": "下一關 · %s",
	"Level %d · %s": "第 %d 關 · %s",
	"Level %d  ·  %s": "第 %d 關  ·  %s",
	" Level %d, %s, is open.": " 第 %d 關，%s，已開啟。",
	"%s can be called now.": "現在可以召喚%s。",
	"Clan gate  %d": "一族城門  %d",
	"Cursed gate  %d": "咒門  %d",
	"Left clan  %d": "左族  %d",
	"Right clan  %d": "右族  %d",
	"Value  %d    ·    %s": "價值  %d    ·    %s",
	"Hero returns in %.1f": "英雄 %.1f 秒後歸來",
	"+%d.%d each second": "每秒 +%d.%d",
	"%s\n%d": "%s\n%d",
	"%s\n%.1fs": "%s\n%.1f 秒",
	"%s\nFULL": "%s\n已滿",
	"%s\nrank %d": "%s\n第 %d 級",
	"%d   %s\n%s": "%d   %s\n%s",
	"%s\n%d value · every %ss\n%d blood · %d damage\n%s": "%s\n價值 %d · 每 %s 秒\n血量 %d · 傷害 %d\n%s",
	"Blood %d · Damage %d": "血量 %d · 傷害 %d",
	"Blood  %d": "血量  %d",
	"Damage  %d": "傷害  %d",
	"Attacking distance  %s · %s. How close a foe must be before this one steps in.": "接敵距離  %s · %s。敵人要多近，這一邊才會上前。",
	"Attacking range  %s · %s. How far the blow itself lands.": "攻擊距離  %s · %s。這一擊本身落得多遠。",
	"Speed  %s · %s": "速度  %s · %s",
	"Time between strikes  %ss": "出手間隔  %s 秒",
	"The other gate spends %d value, then waits %ss.": "對方城門花 %d 價值，然後等 %s 秒。",
	"Beating one pays %d value.": "打倒一個可得 %d 價值。",
	"Rank %d costs %d coins": "第 %d 級要 %d 金幣",
	"%d coins": "%d 金幣",
	"%d coins came back.": "退回 %d 金幣。",
	"This will return %d coins and set every rank to 1.": "這會退回 %d 金幣，並把每一級設回 1。",
	"Confirm reset · 500 diamonds\n%d coins come back. Every rank returns to 1.": "確認重置 · 500 顆鑽石\n退回 %d 金幣。每一級回到 1。",
	"%s    %d blood    rank %d of 20": "%s    血量 %d    第 %d 級，共 20 級",
	"%s    %s    rank %d of 20": "%s    %s    第 %d 級，共 20 級",
	"%s    rank %d of 20": "%s    第 %d 級，共 20 級",
	"Level %d. Pick one. A new skill starts at rank 1. One you already have rises by one rank, up to 20.": "第 %d 關。選一個。新技能從第 1 級開始。你已經有的升一級，最高到 20。",
	"The road paid +%d coins. %d left.": "這條路給了 +%d 金幣。還剩 %d 次。",
	"The purse is full. Coins %d.": "錢袋已滿。金幣 %d。",
	"Time %s. %s. +%d coins.": "時間 %s。%s。+%d 金幣。",
	"Held +%d coins before the gate fell.": "城門倒下前已持有 +%d 金幣。",
	"Held +%d coins while the gate stood.": "城門還在時已持有 +%d 金幣。",
	"+%s coins each second": "每秒 +%s 金幣",
	" · held %d": " · 已持有 %d",
	"%d left. One press pays the %d coins %s.": "還剩 %d 次。按一次可得 %d 金幣，%s。",
	"5 more in %d min.": "%d 分鐘後再回 5 次。",
	"5 more in %d sec.": "%d 秒後再回 5 次。",
	"Place %d": "第 %d 名",
	"%d s": "%d 秒",
	"   ·   Hero rank %d": "   ·   英雄第 %d 級",
	"Port %d is busy.": "埠 %d 正忙。",
	"Hosting on port %d. On this computer the address is 127.0.0.1. Nearby, use %s.": "正在埠 %d 開房。這台電腦的位址是 127.0.0.1。附近請用 %s。",
	"Joining %s on port %d.": "正在加入 %s，埠 %d。",
	"Could not join %s.": "無法加入 %s。",
	"Road %d": "第 %d 條路",
	"%s. It strikes one fighter.": "%s。它攻擊一名戰士。",
	"Hangs behind its castle. Only an archer can hit it there. It swings once for %d from behind the castle onto an archer, a leveling caster, or a healing caster, then stays on the road.": "它掛在自己城堡後面。只有弓手能在那裡打到它。它從城堡後面盪出一次，傷害 %d，打向弓手、升級術士或治療術士，然後留在路上。",
	"Very slow. It eats the fighter in front, except a berserker or a flyer, then sits for 5 seconds and heals. The bite deals %d. It deals no ordinary damage.": "非常慢。它吃掉前面的戰士，狂戰士或飛行者除外，然後坐下 5 秒並治療。這一咬造成 %d。它沒有普通傷害。",
	"Thin blood and a hard shot, then fire stays on that spot for 3 seconds and deals %d.": "血薄，一記重射，然後火在那個位置留 3 秒，造成 %d。",
	"Thin blood. The hit stays at 3. Once every %s seconds it blows its road. The gust hits only the other side, pushing those fighters in front of it back by a quarter of the road. A berserker ignores the gust and covers the fighters behind him. The gust also stretches any fire or ice and keeps it burning 2 seconds longer. Each road holds at most two.": "血薄。傷害停在 3。每 %s 秒吹一次自己的路。那陣風只打另一邊，把前面的那些戰士推回路上的四分之一。狂戰士不理那陣風，並掩護他後面的戰士。那陣風也會拉長任何火或冰，讓它再燒 2 秒。每條路最多兩個。",
	"Throws five long heavy shots, then fights up close. The short sword deals %d.": "丟出五發長而重的遠射，然後近身打。短劍造成 %d。",
	"Waits %s seconds, then the first strike deals %d. After that it fights up close like the horse rider.": "等 %s 秒，然後第一擊造成 %d。之後它像騎手那樣近身打。",
	"Waits %s seconds, then the first charge deals %d. After that it fights up close, slower and softer than the crow.": "等 %s 秒，然後第一下衝鋒造成 %d。之後它近身打，比鴉更慢、更輕。",
	"This is a side-view gate battle. Your clan gate is on the left. The cursed gate is on the right. Both have 2000 blood.\n\nFighters and the hero are born on the ground behind their own gate, so a new call is not standing in the fight. The other side cannot walk past a gate into the ground behind it. Someone standing there can still hit a fighter in front of that gate when the attack reaches. A blow that would have hit someone behind the gate hits the gate instead. A fighter who stays behind their castle for 10 seconds is set down in front of it.\n\nYou start with one call, the sword ninja. A lesson ends when their gate breaks and nine of that monster come out, three on each road. Kill all nine and that soldier is yours. Until you know six, bring who you have. After that, choose 6. Value builds by itself. Hold the phone or iPad sideways. Press the field and the stick appears under that hand, then follows the drag. The call buttons sit along the bottom, and Sword and Shoot sit at the bottom right.\n\nThere are three roads. Soldiers only march forward on the road where you called them, and they fight only that road. The Berserker stands across all three roads, hits every road at once, and enemies on every road can hit the Berserker. The assassin blinks past every other fighter and crosses roads to kill an archer, a leveling caster, or a healing caster. She cuts no one else. The first time a house falls to half blood, a wind helps that side: fighters of the other team who have crossed the middle are blown back to the center and lose half of the blood they still have. You move the hero onto any road with the stick under your hand, or with WASD. J and K match Sword and Shoot. Number keys call the soldiers you brought, in order, onto the hero's road.\n\nIf a runner slips past the line, you are the one who runs back. If your gate breaks, you lose. On a lesson, breaking their gate is not the end: nine of that monster walk out, and you win when those nine are dead. On level 40, a general walks out after their gate falls, and you win when the general dies. Every other level ends when their gate breaks.\n\nWhen their gate is down to a quarter of its blood, they immediately gain their starting gold again. At half blood, on every level, they gain 100 value at once. From level 20 on they also gain 100 value when the gate is still at 70% blood.\n\nThe other gate calls its own fighters. On levels 1 to 19 the fight starts with walkers, and each other monster of that band joins on a later level, one at a time. From level 20 they are walkers, runners, a howler, a viper, a storm, a herald, a shell, a reaver, and an oni. From level 41 those monsters are faster and harder, and Moth, Elder, Glut, and Brood join them. The howler hangs behind its castle. Only an archer can hit it there. It swings from behind the castle onto the road, and onto an archer, a leveling caster, or a healing caster when one is alive, then stays on the road. The viper's bite holds one fighter still for 2 seconds. For a short time they cannot move or attack, and they hold the hurt pose until it ends. A healing caster can clear it. If two fighters are in front, it bites the one who hits harder and does not hold them. Most blows miss the viper. The storm waits 4 seconds, then lightning hits the fighter in front and jumps to four others, one by one, and holds each for 1 second. The herald calls two other monsters every 3 seconds. The shell is slow, hits softly, and carries a great deal of blood. The reaver is a harder hitter for a moderate call. Moth flies on one road. A short weapon cannot hit it, and those fighters stop beneath it, though they still fight a closer fighter on the ground. Elder appears somewhere on the road, strikes whoever is nearest, friend or foe, and fades after 15 seconds. Many blows miss Elder. Glut is very slow. It eats the fighter in front, except a berserker or a flyer, then sits for 5 seconds and heals. Brood bites, and when it dies three quick Lings crawl out. On soldier levels they wear modern kit, and they hit harder than before. Knives match the sword soldier. The firebow is thin-blooded and hits hard, then leaves fire on that spot for 3 seconds. The fan is thin-blooded, barely hurts, and once every 10 seconds it blows its road. The gust hits only the other side, pushing those fighters in front of it back by a quarter of the road. A berserker ignores that gust and covers the fighters behind him. That gust also stretches any fire or ice and keeps it burning 2 seconds longer. Each road holds at most two. The ward carries a great shield, a great deal of blood, and hits for 5. The javelin throws five long heavy shots, then fights up close with a short sword. The drum lifts three allies at once, the way a leveling caster lifts one. On levels 21 to 40 a cow waits 4 seconds, then the first charge hits harder than the blows after it, and it fights up close, slower and softer than a rider. From level 41 a crow does the same and hits harder: it waits 3 seconds, strikes the first enemy hard, then fights like the horse rider. From level 61, Smog, Buck, Scope, and Aria join them. Smog deals no damage and lays smoke where it walks. The smoke hides that stretch for 10 seconds. Buck fires a shotgun once a second, four times, then reloads for 2 seconds. Scope fires a long heavy shot every 3 seconds and has little blood. Aria sings, and the lift is half of a leveling caster, on every ally on every road at once. The bomber is fragile, its hit is heavy, and it strikes the berserker when one is alive. Level 40's general is an officer.\n\nPlay lists seventy levels. The first is open. Winning a level opens the next. Levels 1 to 20 are monsters, and that is where each soldier is learned. Levels 21 to 40 are human soldiers. Levels 41 to 60 are monsters again, and the new monsters begin. Levels 61 to 70 alternate, monster then soldier, starting with monsters. The new soldiers begin on the soldier turns. Your purse stays the same. Theirs gets heavier as the levels climb, and it eases a little when the soldiers first arrive. Before you choose who to bring, the level shows the other side, each fighter with a skin and a name. Press a name to read blood, damage, attacking distance, attacking range, speed, and the special skill.\n\nEach level you open pays 100 diamonds. Clearing a level also pays coins. The base is 200 coins times the level. Three minutes or less doubles that, five minutes or less adds half, six minutes or less pays the base, and a longer clear pays half. On a level you have not cleared, the fight also pays 0.25% of that base each second it is still going. Those coins stay if your gate falls. A level you have already cleared does not pay this. On a cleared level, Automatic finish skips the fight and pays the coins from your last clear. You can take that 50 times. While any are missing, 5 return every half hour. Until a clear is remembered, the stake is the base. Coins are not diamonds. Home has Upgrade. The hero and each soldier you have learned can be ranked 20 times. Each rank adds 5% of that character's blood and damage. Reach, cost, and speed stay the same. Upgrade can also raise your castle blood by 200 a time, and your value by 0.1 each second a time. Twenty is the last. Every 10 levels you choose a skill, skills rank up like fighters, and each use costs 45 value. A cast locks every skill for 10 seconds.\n\nHome is the night gate: Shop, Skin, Upgrade, the levels, and How to play are there, and the diamond count hangs by the lantern. During a fight, Home at the top returns you there.\n\nThe shop sells one new skin for the hero and one for each soldier. A skin costs 200 diamonds. Buying it does not put it on. Wear it from Skin, and Nothing puts the old clothes back.\n\nOn the website you can keep playing as a guest. That progress stays on the device. Sign in with Google and the levels you have opened, your diamonds, your coins, your ranks, and your skins stay with that account, so a phone, a tablet, and a computer can share them. The first sign-in asks for a name. Ranking lists signed-in players: a higher level cleared ranks above a lower one, and the same level ranks the shorter clear time first. A profile shows that name, the best tag, the hero, and a favourite character.\n\n1 vs 1 is on the home screen. It opens after level 20, and until then the button wears a lock. The first time it opens, a present arrives and a key turns in that lock. It is two clans. Each side chooses 6 of the 11. Both have the same value, the same calls, the same roads, the same wind, and a hero. Before the search, choose Your ranks or Maximum. Your ranks uses the ranks saved on each account. Maximum locks both sides at rank 20. The host's choice is what the match uses, and the other ninja can leave. On this page, press Find opponent. The game looks for one other ninja and connects. The match runs until a gate falls. A 1 vs 1 pays no coins. You do not type an address or a code. On a computer build, Host opens port 3001 and the other ninja joins the address.\n\nEscape or Back returns to the title.": "這是一場側面的城門戰。你的一族城門在左邊。咒門在右邊。兩邊都有 2000 血。\n\n戰士和英雄都出生在自己城門後面的地面上，所以新的召喚不會站在戰鬥裡。另一邊不能走過城門，進入它後面的地面。站在那裡的人，當攻擊夠得到時，仍能打到那座城門前面的戰士。原本會打到城門後面某人的一擊，改為打在城門上。在自己城堡後面停留 10 秒的戰士，會被放到城門前面。\n\n你一開始只有一個召喚，劍忍者。一課結束時，他們的城門破了，九隻那種怪物走出來，每條路三個。殺掉全部九隻，那個士兵就是你的。在你認識六個之前，帶上你有的。之後，選 6 個。價值會自己累積。把手機或 iPad 橫過來。按住場地，搖桿出現在那隻手下，然後跟著拖曳。召喚按鈕沿底部排列，斬擊和射擊在右下角。\n\n有三條路。士兵只在你召喚他們的那條路上向前走，也只打那條路。狂戰士橫站在三條路上，一次打中每一條路，每一條路上的敵人都能打到狂戰士。刺客閃過其他每一個戰士，並跨路去殺弓手、升級術士或治療術士。她不砍別人。一座房子第一次掉到一半血時，風會幫助那一邊：已越過中線的對方戰士被吹回中央，並失去他們還有的一半血。你用手下的搖桿，或用 WASD，把英雄移到任何一條路。J 和 K 對應斬擊和射擊。數字鍵依序召喚你帶來的士兵，召喚到英雄所在的路上。\n\n如果一個奔者溜過隊列，要跑回去的人是你。如果你的城門破了，你就輸了。在一課裡，打破他們的城門還不是結束：九隻那種怪物走出來，那九隻死了你才贏。在第 40 關，他們的城門倒下之後，一名將軍走出來，將軍死了你才贏。其他每一關都在他們的城門破掉時結束。\n\n當他們的城門血量掉到四分之一，他們立刻再得到起始的金子。在一半血時，每一關，他們一次得到 100 價值。從第 20 關起，城門還有 70% 血時，他們也得到 100 價值。\n\n對方城門召喚自己的戰士。第 1 到 19 關，戰鬥從行者開始，那一群裡的其他怪物在之後的關卡一個一個加入。從第 20 關起，他們是行者、奔者、嚎者、蝮、雷暴、號手、厚殼、掠者，還有鬼。從第 41 關起，那些怪物更快、更難，蛾、老者、饕和巢也加入。嚎者掛在自己城堡後面。只有弓手能在那裡打到它。它從城堡後面盪到路上，若有弓手、升級術士或治療術士活著，就盪到他們身上，然後留在路上。蝮的咬讓一名戰士停住 2 秒。有一小段時間他們不能移動或攻擊，並保持受傷的姿勢，直到結束。治療術士可以解除。如果前面有兩名戰士，它咬打得較重的那一個，並不困住他們。大多數攻擊打不中蝮。雷暴等 4 秒，然後閃電打中前面的戰士，再一個一個跳到另外四個身上，每個困住 1 秒。號手每 3 秒召喚兩隻其他怪物。厚殼很慢，打得很輕，帶著很多血。掠者是中等召喚裡打得較重的。蛾在一條路上飛。短兵器打不到它，那些戰士停在它下面，不過他們仍會打地面上更近的戰士。老者出現在路上某處，打最近的人，無論友敵，15 秒後消失。許多攻擊打不中老者。饕非常慢。它吃掉前面的戰士，狂戰士或飛行者除外，然後坐下 5 秒並治療。巢會咬，死的時候三隻快的幼爬出來。在士兵關，他們穿著現代裝備，打得比以前更重。短刃對應劍士。火弓血薄、打得重，然後在那個位置留下火 3 秒。扇血薄，幾乎不傷人，每 10 秒吹一次自己的路。那陣風只打另一邊，把前面的那些戰士推回路上的四分之一。狂戰士不理那陣風，並掩護他後面的戰士。那陣風也會拉長任何火或冰，讓它再燒 2 秒。每條路最多兩個。大盾帶著一面大盾、很多血，傷害是 5。投槍丟出五發長而重的遠射，然後近身用短劍打。鼓一次抬起三名盟友，就像升級術士抬起一個。第 21 到 40 關，牛等 4 秒，然後第一下衝鋒比之後的攻擊更重，它近身打，比騎手更慢、更輕。從第 41 關起，鴉也這樣，而且打得更重：它等 3 秒，先重重打第一個敵人，然後像騎手那樣打。從第 61 關起，煙、霰、瞄和詠加入。煙不造成傷害，並在走過的地方鋪煙。煙霧把那一段藏起 10 秒。霰每秒開一槍，四次，然後裝填 2 秒。瞄每 3 秒開一發長而重的槍，血很少。詠唱歌，提升是升級術士的一半，同時作用在每一條路上的每一個盟友。爆者很脆，一擊很重，若有狂戰士活著就打狂戰士。第 40 關的將軍是一名軍官。\n\n開始列出七十關。第一關是開的。贏了一關就開啟下一關。第 1 到 20 關是怪物，每個士兵都在那裡學會。第 21 到 40 關是人類士兵。第 41 到 60 關又是怪物，新的怪物從這裡開始。第 61 到 70 關交替，先怪物再士兵，從怪物開始。新的士兵在士兵那幾關開始。你的錢袋保持不變。他們的隨著關卡升高而變重，士兵剛到時會稍輕一點。在你選擇帶誰之前，這一關會顯示另一邊，每個戰士都有造型和名字。按一個名字，可讀血量、傷害、接敵距離、攻擊距離、速度，以及特殊技能。\n\n你開啟的每一關給 100 顆鑽石。過關也給金幣。基本額是 200 金幣乘上關數。三分鐘或更少是雙倍，五分鐘或更少再加一半，六分鐘或更少給基本額，更久的過關給一半。在你還沒過的關，戰鬥還在進行的每一秒，也給那個基本額的 0.25%。那些金幣在你的城門倒下時仍留下。已經過的關不給這個。在已過的關，自動結算跳過戰鬥，並付給你上次過關的金幣。你可以領 50 次。缺的時候，每半小時回來 5 次。在記住一次過關之前，賭注是基本額。金幣不是鑽石。首頁有強化。英雄和你學會的每個士兵可以強化 20 次。每一級加上那個角色 5% 的血和傷害。距離、費用和速度不變。強化也可以每次把城堡的血提高 200，並每次把你的價值提高每秒 0.1。二十是最後。每 10 關你選一個技能，技能像戰士一樣升級，每次使用花 45 價值。一次施放把每個技能鎖住 10 秒。\n\n首頁是夜裡的城門：商店、造型、強化、關卡，以及怎麼玩都在那裡，鑽石的數目掛在燈籠旁。戰鬥中，上方的首頁會把你帶回那裡。\n\n商店賣英雄的一套新造型，以及每個士兵一套。一套造型要 200 顆鑽石。買下並不會穿上。從造型頁穿上，原本會把舊衣服換回來。\n\n在網站上你可以繼續以訪客遊玩。那份進度留在這台裝置。用 Google 登入後，你開啟的關卡、鑽石、金幣、等級和造型會留在那個帳號，所以手機、平板和電腦可以共用。第一次登入會問一個名字。排行列出已登入的玩家：過了較高的關排在前面，同一關則較短的過關時間優先。個人頁顯示那個名字、最好的標記、英雄，以及一個最愛的角色。\n\n一對一在首頁。它在第 20 關之後開啟，在那之前按鈕帶著一把鎖。第一次開啟時，一份禮物到來，鑰匙在鎖裡轉動。這是兩個一族。每邊選 11 個裡的 6 個。兩邊的價值、召喚、路、風和英雄都一樣。搜尋之前，選擇你的等級或最高。你的等級用每個帳號存下的等級。最高把兩邊都鎖在第 20 級。房主的選擇就是這場用的，另一個忍者可以離開。在這一頁，按尋找對手。遊戲尋找另一個忍者並連上。戰鬥直到一座城門倒下。一對一不給金幣。你不要輸入位址或兌換碼。在電腦版，開房會打開埠 3001，另一個忍者加入那個位址。\n\nEscape 或返回會回到標題。",
}


static func set_lang(code: String) -> void:
	if code == "zh":
		lang = "zh"
	else:
		lang = "en"
	_cache.clear()


static func install() -> void:
	if _installed:
		return
	var base: Font = ThemeDB.fallback_font
	if base == null:
		return
	var theme: Theme = ThemeDB.get_default_theme()
	if theme != null:
		_attach(theme.default_font)
		var types: PackedStringArray = theme.get_type_list()
		for type_name in types:
			var items: PackedStringArray = theme.get_font_list(type_name)
			for item_name in items:
				_attach(theme.get_font(item_name, type_name))
	_attach(base)
	_installed = true


static func _attach(face: Font) -> void:
	if face == null or face == CJK_FONT:
		return
	var chain: Array[Font] = []
	var existing: Array = face.fallbacks
	for item in existing:
		var old: Font = item as Font
		if old == null:
			continue
		if old == CJK_FONT:
			return
		chain.append(old)
	chain.append(CJK_FONT)
	face.fallbacks = chain


static func cjk() -> Font:
	install()
	return CJK_FONT


static func font() -> Font:
	install()
	var base: Font = ThemeDB.fallback_font
	if base == null:
		return CJK_FONT
	return base


static func t(source: String) -> String:
	return _t(source, 0)


static func _t(source: String, depth: int) -> String:
	if lang != "zh" or source == "" or depth > 4:
		return source
	if _has_cjk(source):
		return source
	if _cache.has(source):
		return str(_cache[source])
	var out: String = source
	var key := source
	if key.contains("\r"):
		key = key.replace("\r", "")
	if MAP.has(key) and not _is_template(key):
		out = str(MAP[key])
	else:
		out = _apply(key, depth)
	_cache[source] = out
	return out


static func _has_cjk(source: String) -> bool:
	var n := source.length()
	for i in n:
		if source.unicode_at(i) >= 0x2E80:
			return true
	return false


static func _is_template(key: String) -> bool:
	return key.contains("%d") or key.contains("%s") or key.contains("%.1f") or key.contains("%02d")


static func _build() -> void:
	if _built:
		return
	_built = true
	var ranked: PackedStringArray = PackedStringArray()
	for key in MAP.keys():
		var k := str(key)
		if not _is_template(k):
			continue
		var placed := false
		var at := 0
		while at < ranked.size():
			if k.length() > ranked[at].length():
				ranked.insert(at, k)
				placed = true
				break
			at += 1
		if not placed:
			ranked.append(k)
	for k in ranked:
		var rx := RegEx.new()
		if rx.compile(_pattern(k)) != OK:
			continue
		_pat_rx.append(rx)
		_pat_zh.append(str(MAP[k]))


static func _pattern(key: String) -> String:
	var pattern := "^"
	var i := 0
	while i < key.length():
		if key.substr(i, 2) == "%%":
			pattern += "%"
			i += 2
			continue
		if key.substr(i, 4) == "%.1f":
			pattern += "(\\d+\\.\\d)"
			i += 4
			continue
		if key.substr(i, 4) == "%02d":
			pattern += "(\\d+)"
			i += 4
			continue
		if key.substr(i, 2) == "%d":
			pattern += "(\\d+)"
			i += 2
			continue
		if key.substr(i, 2) == "%s":
			if i + 2 < key.length():
				pattern += "(.+?)"
			else:
				pattern += "(.+)"
			i += 2
			continue
		pattern += _esc(key.substr(i, 1))
		i += 1
	pattern += "$"
	return pattern


static func _esc(ch: String) -> String:
	if "\\.+*?^$()[]{}|".contains(ch):
		return "\\" + ch
	return ch


static func _apply(source: String, depth: int) -> String:
	if MAP.has(source) and not _is_template(source):
		return str(MAP[source])
	_build()
	var n := _pat_rx.size()
	for i in n:
		var rx: RegEx = _pat_rx[i]
		var found: RegExMatch = rx.search(source)
		if found == null:
			continue
		var caps: PackedStringArray = PackedStringArray()
		var count := found.get_group_count()
		for g in range(1, count + 1):
			caps.append(found.get_string(g))
		return _fill(_pat_zh[i], caps, depth)
	if MAP.has(source):
		return str(MAP[source])
	return source


static func _fill(zh: String, caps: PackedStringArray, depth: int) -> String:
	var out := ""
	var i := 0
	var n := 0
	while i < zh.length():
		if zh.substr(i, 2) == "%%":
			out += "%"
			i += 2
			continue
		var token := ""
		if zh.substr(i, 4) == "%.1f" or zh.substr(i, 4) == "%02d":
			token = zh.substr(i, 4)
			i += 4
		elif zh.substr(i, 2) == "%d" or zh.substr(i, 2) == "%s":
			token = zh.substr(i, 2)
			i += 2
		else:
			out += zh.substr(i, 1)
			i += 1
			continue
		var cap := ""
		if n < caps.size():
			cap = caps[n]
		n += 1
		if token == "%s":
			out += _t(cap, depth + 1)
		else:
			out += cap
	return out

