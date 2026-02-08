# Boulder QTE - Next Steps & Roadmap

Development roadmap for completing the prototype and beyond.

---

## 🎯 Current Status

**Phase 1:** ✓ Core Physics - COMPLETE
**Phase 2:** ✓ Limb Control - COMPLETE
**Phase 3:** ✓ Hold System - COMPLETE
**Phase 4:** ✓ Head Tracking - COMPLETE
**Phase 4.5:** ✓ Refactoring - COMPLETE (consolidated holds, reorganized scenes/docs)
**Phase 5:** ✓ Stamina System - COMPLETE (drain/regen, position multipliers, hold difficulty, UI bar)

**Overall:** ~90% of core prototype complete (need win/lose conditions for MVP)

---

## 🚨 Immediate Priority: Win/Lose Conditions (Phase 6)

**Status:** Ready to start
**Estimated Time:** 1-2 hours
**See:** Phase 6 section below

**Stamina system is fully wired: position-based multipliers, hold difficulty drain, forced detach on depletion, StaminaBar UI with color feedback.**

---

## 📋 Phase 5: Stamina System

**Goal:** Add resource management to create risk/reward decisions

**Estimated Time:** 2-4 hours

### **5.1 StaminaManager Singleton** (30 mins)

Create `scripts/managers/stamina_manager.gd`:

```gdscript
extends Node

# Stamina configuration
const MAX_STAMINA = 100.0
const DRAIN_RATE = 10.0  # Per second when holding
const REGEN_RATE = 15.0  # Per second when free
const MIN_LATCH_STAMINA = 5.0  # Can't latch below this

var current_stamina = MAX_STAMINA

signal stamina_changed(new_value)
signal stamina_depleted()

func _process(delta):
    # Will be updated by Player to know drain state
    pass

func drain(delta):
    current_stamina -= DRAIN_RATE * delta
    if current_stamina < 0:
        current_stamina = 0
        stamina_depleted.emit()
    stamina_changed.emit(current_stamina)

func regenerate(delta):
    current_stamina += REGEN_RATE * delta
    if current_stamina > MAX_STAMINA:
        current_stamina = MAX_STAMINA
    stamina_changed.emit(current_stamina)

func can_latch() -> bool:
    return current_stamina >= MIN_LATCH_STAMINA

func reset():
    current_stamina = MAX_STAMINA
```

**Register as autoload in project.godot**

### **5.2 Integrate with Player** (30 mins)

Update `scripts/player/player.gd`:

```gdscript
func _process(delta):
    _handle_limb_selection()
    _handle_limb_actions()
    _update_head_tracking()
    _update_stamina(delta)  # NEW

func _update_stamina(delta):
    var latched_count = 0
    for limb in limbs:
        if limb.is_latched:
            latched_count += 1

    if latched_count > 0:
        StaminaManager.drain(delta)
    else:
        StaminaManager.regenerate(delta)

func _handle_limb_actions():
    var selected = get_selected_limb()
    if not selected:
        return

    # Check stamina before latching
    if InputManager.latch_just_pressed:
        if not StaminaManager.can_latch():
            print("Not enough stamina!")
            return  # Prevent latch

        var nearest_hold = selected.get_nearest_hold()
        if nearest_hold:
            selected.latch_to_hold(nearest_hold)

    # ...rest of function
```

### **5.3 StaminaBar UI** (1 hour)

Create `scenes/ui/StaminaBar.tscn`:
- ProgressBar or custom ColorRect implementation
- Position: Top-left or bottom-center
- Color: Green → Yellow → Red based on level
- Smooth interpolation for visual polish

Create `scripts/ui/stamina_bar.gd`:
```gdscript
extends ProgressBar

func _ready():
    max_value = 100
    value = 100
    StaminaManager.stamina_changed.connect(_on_stamina_changed)

func _on_stamina_changed(new_value):
    value = new_value
    # Change color based on level
    if value < 30:
        modulate = Color.RED
    elif value < 60:
        modulate = Color.YELLOW
    else:
        modulate = Color.GREEN
```

Add to each level scene (LevelEasy.tscn, LevelMedium.tscn, LevelHard.tscn)

### **5.4 Stamina Depletion Logic** (30 mins)

Update `scripts/player/player.gd`:
```gdscript
func _ready():
    # ...existing code
    StaminaManager.stamina_depleted.connect(_on_stamina_depleted)

func _on_stamina_depleted():
    # Detach all limbs
    for limb in limbs:
        if limb.is_latched:
            limb.detach_from_hold()

    print("Stamina depleted! All limbs released!")
```

### **5.5 Balance & Testing** (30 mins)

Tune constants for fun gameplay:
- **DRAIN_RATE**: Too fast = frustrating, too slow = no challenge
- **REGEN_RATE**: Should encourage strategic resting
- **MAX_STAMINA**: Affects how long you can hold on

**Test scenarios:**
- Can you climb a wall with current values?
- Is there risk/reward in resting vs pushing forward?
- Do players need to plan their route?

