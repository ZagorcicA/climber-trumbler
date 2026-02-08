# Claude Code Development Instructions

## 🎯 Core Mission

You are helping develop "Climber Trumbler", a 2D physics-based ragdoll climbing game in Godot 4.3. Your job is to read log files, understand what's happening, debug systematically, and communicate clearly.

---

## 📊 Output Monitoring System

### How It Works

The developer runs Godot with output piped to a log file:

**macOS / Linux:**
```bash
godot --path . --editor 2>&1 | tee logs/godot_output.log
```

**Windows (PowerShell):**
```powershell
godot --path . --editor 2>&1 | Tee-Object -FilePath logs/godot_output.log
```

**Windows (Git Bash):**
```bash
godot --path . --editor 2>&1 | tee logs/godot_output.log
```

**What this means:**
- ALL Godot output (prints, errors, warnings) writes to `logs/godot_output.log`
- You can read this file directly - no need to ask the user to paste output
- File updates in real-time while Godot runs
- This is your window into what's actually happening in the game

### Critical Rule: Always Check Logs

**NEVER assume code works without reading `logs/godot_output.log`**

After ANY code change:
1. Tell the user to clear logs:
   - macOS/Linux/Git Bash: `> logs/godot_output.log`
   - PowerShell: `Clear-Content logs/godot_output.log`
2. Tell them to test: "Press F6 to run the scene for 5 seconds"
3. Read `logs/godot_output.log` yourself
4. Analyze what you see
5. Debug based on actual behavior

---

## 🔄 Systematic Problem-Solving Framework

### Before Making ANY Changes:

1. **Read the log file** - Understand current state
2. **Identify the problem** - What exactly isn't working?
3. **Form a hypothesis** - Why might this be happening?
4. **Document your plan** - Use the template below
5. **Get confirmation** - Wait for my approval before proceeding

### Investigation Template

Always use this format when investigating:
```
## [INVESTIGATION] Issue Name

**Problem:** Clear description of what's not working

**Evidence from logs:** Quote specific lines from logs/godot_output.log
[PHYSICS] rotation: -2.37 (not changing)
[DEBUG] angular_velocity set to: 150.5

**Hypothesis:** Why this might be happening
The PinJoint2D might be overriding angular_velocity each frame

**Proposed Solution:** What I want to try
Temporarily comment out NeckJoint to test if head can rotate freely

**Risk Level:** LOW / MEDIUM / HIGH
LOW - easily reversible by uncommenting

**Test Plan:** How to verify if this works
1. Comment out joint creation in _ready()
2. Clear logs
3. Run for 5 seconds
4. Check if rotation value changes in logs

**Backup Plan:** How to revert if it doesn't work
Uncomment the joint code, try different approach
```

---

## 🚨 Risk Assessment (READ THIS CAREFULLY)

### LOW RISK ✅ (Safe to try)
- Adding debug print statements
- Reading/checking values
- Commenting out code temporarily
- Adjusting numeric constants within reasonable ranges
- Using documented Godot functions

**You can proceed after explaining your plan**

### MEDIUM RISK ⚠️ (Explain thoroughly first)
- Changing physics properties significantly
- Modifying scene structure
- Adding new nodes/components
- Changing core algorithms
- Trying "sketchy" or experimental approaches

**Required:** Detailed explanation, wait for explicit approval

### HIGH RISK 🛑 (Detailed plan + explicit approval required)
- Deleting nodes
- Major refactoring
- Changing multiple systems at once
- Anything that could break working features

**Required:** Full investigation template filled out, explicit "yes, proceed" from me

---

## 📝 Debug Print Standards

### Required Format

All debug prints MUST use clear prefixes:
```gdscript
[INIT]    - Initialization/setup
[DEBUG]   - General debugging info
[STATE]   - Variable values and state changes
[PHYSICS] - Physics-related calculations
[ERROR]   - Error conditions
[TEST]    - Specific test output
```

### Good Debug Prints ✅
```gdscript
# Clear, informative, shows values in context
print("[PHYSICS] Head - target: ", rad_to_deg(target_rotation), 
      "° current: ", rad_to_deg(rotation), "° diff: ", rad_to_deg(angle_diff), "°")

# Shows state transitions
print("[STATE] Limb selection changed: ", old_index, " -> ", new_index)

# Shows function calls with parameters
print("[DEBUG] latch_to_hold() called, hold position: ", hold.global_position)

# Shows calculations step by step
print("[TEST] Force calculation: direction=", direction, " distance=", distance, " final_force=", force)
```

