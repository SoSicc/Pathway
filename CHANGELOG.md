## Unreleased

### Pop-ups, campfires and travel
- The campfire card has a new, more compact look. The fire is a round medallion, with its burn time running down a ring around it and the time underneath. Below it, each camp buff has its own tile with a countdown sweep: camp buffs (the minute's sit, then their time), the sleeping bag (stacks, and the next one coming) and Well Fed (says so when you're not). A single hint line says what to do next ("Sit a minute for camp buffs", "Lie on your bag: a stack a minute"), and what you can use there sits under a line at the bottom. Point at a tile for what it means.
- New minimap glow: Fire. Flames lick up around the round map's edge, tall over the top and low underneath, each flickering on its own, with embers drifting up off it. It's all the game's own animation, so it costs nothing to run, and it stops while the map is hidden. Pick it under GoodMap's "Glow around the map", or the new Campfire look in Setup's minimap looks.
- The campfire card no longer shows up with no fire there. It comes up only while you have the Campfire Nearby buff, are sitting for the camp buffs, or are lying in your sleeping bag, and it goes as soon as none of those is true. A fire Pathway only remembered (one it guessed at earlier) no longer brings it up.
- A town's own campfire is now known for what it is. Sitting at one (Lakeshire has one) used to count as a fire someone had placed, with a burn-out countdown, and Pathway even told other Pathway players about it. Now the card says "Town campfire: always lit", and nothing is timed or shared. A fire near you whose burn time nobody knows says so instead of counting down.
- The sleeping bag's three stack dots show as dots (the game's font has no dot, so they showed as boxes).
- The notification bell beside the minimap, and the holiday button above it, can be clicked again. The Blizzard minimap that Pathway's minimap replaces is only made invisible, and some of its frames still took the clicks. Both buttons now sit a layer above it.
- The guide takes you where it's going. Nothing joins it just because it's near where you're standing: a quest ready in your town, a Fastest XP set picking up ready quests from the zone you're in, an undiscovered flight path behind you, the inn to set your hearthstone. Each one now joins only when it's on the guide's way: next to one of its next stops, or a short detour on the way to the next one. Turn-ins still join in any town the guide goes through (where you fly or sail from doesn't count as going there).
- Fastest XP's title names the zone it's sending you to now ("Fastest XP: Elwynn Forest"), not just the zone the set was picked for.
- All pop-ups share one spot: questions, gear and talent tips, the campfire and its timer come up just above the magic button, bottom middle, stacked when there's more than one so they never cover each other. Setup asks where you'd like them (above the magic button, middle or top), and so does Settings, Home. Shift-drag any one to move them all.
- Campfires are found however the game names their buffs: by the buff's id and, failing that, by its name, and a buff time the game keeps hidden from add-ons no longer stops the check. Already by a fire when you log in or /reload: the timer comes up too.
- Campfires from every campfire add-on we could reach: Pathway listens (never sends) to CampFirePin, S'more Skills and, in your group, Kerzo Camping Sync, and reads Happy Camper's camps through its public camp lookup, shown as "Camp data: Happy Camper" and never passed on. Pathway players share fires only with each other, on Pathway's own channel, and pass on what they hear so everyone running Pathway sees it.
- Layers: Pathway reads your layer from the creatures around you, and fires known to be on another layer stay off your map.
- No more phantom fires: "Campfire Nearby" only says a fire is within about 100 yards, so a fire you've only come near is kept for the timer and never pinned on a map where it isn't.
- The campfire window: how long the fire burns, the minute you sit for camp buffs (then how long they last), your sleeping bag's three stacks with the next one's countdown, and a row of what you can use there: the camp objects you carry, the bag, XP food, one click each. It also comes up while you sleep in your bag.
- /pw net lists each source: Pathway players, CampFirePin players, S'more Skills hosts, your Kerzo group, Happy Camper's camps, your layer, and anything the game blocked.
- Making Campfire Kits no longer puts a fire on your map (or tells other players about one). A fire counts as placed only once its buff turns up on you a moment after the cast.
- /pw net shows whether sharing is reaching anyone: the channels joined, how many Pathway and campfire players have been heard in the last day and when, what was sent, and if the game refused a message.
- Campfire timer: by a campfire, a small bar shows how long until it burns out, turning amber then red near the end. Exact when the fire was seen placed (by you or a player sharing), otherwise "up to", the most it can have left. Settings, Quest help: Campfire timer.
- Fires burn fifteen minutes (the game's data), not ten.
- The campfire pop-up's fire sits in its own square inside the window: the glow and embers no longer spill out, and it fades in instead of growing.
- Less running: time on a flight, boat or tram counts for about a third of the same time running, for the way there, Fastest XP's choice of zone and the order of stops. A flight a few minutes slower that saves you the run now wins, and the step says "Less running" rather than claiming it saves time. Never one that's far slower. Settings, Navigation: Less running.

### Faster reloads
- Logging in or /reload does about a third of the work it did. The list of who starts and ends each quest is kept by number and built the first time it's needed, not up front; the bank window is made the first time you open your bank.
- No hitch ten seconds after loading: the WoW-Pro tips are read a couple of milliseconds a frame in the background instead of all at once.
- Campfires you knew survive a /reload (with the time they really have left), so Pathway doesn't ask the channel again; the quest XP question goes out at most every 15 minutes rather than at every reload.
Fastest XP goes by experience a minute, not experience.

- Each quest is timed from what it asks: who to kill or talk to, what to collect and where, how far that is from its giver and how spread out, how many (your quest log's own counts once you have it, remembered for your other characters), elites, and a hand-in somewhere else. A delivery that pays 400 in forty seconds now beats twelve drops for 1100.
- The cut is the top 25% by experience a minute, and the next set is the zone with the most experience a minute, using each quest's own time instead of a flat four minutes.
- Your pace: Pathway times each Fastest XP set (only while you're at the keyboard) and learns how you compare with its guess, so the times become yours.
- The score: each finished set shows its experience an hour, the session tooltip on the guide's bottom line lists the last three, and /pw fast lists the last ten.

Turn-ins.

- A turn-in run (Turn in, Turn in all) only hands in: no "Pick up" steps at the people it stops at, and the quest helper doesn't accept anything while it runs (hold Shift and take one yourself if you want it).
- Any other guide (Fastest XP, Nearest set, a zone or a guide you picked) also hands in your finished quests in a town or city it already takes you to, or the one you're standing in, right after its stop there. Settings, Quest help: Turn-ins in the same town.

Built for Forever.

- Checked against Blizzard's own Forever interface code and API, every game function, window and event Pathway uses. Forever runs the modern interface with its own touches, none of the classic one, so Pathway now speaks Forever's own way throughout:
  - The quest log, completed quests, objectives, deleting and sharing quests use Forever's quest API (C_QuestLog); the classic quest log paths are gone.
  - Gray quests follow the game's own cutoff (UnitQuestTrivialLevelRange), the same one the quest log colors use.
  - Your spec for gear upgrades, and the spec of players you inspect, come from Forever's specializations (points in each tree).
  - Talent suggestions read Forever's talent tree only.
  - Fixed: the fishing log asked the game something Forever doesn't have when you looted a catch (LootSlotHasItem); it uses the loot slot type now, like the game's own loot window.
  - Removed what Forever doesn't have: classic PvP rank and honor reading, pet and toy lookups in the bags.

Tidier windows.

- Pathway's question cards size themselves to what they hold: wide enough for their buttons (a second row past a limit), tall enough for their text, so nothing runs under the buttons or past the edge. "Never ask" is a quiet link on the left instead of one more button.
- The guide window's title stops before the journal icon instead of running under it, and the next Fastest XP set reads on one line ("Next: Redridge Mountains · 2 quests, 5k XP").
- The campfire pop-up and the delete-quests panel grow to fit their words too.
- The guide window grows down, not up: it's kept by its top edge, so a step with a lot to it no longer pushes the window up over the minimap and its buttons. A spot you'd already set moves over to its top the first time the guide shows, without the window jumping.
- The WoW-Pro tip under the guide is as tall as its note: a tip that wraps onto a second line no longer pushes the credit line out past the window's bottom edge.
- Question cards and the campfire pop-up stay where you put them, like every Pathway window: Shift-drag moves one, and every one after comes up in that same spot (kept by its top middle, so a bigger card still starts there).

Delete quests.

- A red "Clean up" button on Forever's Map & Quest Log, between the search box and the quest count, with the game's trash icon and an arrow for its choices (it glows under the mouse and lists them): a panel slides out beside the map window with Delete all, Keep the best (keeps your top 25% by experience; hover it to see which would go), and a tick box on every quest so you can pick exactly which ones go. The panel counts what you've ticked and deletes just those.
- A quest that's ready to hand in is never deleted, whichever you pick: it gets a green mark instead of a tick box, and the panel says how many it's keeping.
- Every delete asks once more on the same button (click again within a few seconds), then the quests go one by one with a bar filling as they do. Settings, Quest help: Delete quests button.
- Deleting really drops the quests now. Forever only lets a quest go from something you did, which is why the well-known macro works and the old timed one-by-one didn't: your confirming click now drops them all right then, just as the macro does, and the log is checked a moment later. Anything still there turns the buttons into "Try again", and each click tries the next way (the game's own Abandon and its Yes, then the Abandon button on the quest's page). Last of all, the game's own Abandon box, one Yes each. Quests the game won't let you drop are skipped and counted.

Leveling the Forever way.

- Dungeon sweeps: Forever pays dungeon quests well and dungeon kills poorly, so a dungeon is worth one run with all its quests. When one fits your level, Fastest XP asks (once a dungeon, with "Never ask" to turn it off). Say yes and the next set is the sweep: gather its quests, a stop at the door to find a group, the run, then the hand-ins. Quests you don't finish inside stay in your log.
- Quest experience data refreshed from QuestieDB's November 18 Forever update, measured from real play: 515 more quests have their real reward, and 58 rewards Forever changed are corrected (some quests pay double what they used to, a few far less). Dungeon quests aren't in it yet.
- Forever's dungeon quest rewards: 98 dungeon quests (Hall of Thanes up to Razorfen Downs) now have what the live game pays, gathered from ForeverChanges and Conquest Capped, which agree quest for quest: Deviate Hides 3,100, The Defias Brotherhood 6,200, each City of Dalaran quest 9,400. A dungeon quest Pathway has no Forever number for yet counts at 2.2 times the old one (Forever pays 1.8 to 2.7 times, by dungeon) until someone sees the real one.
- Shared with other Pathway players, over a hidden add-on channel that never shows in chat: the quest rewards each of you sees (only what you saw yourself, and only numbers that make sense for the quest). Joining late, Pathway asks about quests near your level nobody measured yet, and whoever knows answers.
- Campfires on the world map and minimap: ones you place, sit at or walk past, and ones others shared, with how long they'll burn, the fire's tier and what's set up at it. Click one to go there. They live in memory only and go when they burn out.
- Campfires are shared the way CampFirePin (BeeTwenty's Campfire add-on) shares them, on its own channel and in its own words, so Pathway players and CampFirePin players see each other's fires, and a fire one of them saw go out goes for everyone. Like CampFirePin, only fires someone stood at are shared; one guessed from walking past stays yours.
- Tidy by itself: rewards the data now has are dropped from your saved variables at login, shared numbers are capped, and nothing about fires is ever saved.
- With Questie installed, its quest experience table is read at login too: where it has a newer, measured number for a quest Pathway only knows the old reward for, Pathway uses it (in memory, nothing saved).
- Settings, Quest help: Share with other Pathway players, Campfires on the maps.
- Real quest XP: the data's rewards are the old world's (Forever pays dungeon quests far more: Deviate Hides is 1,600 there). Whenever the game shows a reward, in the quest window or your log, Pathway notes it for all your characters and plans with it.
- XP buffs, asked at the right moment (a new Fastest XP set): lay out your Cozy Sleeping Bag when its buff is missing, or from level 14 the way to its quest chain (open to you from 14 now, though its quests say 22); XP food before a set with killing in it, or the nearest cooking trainer if you have none. Yes puts the bag or food on your magic button and step key.
- Rested: logging out or stepping away out in the world, Pathway offers the nearest inn (or your Sleeping Bag, which counts as one).
- Campfires: passing one when your camp buffs are gone or nearly, a pop-up with embers asks you to stop and sit (a Sit down button does it).
- Each of these has "Never ask" or "Don't show again" right there, and its own switch in Settings, Quest help.

## 1.4.3
Smoother and tidier: action bars stay put in fights, flights are chosen when they're faster, and the add-on folder is three files of Pathway's own.

- Action bars no longer vanish in a fight. Pathway's minimap used to hide and show the game's minimap frame, which made the game redo its whole screen layout (action bars included) under Pathway's name; mid-fight that layout can't place the bars. Now the game's minimap only turns invisible and lets the mouse through, and Pathway never moves the game's minimap during a fight.
- Flying is chosen when it's faster: Three Corners now joins Redridge and Duskwood on foot, so from Stormwind to Darkshire the guide flies you to Lakeshire.
- Your hearthstone: Pathway learns where it goes only once you're really there (or when you walk into that inn), never says "hearth" while you're standing in your inn, moves the step on as soon as you're there, and shows the hearthstone on that step instead of a gryphon, with "Use it where you stand".
- Notifications keep what's worth coming back to (a level, a full quest log, an elite added to your guide); guide steps and quick confirmations are just a passing toast now.
- The performance meter names the busiest handlers by file and line, and /pw perf lists them in chat.
- On the tram, the game's own tram map (you, moving down the line) fades in and out under the rainbow tunnel, inside Pathway's minimap; no more stray second minimap.
- Lighter in fights: objective aiming and trip re-planning wait for the fight to end, and a step that can't be finished no longer redraws everything twice a second.
- The worst moments are kept: while the performance meter is on, Pathway saves its busiest handlers' peaks (with the zone and what you were doing), so slowdowns can be fixed from facts.
- Nothing grows without end: players and healers seen are forgotten after half an hour (a long evening in a city or a battleground no longer piles them up), and the saved lists have firm limits (2000 places, 150 doorways and 150 gathering spots of each kind per zone; "Done" marks for quests you've turned in are tidied away at login).
- Tidier add-on folder: Pathway's own code ships as three files, Data.lua, Pathway.lua and Modules.lua (WoW-Pro's guides and RestedXP's hints stay as they are). Same code, same order, same behavior; tools/bundle.py --split gives the separate files back.

## 1.4.2
Pathway's license now asks for credit: anything built from Pathway keeps the line "Based on Pathway by SoFinSicc" and takes a name of its own.

- Every Pathway file carries its copyright line, and LICENSE.md adds terms under section 7 of the GPLv3: anything based on Pathway keeps the credit "Based on Pathway by SoFinSicc" with a link back, isn't passed off as Pathway or as someone else's work, and needs its own name and icon.
- The About page in settings shows who made Pathway and where it lives.

## 1.4.1
The minimap gets the real ground up close, ride effects for the tram, boats, zeppelins, lifts, swimming, ghosts and hearthing, and the guide a one-click run to turn in every quest that's ready.

**The minimap up close**
- Terrain up close: past the zone map's own detail the game's real minimap terrain fades in under every pin (roads, houses, docks), drawn from the minimap squares already in the game, so it pans and zooms with the map and every pin, your arrow and your route sit exactly on it. More zoom steps go down to about 100 yards across. In towns and cities the map zooms in to it while you're there and back out as you leave. A town's area is the game's own where there is one, else a circle round its flight master or inn that learns the town's real size as you walk it.
- Detailed view inside: in an inn, a house, a cave or a tunnel with no map of its own, the minimap fades over to the game's own picture of the rooms around you, with Pathway's pins and quest spots placed right on it. Zoom out past its widest view for the zone map. Minimap settings: "Detailed view inside buildings", "Terrain up close", "in cities and towns".

**Ride effects**
- Ride effects on the minimap: a rainbow 3D tunnel in the Deeprun Tram (with where it's going), water light, a wake and foam on boats and ferries, wind streaming past on zeppelins, light bands on lifts, ripples while you swim, and underwater a deep-blue view with rising bubbles and an air gauge round the edge that turns amber, then red and pulses faster before you run out of breath. Running back as a ghost gets a cold, hazy spirit world. Boats and zeppelins show where they're going and, once Pathway has timed a ride, how long is left. Each one can be turned off (minimap settings, Ride effects).
- Hearthing on the minimap: while you cast your hearthstone, Astral Recall or a teleport, light spirals in to you faster and faster, a ring turns from blue to gold and the middle burns brighter, with where you're going and the time left; a flash when it lands, and a burst of light where you arrive. Minimap settings, Ride effects.
- Ride effects: boats and zeppelins only count where a boat or zeppelin runs (no more wind from a knockback), the edge fills up as the ride goes on and a soft chime plays 10 seconds before you arrive (same switches as flight mode), fewer particles when the frame rate drops, one shared timer (shown as "Ride effects" in the performance meter), and Reduce motion: slower and softer, no flashes.

**Turn in all**
- Turn in all: a small tab with the yellow "?" next to Fastest XP (with how many quests are ready). One click and the guide takes you to every quest that's ready to turn in, in the quickest order from where you stand: flights, boats, the tram and your hearthstone counted, on either continent. Quests that become ready on the way join the run. Your guide waits and comes back when you're done; click the tab again to stop.
- Turn in all: every stop numbered on the map in order, the total time in the title ("Turn in all · 6 · about 9 min"), and the run picks up again after a reload.

**Checking it**
- `/gmap check`: tries everything on the minimap in front of you (each ride effect, the terrain up close, the detailed view) and says in chat what worked. Preview buttons for each ride effect in the minimap settings, and `/gmap preview`.

**Fixes**
- Deeprun Tram and other places that are an instance of their own: the minimap no longer shows the zone outside (Dun Morogh) with a made-up position. GoodMap shows the place's own map when the game has one, even when the game doesn't say which map you're on, and hands over to the Blizzard minimap where there's none. `/gmap where` shows which map you're on.

## 1.4.0
Fastest XP rebuilt on real quest XP, a minimap that shows your quests and what you track everywhere (caves, buildings and dungeons included), corpse runs, towns in Go anywhere, and a tidier minimap bar.

**Fastest XP, rebuilt**
- It knows what each quest really pays on Forever (QuestieDB's quest XP data, with the game's own rule for quests below your level), instead of guessing from the quest's level. Quests with no level and no measured XP (mail rewards and the like) no longer count.
- The next set is the zone that gives the most XP per minute: what its top quests pay, against the real trip there (flights, boats, the tram, on either continent) and the time the quests take. A big set a flight or a boat away now beats one lone quest next door, so it no longer hops from zone to zone for single quests.
- A quest that opens a chain where a later part makes the cut counts too.
- A set never gets stuck: quests you skip leave it, and when nothing left in a set is something the guide can do, the next set is worked out straight away.
- The title shows how much of the set is left ("Fastest XP: Wetlands · 3 of 7 left"), and near the end the card shows where the next set is.
- Described as what it is: only the highest-XP quests (the top 25%).

**Quest spots on the minimap**
- Every objective spot of your quests is a bold pip with a dark outline in that quest's own color, readable on any map art. The guide's quest is in your accent color, bigger and glowing; other quests never get a color close to it.
- The spot the arrow wants pulses, spots you've checked turn hollow, and a chevron on the edge points to a quest whose spots are all off the minimap.
- Works on both minimaps, replaces the small objective dots, and can be turned off (Settings, Navigation). It's redrawn only when a spot would move a pixel, so it costs next to nothing.

**Better steps**
- Things you click (crates, ore, chests): once you've stood at a spot for a moment it's checked, and the arrow moves on to the next one. Checked spots come back after five minutes, or straight away when you've checked them all. The step says how many spots there are ("24 spots in Wetlands").
- Steps without a guide writer's tip show what the quest itself says ("...from Menethil Harbor").
- Objectives Pathway's data can't place (mostly items in Forever's own quests) now use the quest area the game shows on your map, instead of being left out of the guide.
- You died: while you're a ghost the arrow and the minimap paths take you to your corpse, and the guide card says so. The guide stays where it was and carries on when you're back on your feet. If the game can't say where your body is, Pathway uses the spot where you died.

**Pathway's minimap**
- Caves, buildings, tunnels and floors: when the game has a map for where you are, the minimap switches to it, and back when you leave. Your quest pins, quest spots and town services come along. Indoors with no map of its own (an inn, a house), the map comes two steps closer.
- Dungeons, raids and delves: when the instance has a map, the minimap stays and shows the whole floor you're on, following you from floor to floor, with the game's own marker for you. Only where there's no map does it hand over to the Blizzard minimap.
- No more circle: indoors the game paints its own building art and a black ring into the minimap, which showed through. The radar now steps out indoors (your setting is moved over once; you can turn it back on).
- What you track, at all times: inside the radar the game shows its own live blips; everywhere it isn't (indoors, on a flight, when you've moved the map, past its edge on a zoomed-out map), Pathway shows the herbs and ore you can gather at your skill (while you track Find Herbs or Find Minerals) and the town services you track. Pathway's pips show where a node can be, not whether it's up right now. Settings, Navigation: Tracking everywhere.
- Each of these can be turned off in the minimap's settings.

**A tidier minimap bar**
- Other add-ons' minimap buttons stay off the bar unless you want them there: setup has a step that lists them and asks which (if any) go on the bar, and the rest wait in the numbered add-on button, a click away. That works for buttons made without LibDBIcon too. When you add an add-on later, Pathway asks once where its button goes. Change your picks any time: minimap settings, Button bar, "Add-on buttons on the bar".
- The notification bell has its own spot on the left of the minimap, just under the holiday ("Today") button, or in its place when there's no holiday, with a bell icon instead of the letter that looked like the mail icon.
- No more blank space where the mail icon was once your mail is read: the bar closes the gap, and opens it again when new mail comes.

**Go anywhere**
- Finds towns too: every flight-path town on both continents (Gadgetzan, Booty Bay, Everlook, Theramore...) and the inn towns without one (Goldshire, Kharanos, Brill...). Picking a town takes you to the town itself, not just its zone; the other side's towns are marked. `/pw go gadget` works too.

**Fixes**
- Ten "Unrecognized XML" warnings every time the game loaded (Bindings.xml was listed in the .toc; the game loads it by itself). Your key bindings are unchanged.
- An error on a flight step when the time it saves couldn't be worked out, a bags error while refreshing in combat, and the player card being blocked by the game in combat.

## 1.3.0
Three ways to quest that you pick, Go anywhere, Outfits, combat and danger alerts on the minimap, Mark completed, and a big speed pass: Pathway now works only when something really changes.

**Three ways to quest, your pick**
- Fastest XP is the default; Storyline and All quests only run when you pick them (setup, the guide's switch, the journal or the map menu). When a chain or a zone's first steps are done, the guide carries on the way you chose.
- Fastest XP: only the highest-XP quests at your level (the top 25%). You get a set (those quests in the zone you're in), pick it up, finish it and hand it in without picking up anything else; the next part of a chain in the set joins it when it gives as much XP. Then the next set, here or in the closest zone that still has some. The cut is set once per level, so finishing the best quests moves you on instead of lowering the bar.
- Storyline: only the story chain that fits your level best (the one you're on, else the one whose next quest is closest to your level), start to finish, with the breadcrumbs that lead into it. Then the next best one.
- All quests: every quest in the zone, chain to chain. A chain is finished before the next one starts (the one you're on, else the closest), and quests on their own are picked up where they sit along it.

**Hearthstone advice**
- On Storyline and All quests, when most of your hand-ins sit around one inn and your objectives take you away from it, Pathway says where to set your hearthstone (once per zone) and adds "Set your hearthstone here" to your guide as you pass that inn. Skip it if you'd rather not.

**Go anywhere**
- A globe button on the minimap bar (and /pw to <zone>): type a zone or city, click it to see the fastest way there leg by leg with times, and go. It weighs the roads and passes, your flight paths, boats, zeppelins, the tram, the Feathermoon ferry, your hearthstone, mage and druid teleports, Astral Recall and the engineering transporters to Gadgetzan and Everlook. Each leg is a step in your guide, and your guide comes back when you arrive.
- Every route now takes a flight, boat or teleport whenever it's clearly quicker (it used to favour sitting back on a slightly slower flight).

**Outfits**
- With transmog outfits saved, an Outfits button on the minimap bar lists them: click one to wear it (the game's own /outfit, so it works anywhere). No outfits, no button. Both new buttons can be turned off in the parts menu.

**Window opacity**
- One setting for how solid Pathway's windows are, from fully solid to see-through: the guide, the cards, the meter and the rest. Setup asks (Solid, Standard, Soft or See-through) and Settings has a slider.

**Skip and Mark completed**
- Skip now leaves the step's quest out of every guide until your next level, so it stops coming back.
- Mark quest completed leaves it out for good on this character: right-click Skip, use the guide's menu, or right-click a quest in the guide's list. An Undo comes with it, and Settings can bring everything back.

**Combat and danger on the minimap**
- In combat the minimap's edge pulses red.
- A hostile creature that's almost close enough to notice you is called out: the edge pulses amber and a line names it, with an optional sound. Needs enemy nameplates showing.

**Off means off**
- The path button on the minimap bar now rests everything tied to the route, not just the two windows: the route math, the magic button and quest bar, and the paths on the minimap and map. One click brings it all back, caught up.
- Parts you switch off stop their background work too: card lookups on hover, the nameplate quest list, WoW-Pro's notes, and the checks for nearby elites.
- The parts menu on the minimap button has switches for the combat pulse, the nearby enemy alert, town services, step tips and WoW-Pro tips.

**Cards**
- A player's item level keeps being asked for until the game answers, instead of sitting on "looking...". Long names and races fit the card.
- Player, rare, elite and boss cards use the game's tooltip look (its border, fonts, gold labels and health bar, class-colored names) with Pathway's colored band, item level and odds.

**Flights you'll actually take**
- The fastest way to your next stop is checked again as you move (every few seconds, and only once you've moved a stretch, so standing still costs nothing). A flight master you've walked up to is offered right away, and a flight that's no longer worth it once you've run most of the way is dropped.
- A trip's legs are counted properly: refreshing the route no longer uses up its legs, which could stop flights being offered on a long route.
- On the flight map, a bobbing arrow and a glow sit over the flight point your guide wants you to fly to, with "Fly here" under it (on both the newer and the classic flight map).
- The flight map is the truth: when you open it, flight points it doesn't offer you are forgotten, and any route through them is planned again. At login, Pathway only learns flight points the game plainly says you've discovered.

**Faster everywhere**
- The game says "the quest log changed" many times a second, usually when nothing did. Pathway now only reworks what you can pick up when a quest really comes, goes or gets done; a kill count moving just moves the guide along. In an offline test of questing with the guide on, Pathway's work dropped from about 47 ms to about 2 ms per second of play.
- What a character could ever pick up (race, class, side, a giver somewhere) is worked out once, so checking what's available now looks at a fraction of the quest list.
- The minimap path updates ten times a second instead of twenty, moves its dots instead of re-creating them, and flight path icons only move when you, the facing or the zoom do.
- The arrow turns every frame but only rewrites its words when they change.
- The performance meter reads every add-on's memory at most every few seconds, and only while you hover it (that alone was most of its own cost), and no longer runs a garbage-collection step.
- The nearby-elite check looks only at elite quests.

## 1.2.2
A chain-first route pass focused on quest progression.

**Routes**
- The default nearby route now keeps active quest objectives and completed turn-ins ahead of unrelated quest pickups.
- Pickups at the player's current hub remain batched, and a quest giver with both a completed hand-in and a newly available pickup remains one combined stop.
- Follow-up priority now recognizes prerequisites and parent links as well as explicit `NEXT` links, so a hand-in that unlocks a later quest is treated as chain progress.
- Objective targeting now matches quest-log objective type and text; it no longer silently maps an unmatched objective to an unrelated database target just because the list positions happen to line up.
- The same focus rule is applied when nearby work is merged into an active route, preventing unrelated pickups from sneaking back in mid-route.
- Explicit Pick up and Fastest XP modes retain their distinct behavior.

**Validation note**
- Compared prerequisite/alternative-prerequisite handling with the published WoW-Pro guide syntax; `PRE` represents required predecessors and `PREANY` represents alternative predecessors. Pathway's existing quest-eligibility checks remain the authority for whether a follow-up is actually available.
- Static source and packaging checks are included with this build. A live WoW: Forever client test is still required to validate quest-log events, actual NPC availability, and route behavior across real quest chains.


# Pathway

## 1.2.1
A reliability and packaging update.

**Fixed**
- Load `Bindings.xml` from the addon manifest so Pathway, GoodMap and Fishing Blinker keybindings are registered by the client.
- Keep the addon's manifest version and runtime version in sync at 1.2.1.

**Validation**
- All bundled Lua files pass a Lua syntax compilation check.
- All XML files parse successfully.
- All Lua files referenced by the addon manifest are present.
- In-game behavior and performance still require verification in the WoW: Forever client.


## 1.2.0
A smoother first run, a better player card and journal, and smarter routes.

**Three ways to quest a zone**
- Story: the zone's main story, chain by chain. All quests: everything there for your level, closest first. Fastest XP: after every hand-in, the quest that gives the most experience for the time it takes, wherever it is.
- Switch any time with the three buttons at the top of the guide window; the journal's zone pages and setup ask too, and your choice is kept.

**Setup**
- Setup walks you through only the parts you picked, with "Step 2 of 5" on every page: your parts, size and color, your damage meter (Simple, Standard or Detailed), your minimap, then your windows.
- Placing windows: each one starts in a layout that keeps the middle of your screen clear. The instructions move out of the way of the window you're placing (and can be dragged), and say how to move and size it. Tips wait until setup is done.
- Ctrl + mouse wheel resizes every Pathway window again.

**Player card**
- Item level is the headline, colored against yours (+3 above you in red, below you in green).
- Full names with surnames (the second name was showing as a realm).
- The game's tooltip stays hidden for players, including over unit frames.
- The card has its own spot by default, at the left of your screen.

**Guide**
- A journal button on the guide window, and an x on every tab to close that guide.
- Step tips for about 470 quests (up from 340), including which floor, which path and who patrols where.
- Smarter order: at a quest hub you pick up and hand in everything there first; then the closest stop by the real walk, with hand-ins that open the next quest pulled forward and plain hand-ins bunched up for the way back.
- Dungeon quests wait for the dungeon instead of walking you to its door.
- "I can't get this quest here" in the guide menu leaves a quest out until your next level. Quest givers that don't offer a quest are still learned automatically when you talk to them.

**Guide fixes**
- Class quests stay with their class (Forever lists some, like the mage library books, without one), and book hand-ins only show once you have the book.
- Your flight paths are learned at login where the game shares them. If Pathway doesn't know them yet, standing at a flight master it says so: talk to them once and it flies you from then on.
- Stormwind Harbor's boat to Auberdine is part of trip planning: Westfall to Darkshore flies you to Stormwind, then takes the boat.
- Every quest in the guide's list says where it goes next (with a note when it's across the sea), and its tooltip shows the quest's own words. Hand-ins show the quest's words too, so "speak with him in Stormwind" is right there.
- Clicking Done on a "Discover flight path" step now counts that flight path as known, so trips use it straight away.
- Quest givers from the other faction are no longer used for directions (no more being sent to Undercity as Alliance).
- Special book quests with nothing to do (like "Friend of the Library") stay out of the guide.
- Every step is a numbered plan in plain words: "1 Kill Sneed's Shredder, 2 Loot the Gnoam Sprecklesprocket, then hand it in to Shoni the Shilent". Pickups and hand-ins say who to talk to and what to accept or turn in.
- Dungeon quests whose item drops inside a dungeon, and elite quests above your level, stay out of routes when you're on your own (Fastest XP skips elites altogether). Steps that need a group say so.
- Your quest list in the guide shows the 10 that matter most now: your guide's next ones first, then the most experience for the least travel. Click one to follow it; if Pathway can't place it yet, the journal opens on it.
- No more popups as you leave a town or finish a zone (both can be turned back on in settings).
- Elite quests join your guide the moment you meet them: target the elite, walk up to it, or stand at its quest giver. A toast and the step say it's elite; Skip leaves it out again.
- Steps say how to do them in a guide writer's words where there are some ("Kill Young Wolves and Timber Wolves. Loot them for their Tough Wolf Meat"), now for 785 quests. Where there aren't, Pathway writes the steps itself, with the creatures' levels and any quest item to use.

**WoW-Pro tips**
- When your step has a note in the WoW-Pro Community's Forever guides ("Vagash is in a cave atop the hill", "Leave the mine and only target the ones outside"), it shows in a small window joined to the bottom of your guide, in Pathway's look. Their guides are included unchanged, credited to them (CC BY-NC-ND 3.0). Settings > Guide turns it off.

**Rare, elite and boss cards**
- Hover or target a rare, elite or boss for its own card: how tough it is for you, which of your quests needs it, and what it drops.
- Drops are icons you can hover, link and try on. Upgrades for you glow green, pets and mounts purple, and anything worth keeping or selling gold.

**A calm start**
- No guide loads on its own after setup or when you close your last tab. The guide shows "No guide loaded" with two buttons, Load Fastest XP guide and Find something else? (the journal), and the arrow stays away until you pick one.
- The magic button only shows when the step has something to target or use.
- The quest log has a Clear all button (it asks first).

**Minimap**
- Starts small (you can make it bigger in setup or Style the minimap).
- Quest areas are soft glows clipped to the round map, brightest for the quest you're on. The game's own quest areas (which can't be clipped) only show on a square map.
- Near an inn, a flight master or mailboxes the map zooms in two steps and shows the town's services: inns, banks, auction houses, repairs, mail, flights and your class trainer. Zooming in on a town does the same. Quest dots step back while they show.
- Redraws only when something you'd see changes, so it does less work.

**Guide and arrow switch**
- A path button on the minimap bar turns the guide and the arrow off together, and back on.

**Performance meter**
- Hover it to see what each part of Pathway costs (minimap, bags, fishing, the guide, the arrow, cards, meters...), and click it to turn any part off right there.

**Minimap**
- Flying between flight paths, the route line and its running lights move with you smoothly.

**Upgrades panel**
- Sits clear of the character window's side tabs and the arrow.
- Shows what you'd gain (stats, or "fills your empty slot") instead of percentages.
- Only upgrades from quests you're on or can start now are listed, and every one has a Go button that loads the quest in your guide. Dungeon quests and elites above your level stay out.

**Journal**
- Bigger, so everything fits: more new quests on the home page, plus shortcuts to gear upgrades and your next talents.

**Routes**
- Flights are taken when they're faster: a known flight path wins over a long run (Stormwind to Westfall now flies to Sentinel Hill). Time in the air counts at half, since you can sit back, and flights you've taken use their real time.
- The guide orders stops by how you'd really walk between zones, not a straight line over the mountains.
- The arrow's time to arrive follows the real road at your real speed.

**Setup**
- No more guide offers when you enter a zone. Load a zone's guide from the guide window or /pw zone.
- Nothing pops up over setup: the guide, arrow and welcome wait until it's done.
- The last step places your windows: each one you chose glows in turn and you drag it where you want it. Then they lock; Shift-drag moves one, and Settings > Home places them again.

**New**
- Performance meter (optional): frame rate and latency in a small box. Hover it for what's using the most; click it for lighter effects, a calmer background frame rate and freeing memory, all of which can be put back.
- The player card can have its own spot, and shows when you point at a name in the damage meter.
- The damage meter has three styles: just you, your group, or your group and your range. Plus options for the group total, the card on hover, and which numbers it starts on.

**Fixed**
- Mailboxes, banks and auction houses you track show on the minimap in cities and inns again.

## 1.1.2
A cleaner guide, exact directions, and help with talents and gear.

**Guide**
- A cleaner guide window: the step you're on, then the one after, with Done and Skip right under it. Your quests fold away into a list you can open and click.
- Done marks a step finished for good on that character, so the guide never sends you back for it. Made a mistake? Undo waits in your notifications.
- Step tips: short notes on exactly where to go, like "upstairs in the inn" or "enter the cave", for about 340 quests. From RestedXP Guides (CC BY-NC-SA 4.0). The arrow shows them once you're close.
- Pathway learns the doorway into every building and cave you walk into, then points you to the door first. Inside, it tells you which floor to go to.

**Talents and gear**
- Talent tips work with Forever's talent window: your next three talents get numbered rings, with a line above the tree naming them.
- An Upgrades button on your character window lists the best quest reward for each slot, from quests you're on or can pick up soon, with a Go button that puts it in your guide.
- Item tooltips say where the item comes from.

**Minimap and windows**
- The minimap opens each zone at a comfortable zoom, then remembers how you like each zone.
- Every Pathway window can be moved, and resized with Ctrl and the mouse wheel. "Reset windows" puts them back.

**Damage meter**
- Every party and raid member's DPS, with your own row always shown and the group total.
- Your DPS range across your recent fights, with this fight highlighted against your average.

**Players**
- The game's tooltip no longer shows over the player card, even when you sweep quickly across a crowd. The card has a size slider.

**First run**
- Setup starts by asking which parts you want (guide, minimap, bags, gear, talents, player cards, meter, fishing) and only asks about the ones you picked.

## 1.1.1
Fixes from playing 1.1, plus notifications and a damage meter.

**Fixed**
- Going to a mailbox, flight master or anything from "Find the nearest" now finishes when you get there (or open it), and your guide comes back.
- Routes know how the zones really connect: Stormwind to Dun Morogh takes the Deeprun Tram instead of a walk through the mountains. Boats, zeppelins and flights win whenever they're faster, and "Find the nearest" measures by the road too.
- The magic button is always there while you follow a guide. With nothing to target, it opens the guide.
- Gear upgrades are noticed again: weapon damage is read properly and small early-level upgrades count.
- The game's tooltip no longer shows through the player card.
- Your bags open beside the guide window and the meter, not on top of them.
- The quest reward Pathway picks gets a small check mark (the label used to cover the next reward's name).
- Tucking away Blizzard's quest tracker no longer causes errors in the game's own code.
- Lighter on your frame rate: the arrow, objective tracking and the minimap path do less work.

**New**
- Notifications: a button next to the Pathway button on your minimap bar shows what Pathway told you lately. Upgrades wait there with an Equip button.
- Damage meter: a small fixed window with the game's own damage, healing and damage taken numbers, for this fight or the whole session. Settings > Players & combat.
- "Put upgrades on for me": soulbound upgrades go straight on (off by default).

## 1.1.0
A big polish pass: Pathway now sets itself up, looks right on any screen, and gets a new character moving in one click.

**Getting started**
- First-time setup: pick your size, your color, how you want to do each step, and style your minimap, all live.
- A welcome on every new character that loads a starter guide for the quest in front of you.
- Text and windows scale to your screen automatically, so everything is readable out of the box.
- Short tips the first time you meet each part. Run setup or the tips again any time.

**Guide**
- Guide tabs: follow several guides at once and switch between them.
- Never lost: when a guide ends, Pathway shows what's next with one click to go.
- Your quests listed in the guide window, and Blizzard's quest tracker tucks itself away while the guide is open.
- Directions say where things really are: inside the abbey, in the mine, on top of the tower.
- Starter quests fixed: the guide follows the quests your class and zone actually offer.
- The magic button: one movable button that does the next step (target, use the item, talk, turn in). On by default.
- A cleaner quest bar with target and item boxes and kill counts (off by default; the magic button covers it).

**Minimap**
- A style page with a live preview: edge glow (soft, neon, pulse, breathe, aura, shadow, double ring, rainbow), solid, dashed or dotted edges, thickness and color.
- Facing glow styles (arc, wide, beam, comet, front & back, spot, fan) with color, brightness and width.
- Seven arrow shapes in any color, map size and shape, and quick looks. Every click changes your real minimap and is saved.
- One Pathway button on the minimap bar: left-click for everything, right-click for options.
- Find the nearest mailbox and the closest flight master.
- The minimap now works in starting zones and on new characters, and starts zoomed in.

**Journal and more**
- A "For you" home page with zone pictures, what's new in Forever, and pets and mounts you can get.
- A Pets & mounts tab with where each one comes from.
- Suggested talent points while you level.
- Player cards replace the default tooltip and fade out slowly so you can read them.
- Every part has its own checkbox in the main menu. Start fresh resets every setting.

## 1.0.0
First release for WoW Forever.
- Quest journal: every zone, dungeon, class and profession quest, with story chains and progress.
- Guides that flow from quest to chain to the rest of the zone, skipping what you've done.
- Arrow, minimap and world map paths, a slim step window with live objective progress.
- Quest bar with a box per target (with raid markers) and per quest item, plus a step key.
- The fastest way to every step: flight paths, boats, zeppelins, the tram, hearthstone and teleports, across continents.
- Learns new quests as you play, until the data catches up; Forever & secrets tab in the journal.
- Player cards show spec from what players cast and wear, and who they're targeting.
- Ctrl+Alt-click any item to see where it comes from and get a guide there.
- Drop a map pin and Pathway takes you there, then back to your guide.
- Undiscovered flight paths highlighted, and picked up on the way.
- Bags with Grid, Categories and labeled Bags layouts, Loot Inbox and Bank Anywhere.
- Zone map minimap with flight mode, button bar and route drawing.
- Fishing mode with bite timer, journal and tackle.
- Player cards with your odds in a fight, and red crosses over enemy healers.
- Find the nearest repair, vendor, trainer, bank and more.
