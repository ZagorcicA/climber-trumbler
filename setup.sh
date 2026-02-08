#!/bin/bash
# Climber Trumbler - One-time project setup
# Run this after cloning or pulling for the first time
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh

echo "=== Climber Trumbler Setup ==="
echo ""

# 1. Install git hooks
echo "[1/3] Installing git hooks..."
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "  -> Pre-commit hook installed (strips Godot UIDs)"

# 2. Clear Godot UID cache
echo "[2/3] Clearing Godot UID cache..."
rm -f .godot/uid_cache.bin
echo "  -> UID cache cleared (Godot will regenerate on next open)"

# 3. Create logs directory if missing
echo "[3/3] Ensuring logs directory exists..."
mkdir -p logs
touch logs/.gitkeep
echo "  -> logs/ directory ready"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Open Godot:  godot --path . --editor 2>&1 | tee logs/godot_output.log"
echo "  2. Start Claude Code in another terminal:  claude"
echo "  3. Start building!"
echo ""