### Bad Debug Prints ❌
```gdscript
# No context - what does this number mean?
print(rotation)

# Too vague - not helpful
print("doing physics")

# Spams log every frame (60 times per second!)
func _process(delta):
    print("process called")  # DON'T DO THIS
```

### Smart Debug Strategy
```gdscript
# DURING INVESTIGATION: Print detailed info
func _physics_process(delta):
    print("[PHYSICS-HEAD] is_tracking=", is_tracking, 
          " target_rot=", target_rotation,
          " current_rot=", rotation, 
          " angular_vel=", angular_velocity,
          " angle_diff=", angle_diff)

# AFTER IT WORKS: Remove or reduce prints
func _physics_process(delta):
    # Only print if something unexpected
    if is_tracking and abs(rotation - target_rotation) > 0.1:
        print("[WARNING] Head not reaching target")
```

---

## 🧹 Log Management (CRITICAL)

### Always Clear Logs Before Testing

**DO THIS EVERY TIME before a new test:**
```
Me (Claude Code): "Before testing this change, please clear the log:
> logs/godot_output.log

Then press F6 to run the scene for 5 seconds."
```

**WHY?** So we only see output from THIS test, not mixed with old data.

### Standard Test Cycle
```
1. You make code changes
2. You add debug prints with clear prefixes
3. Tell me: "Clear logs with: > logs/godot_output.log"
4. Tell me: "Press F6 to run for 5 seconds"
5. I test
6. You read fresh logs/godot_output.log
7. You analyze clean output
8. Repeat for next change
```

### No Log Buildup

- Logs are cleared before each test
- Old output doesn't accumulate
- Each test gives fresh, clean data
- Easier to spot exactly what changed

---

## 🔍 How to Read Logs Effectively

When you read `logs/godot_output.log`, look for:
```
✓ Your debug prints appear (code is running)
✓ Values look reasonable (no NaN, inf, or extreme numbers)
✓ Sequence makes sense (init → setup → process loop)
✗ Errors or warnings
✗ Missing expected output (function not called?)
✗ Values not changing when they should
✗ Unexpected behavior
```

### Example Good Analysis
```
I've read logs/godot_output.log and found:

[INIT] Head controller initialized ✓
[STATE] is_tracking: true ✓
[PHYSICS] target_rotation: -1.5708 (-90°) ✓
[PHYSICS] current rotation: -2.37 (-136°) 
[PHYSICS] angle_diff: 0.7969 (45.6°) ✓
[PHYSICS] setting angular_velocity to: 39.845 ✓
[PHYSICS] current rotation: -2.37 (-136°) ✗ NOT CHANGING

Analysis: The code executes correctly, calculations are right, 
angular_velocity is being set, but rotation doesn't change. 
This suggests something is overriding the angular_velocity after 
we set it. Most likely culprit: the PinJoint2D (neck joint).
```

---

## 💬 Communication Standards

### When Investigating
```
"I'm reading logs/godot_output.log now..."
[actually read the file]

"The logs show:
[INIT] Component initialized
[STATE] variable_x = 5
[ERROR] Null reference at line 42

This means [your analysis]. I think the issue is [hypothesis].

I'd like to try [RISK LEVEL]: [specific change]
This will help us [why this test is useful].

Should I proceed?"
```

### When You Find Something
```
"Good news! After testing with clean logs, I can see:
[PHYSICS] rotation: -2.37 → -2.15 → -1.92

The head IS rotating now! It was working all along, just very 
slowly. The issue is the rotation speed is too low. I'll increase 
the LOOK_SPEED constant from 50 to 200 and test again."
```

### When You're Stuck
```
"I've tried three approaches:
1. [Approach 1] - Result: [what happened]
2. [Approach 2] - Result: [what happened]  
3. [Approach 3] - Result: [what happened]

The logs consistently show [pattern], but the expected behavior 
isn't occurring. I'm not certain what's preventing it.

Could you manually test [specific thing] in the Godot editor to 
help narrow down the issue? Or should we try a completely 
different approach?"
```

### When Proposing Risky Changes
```
## [INVESTIGATION] Major Physics Refactor

**Problem:** Current approach not working after 5 attempts

**Evidence:** [quote logs]

**Hypothesis:** Fundamental issue with using angular_velocity in _physics_process

**Proposed Solution:** Use _integrate_forces() instead and apply 
torque through state.angular_velocity

**Risk Level:** MEDIUM - Changes physics timing but easily revertible

**Test Plan:**
1. Create new function _integrate_forces(state)
2. Move rotation logic there
3. Test and compare logs with old approach

**Backup Plan:** Keep old code commented out, can revert immediately

**Why this is worth the risk:** All attempts with current approach 
failed, Godot docs suggest _integrate_forces for direct velocity control

May I proceed?
```