---

## 📋 Phase 6: Win/Lose Conditions

**Goal:** Complete gameplay loop with clear goals

**Estimated Time:** 1-2 hours

### **6.1 Win Trigger** (30 mins)

Create `scenes/environment/WinTrigger.tscn`:
- Area2D at top of climbing wall
- Detects when player's torso enters

Create `scripts/environment/win_trigger.gd`:
```gdscript
extends Area2D

signal player_reached_top()

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.name == "Torso":  # Player's torso
        player_reached_top.emit()
```

### **6.2 GameUI Implementation** (1 hour)

Create `scenes/ui/GameUI.tscn`:
- Win message panel (hidden by default)
- Lose message panel (hidden by default)
- Restart button
- "Press R to restart" text

Create `scripts/ui/game_ui.gd`:
```gdscript
extends CanvasLayer

@onready var win_panel = $WinPanel
@onready var lose_panel = $LosePanel

func _ready():
    win_panel.hide()
    lose_panel.hide()

func show_win():
    win_panel.show()

func show_lose():
    lose_panel.show()

func hide_all():
    win_panel.hide()
    lose_panel.hide()
```

### **6.3 Level Integration** (30 mins)

Update `scripts/environment/level.gd` (used in all level scenes):
```gdscript
@onready var win_trigger = $WinTrigger
@onready var game_ui = $GameUI

func _ready():
    win_trigger.player_reached_top.connect(_on_player_won)
    StaminaManager.stamina_depleted.connect(_on_player_lost)

func _on_player_won():
    print("Victory!")
    game_ui.show_win()
    # Optionally freeze game or show stats

func _on_player_lost():
    print("Out of stamina!")
    game_ui.show_lose()

func restart_level():
    StaminaManager.reset()
    game_ui.hide_all()
    get_tree().reload_current_scene()
```

---

## 📋 Phase 7: Polish & Juice

**Goal:** Make the game feel great

**Estimated Time:** 2-4 hours

### **7.1 Sound Effects** (1 hour)

Find/create placeholder sounds:
- Limb latch (click/snap sound)
- Limb detach (pop/release sound)
- Fall/lose (thud/impact sound)
- Win (chime/success sound)
- Low stamina warning (alert sound)

Create `scripts/managers/audio_manager.gd`:
```gdscript
extends Node

var sfx_latch = preload("res://audio/latch.wav")
var sfx_detach = preload("res://audio/detach.wav")
# ... etc

func play_latch():
    var player = AudioStreamPlayer.new()
    add_child(player)
    player.stream = sfx_latch
    player.play()
    player.finished.connect(player.queue_free)
```

Hook up to events in limb.gd and level.gd

### **7.2 Visual Feedback** (1 hour)

**Particle effects:**
- Dust cloud when limb latches
- Particles when falling
- Sparkles when winning

**Camera shake:**
- Small shake when latching
- Big shake when falling

**Improved visuals:**
- Add outlines to shapes
- Animated sprites instead of ColorRects (optional)
- Background gradient

### **7.3 Tutorial/Hints** (30 mins)

Add text overlays:
- "Press 1-4 to select limbs"
- "Move mouse to control limb"
- "Press SPACE to latch"
- "Press X to detach"
- "Watch your stamina!"

Show on first launch, hide after player understands

### **7.4 Feel Improvements** (30 mins)

**Timing tweaks:**
- Add slight delay before stamina drain starts
- Brief "grace period" when stamina hits 0
- Slow-motion effect when falling?

**Visual indicators:**
- Draw line from limb to cursor when selected
- Pulsing outline when stamina low
- Flash when can't latch (no stamina)

---

## 📋 Phase 8: Level Design

**Goal:** Create interesting climbing challenges

**Estimated Time:** 2-4 hours

### **8.1 Level Variations**

Create multiple levels with different challenges:

**Level 1: Tutorial**
- Short wall
- Holds close together
- Easy to complete

**Level 2: The Gap**
- Larger gaps between holds
- Requires momentum generation
- Teaches swinging

**Level 3: Endurance**
- Many holds but long climb
- Tests stamina management
- Need to rest strategically

**Level 4: Overhang**
- Holds positioned for ceiling climbing
- Tests player skill
- Requires planning

### **8.2 Hold Types** (Optional)

Add variety:
- **Small holds:** Drain stamina faster
- **Large holds:** Can rest (regenerate faster)
- **Crumbly holds:** Detach after X seconds
- **Slippery holds:** Harder to latch (smaller detection radius)

### **8.3 Hazards** (Optional)

Add challenge:
- **Moving holds:** Slide horizontally
- **Timed holds:** Disappear/reappear
- **Spikes:** Insta-fail if touched
- **Wind zones:** Push player sideways

---

## 📋 Phase 9: Menu & Settings

**Goal:** Professional presentation

**Estimated Time:** 2-3 hours

### **9.1 Main Menu**
- Title screen
- Play button
- Level select
- Settings
- Quit

