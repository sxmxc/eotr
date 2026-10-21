# BKL-031 boss encounters

Current authority: [three-act-progression.md](three-act-progression.md).
Each act now has one boss in its own encounter pool. All use
ELIMINATE_HOSTILES and an aggregate hostile health meter (BKL-019).
The historical Triune/Core Nexus ladder is not implemented content.
The design rationale below predates the completed multi-act integration;
the campaign document takes precedence where details differ.

Normal combat asks players to spend three energy across damage, block, movement
and harvesting. Phase Step moves one hex and the first movement refunds energy;
mana wells grant energy. Attacks include ranged bolts, adjacent multi-hit Jab,
area damage and expensive finishers. Corruption forbids ordinary movement;
collapse removes outer cells. Obelisks normally add bounded reinforcements and
are not instant-win objectives. Bosses should change these decisions, rather
than merely increase the amount of ordinary combat.

## Bulwark: bait and punish

Replace the ordinary two-Bulwark/support/Obelisk group with one committed siege
creature. At player-turn start it fixes a short ram route toward the player's
current cell. The route never follows subsequent movement. On its turn it rams
that route for 10 blockable damage and advances along surviving free cells.
Its next turn is recovery: incoming ordinary damage is increased by 50%, and
it cannot attack. Then it commits again from its new location.

The tactical question is whether to spend a movement card to sidestep, hold a
mana well and block, or attack through the danger. Recovery lets melee builds
close and multi-hit builds exploit the opening. Ranged builds retain direct
damage access at all times. No compulsory damage threshold or specific card.
Collapse changes the available baiting routes; destroyed route cells are never
used. The boss abandons a ram to escape an imminent collapsing edge.

Presentation: broad amber tread plates mark the exact route; the creature
leans into its commitment and surges across it. Open plating glows ivory during
recovery. Heavy Behemoth audio is distinct from the other encounters.

## Void Spectre: compose the last word

The Spectre listens on odd turns and reaps on even turns. Each attack card adds
one chorus voice, capped at three; every other card removes one. Chorus persists
across the listening turn, then resets after the reap. Reap deals one 3-damage
hit plus one per voice (up to four hits); every hit is blockable. Listening
advances toward the player but deals no damage. No healing Obelisk, residue spam,
arbitrary health phases or immunity windows.

The tactical question is how to order two hands: spend attacks early then quiet
the chorus with movement, resource or defense cards; or preserve attack output
and prepare block. Even an attack-heavy hand can damage-race or defend against
the capped response. The displayed hit count updates after each card. Listening
offers a closing/harvesting turn; collapse makes delaying damage progressively
more expensive. Existing statuses and targeted attacks continue to work.

Presentation: translucent copies of the actual Spectre illustration accumulate
around it, then converge into successive ghost impacts. Violet inward motion
and Ghost audio distinguish this from a ground hazard.

## Prismatic Siege: dismantle the circuit

A stationary core rotates power through three fragile relay creatures in
authored positions. One relay is lit for the entire player turn. Actual health
damage dealt to that relay is also dealt to the core; excess overkill is not
duplicated. Destroying the lit relay interrupts that turn's 9-damage blockable
discharge. The next turn selects the next surviving relay. When none remain,
the unshielded core uses a weaker 4-damage discharge. Relays do not summon,
move, or add unrelated normal attacks. The core can always be attacked directly.

The tactical question is where to send damage: break the active relay for
offense and safety, clear another relay to simplify future turns, or race the
core and block the discharge. Area attacks can damage both core and relay;
this deliberate benefit rewards positioning without requiring area cards.
Victory still requires every hostile, so destroying the core shuts down its
discharges but does not silently delete surviving relays. Collapse can destroy
outer relays and naturally simplifies the circuit; no inaccessible objective
or invulnerability lock remains.

Presentation: angular crystal facets surround relays, with a single bright
prismatic connection to the core. Interrupted power visibly breaks; discharge
uses a concentrated crystal flash, not the Bulwark's tread or spectral copies.

## Engineering and validation

Use a small shared enemy/action adapter for the existing EnemyHandler lifecycle,
then three concrete enemy scripts for these three mechanics. Authored spawn and
terrain fields are optional EncounterDefinition data; normal encounters retain
their generation and AI. No alternate damage, card, occupancy or turn engine.
Telegraphs lock at player-turn start, remain inspectable in the existing intent
surface, and are cancelled on death/end of battle.

Validate actual card sequencing, capped relay transfer/overkill, active relay
death, core-first victory, route lock, occupancy, cancellation and collapse.
Use fixed AutoWalker seeds plus native phase captures; bot outcomes alone do not
establish fun or balance. Keep evidence bounded under .qa-tmp/bkl-031.