---

## 📂 Project Context

### Current Status
- Phases 1-5: ✅ COMPLETE (ragdoll, limb control, holds, head tracking, stamina)
- Phase 6: 🔜 NEXT (win/lose conditions)

### Current Priority: Win/Lose Conditions (Phase 6)

**Goal:** Complete the gameplay loop with win trigger at top of wall and lose on stamina depletion.

**Your Task:**
1. Read `docs/NEXT_STEPS.md` Phase 6 section for implementation plan
2. Read `logs/godot_output.log` for current state
3. Implement win trigger, game UI, and level integration
4. Clean up debug prints after feature is verified working

### Key Files

**Log file:** `logs/godot_output.log` (your main data source)

**Documentation (in docs/ folder):**
- `ARCHITECTURE.md` - System details
- `CURRENT_ISSUES.md` - Known problems (minor only)
- `PHYSICS_TUNING_GUIDE.md` - All physics parameters
- `IMPLEMENTATION_LOG.md` - Development history
- `NEXT_STEPS.md` - Roadmap

**Scripts:**
- `scripts/player/head.gd` - ✅ Working
- `scripts/player/player.gd` - ✅ Working
- `scripts/player/limb.gd` - ✅ Working
- `scripts/environment/hold.gd` - ✅ Working (single Hold.tscn with difficulty export)
- `scripts/managers/input_manager.gd` - ✅ Working
- `scripts/managers/stamina_manager.gd` - ✅ Working
- `scripts/ui/stamina_bar.gd` - ✅ Working
- `scripts/ui/start_screen.gd` - ✅ Working

---

## ✅ Quality Checklist

Before considering any change complete:

- [ ] Code compiles without errors
- [ ] Logs cleared before testing
- [ ] Debug prints added with clear prefixes
- [ ] Tested by user (F6 pressed)
- [ ] `logs/godot_output.log` read and analyzed
- [ ] Feature works as intended OR issue identified
- [ ] No new errors in logs
- [ ] Investigation documented if still working on it
- [ ] Logs cleared after testing (ready for next iteration)

---

## 🎯 Your Immediate Next Steps

1. **Read** `docs/NEXT_STEPS.md` Phase 6 section for win/lose implementation plan
2. **Read** `logs/godot_output.log` to see current state
3. **Create** an investigation plan using the [INVESTIGATION] template
4. **Share** your plan with me
5. **Wait** for my approval
6. **Proceed** systematically
7. **Clean up** debug prints after feature is verified working

---

## 🧹 Post-Feature Cleanup

After completing and verifying a feature:
1. Remove ALL debug print statements from the feature's code
2. Keep code clean — no leftover `print()` calls in production code
3. Only leave prints gated behind a debug flag if truly needed for future debugging

---

## 🤝 Working Together

### Good Practices ✅
- Read logs after every change
- Use investigation template for complex issues
- Ask for approval before risky changes
- Clear logs before each test
- Add informative debug prints
- Explain your reasoning
- Admit when unsure
- Suggest we look at docs together

### Bad Practices ❌
- Assuming code works without checking logs
- Making changes without explanation
- Trying risky approaches without approval
- Leaving spammy debug prints
- Making multiple changes at once without testing
- Ignoring evidence in logs
- Not clearing logs between tests

---

## 🔬 Philosophy

We're debugging systematically like scientists:
1. **Observe** - Read logs, understand current behavior
2. **Hypothesize** - Form theory about why it's happening
3. **Test** - Make minimal change to test hypothesis
4. **Analyze** - Read logs, did it work?
5. **Iterate** - Try next hypothesis or refine approach
6. **Document** - Keep investigation notes clear

Small, careful steps with clear evidence beat wild experimentation.

---

## 🚀 Ready to Start!

Your first action should be:
```
"I'm starting by reading the current state. Let me check logs/godot_output.log..."
[read the file]

"I can see: [summarize what logs show]

Now reading docs/NEXT_STEPS.md for the roadmap..."
[read that file]

"Based on the logs and documentation, here's my plan:

[Use INVESTIGATION template]

Does this approach make sense? Should I proceed?"
```

Next up: Win/Lose conditions to complete the MVP! 🎯