### **9.2 Settings Menu**
- Audio volume sliders
- Fullscreen toggle
- Controls remapping
- Physics difficulty (easy/normal/hard)

### **9.3 Pause Menu**
- Pause with ESC key
- Resume, restart, quit options
- Show controls reminder

---

## 🎯 Minimum Viable Prototype (MVP)

**Definition:** Smallest playable version that demonstrates core concept

**Required:**
- ✓ Ragdoll physics
- ✓ Limb control
- ✓ Hold system
- ✓ One level
- ✓ Stamina system
- ⏳ Win condition
- ✓ Basic UI (StaminaBar)

**Not Required:**
- Head tracking (nice to have)
- Sound effects (can add later)
- Multiple levels (one is enough)
- Polish/juice (adds feel but not gameplay)
- Menus (can restart manually)

**MVP Complete After:** Phases 5-6 (stamina + win/lose)
**Estimated Time to MVP:** 3-6 hours from current state

---

## 🚀 Beyond Prototype

**If the prototype is fun, consider:**

### **Gameplay Expansion**
- Local multiplayer (race to the top)
- Online leaderboards (fastest time)
- Daily challenge levels
- Level editor for community levels
- Speedrun mode with timer
- Achievements/challenges

### **Content**
- 20+ handcrafted levels
- Level themes (mountains, buildings, space?)
- Different characters (affects mass/physics)
- Cosmetic customization

### **Technical**
- Mobile port (touch controls)
- Better graphics/animations
- Original soundtrack
- Save system
- Analytics/telemetry

---

## 📊 Development Milestones

| Milestone | Description | Est. Time | Status |
|-----------|-------------|-----------|--------|
| M1: Physics | Ragdoll working | 3-4h | ✓ Done |
| M2: Control | Limb movement | 2-3h | ✓ Done |
| M3: Holds | Latch system | 2-3h | ✓ Done |
| M4: Head | Tracking system | 1-3h | ✓ Done |
| M5: Stamina | Resource management | 2-4h | ✓ Done |
| M6: Win/Lose | Complete loop | 1-2h | 🔜 Next |
| **MVP COMPLETE** | **Playable prototype** | **11-19h total** | **~90% done** |
| M7: Polish | Juice & feel | 2-4h | 📝 Later |
| M8: Levels | Content creation | 2-4h | 📝 Later |
| M9: Menus | Presentation | 2-3h | 📝 Later |
| **FULL PROTOTYPE** | **Complete game** | **17-30h total** | **In progress** |

---

## 🎓 Learning Opportunities

As you continue, focus on:

**Godot Skills:**
- Signals and observers
- UI/UX in Godot
- Scene instancing
- Resource management
- Audio system

**Game Design:**
- Difficulty balancing
- Teaching through level design
- Visual feedback importance
- Player psychology (flow state)

**Programming:**
- State machines
- Event-driven architecture
- Performance profiling
- Code organization at scale

---

## 🔄 Iteration Strategy

**After each phase:**
1. **Test thoroughly** - Play for 5-10 minutes
2. **Get feedback** - Show to others if possible
3. **Note what feels good** - Document successes
4. **Note what feels bad** - Document problems
5. **Prioritize fixes** - Not everything needs fixing
6. **Iterate quickly** - Small changes, test often

**Questions to ask:**
- Is this fun?
- Is this frustrating?
- Is this clear?
- Would I play this again?
- What's the core experience?

---

## 🎯 Definition of Done

**For prototype to be "complete":**
- [ ] Player can climb a wall
- [ ] Stamina creates meaningful decisions
- [ ] Win condition is clear and satisfying
- [ ] Lose condition is clear and fair
- [ ] Game can be restarted easily
- [ ] No game-breaking bugs
- [ ] Physics feel good and intentional
- [ ] Can show to others and explain quickly

**When all checked:**
Prototype is done! 🎉

**Then decide:**
- Ship as-is (game jam, portfolio)
- Polish and expand (full game)
- Learn from and move to new project

---

## 💾 Backup Recommendations

**Before major changes:**
- Commit to git (if using version control)
- Duplicate project folder
- Document current "good" physics values
- Take screenshots/videos of working version

**Why:** Easy to rollback if experiment goes wrong

---

## 📚 Resources

**Godot Documentation:**
- https://docs.godotengine.org/en/stable/
- 2D physics tutorial
- UI system guide
- Audio system guide

**Game Feel:**
- "The Art of Screenshake" (YouTube)
- "Juice It or Lose It" (GDC talk)
- Game Maker's Toolkit (YouTube channel)

**Similar Games for Inspiration:**
- Getting Over It with Bennett Foddy
- QWOP
- I Am Bread
- Human Fall Flat

---

**Current Next Action:** Fix head tracking or skip to Phase 5 (stamina)

**Recommended:** Spend max 3 hours on head tracking, then move forward

**Goal:** Complete MVP within next 6-8 hours of work

---

Good luck! The foundation is solid. You're close to a complete prototype! 🚀
