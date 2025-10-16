#!/usr/bin/env bash
# Manual Deployment Script - Step-by-step deployment to VPS

# Use when sshpass is not available or for manual control

set -euo pipefail
VPS_HOST="185.52.176.18"
VPS_USER="dev"

VPS_BASE="/home/dev"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         MANUAL DEPLOYMENT - Step-by-Step Guide              ║"

echo "║              dev@185.52.176.18 (OpenBSD)                     ║"

echo "╚═══════════════════════════════════════════════════════════════╝"

echo ""

echo "This script will guide you through manual deployment."
echo "You'll need to run SSH commands yourself."

echo ""

read -p "Press Enter to continue..."

# ============================================================================
# STEP 1: TEST CONNECTION

# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "STEP 1: Test VPS Connection"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""

echo "Run this command to test connection:"

echo ""

echo "  ssh $VPS_USER@$VPS_HOST"

echo ""

echo "Password: Test1234"

echo ""

read -p "Did the connection work? (y/n): " response

if [[ ! $response =~ ^[Yy]$ ]]; then

    echo "❌ Cannot continue without VPS access"

    exit 1

fi

# ============================================================================
# STEP 2: DEPLOY OPENBSD.SH

# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "STEP 2: Deploy OpenBSD Bootstrap"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""

echo "Run these commands:"

echo ""

echo "  scp openbsd.sh $VPS_USER@$VPS_HOST:~/"

echo "  ssh $VPS_USER@$VPS_HOST"

echo "  chmod +x openbsd.sh"

echo "  ./openbsd.sh --pre-point"

echo ""

read -p "Press Enter when done..."

# ============================================================================
# STEP 3: DEPLOY REPLIGEN

# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "STEP 3: Deploy Repligen"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""

echo "Run these commands:"

echo ""

echo "  ssh $VPS_USER@$VPS_HOST 'mkdir -p ~/repligen'"

echo "  scp repligen/repligen.rb $VPS_USER@$VPS_HOST:~/repligen/"

echo "  scp repligen/repligen_nlu.rb $VPS_USER@$VPS_HOST:~/repligen/"

echo "  scp repligen/repligen_v2.rb $VPS_USER@$VPS_HOST:~/repligen/"

echo "  scp repligen/scrape_replicate_explore.rb $VPS_USER@$VPS_HOST:~/repligen/"

echo "  scp repligen/README*.md $VPS_USER@$VPS_HOST:~/repligen/"

echo "  ssh $VPS_USER@$VPS_HOST 'gem33 install sqlite3 ferrum --no-document'"

echo ""

read -p "Press Enter when done..."

# ============================================================================
# STEP 4: DEPLOY POSTPRO

# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "STEP 4: Deploy Postpro"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""

echo "Run these commands:"

echo ""

echo "  ssh $VPS_USER@$VPS_HOST 'mkdir -p ~/postpro'"

echo "  scp postpro/postpro.rb $VPS_USER@$VPS_HOST:~/postpro/"

echo "  scp postpro/postpro_README.md $VPS_USER@$VPS_HOST:~/postpro/"

echo "  ssh $VPS_USER@$VPS_HOST 'doas pkg_add vips'"

echo "  ssh $VPS_USER@$VPS_HOST 'gem33 install ruby-vips tty-prompt --no-document'"

echo ""

read -p "Press Enter when done..."

# ============================================================================
# STEP 5: DEPLOY DILLA

# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "STEP 5: Deploy Dilla"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""

echo "Run these commands:"

echo ""

echo "  ssh $VPS_USER@$VPS_HOST 'mkdir -p ~/dilla'"

echo "  scp dilla/dilla.rb $VPS_USER@$VPS_HOST:~/dilla/"

echo "  scp dilla/dilla_README.md $VPS_USER@$VPS_HOST:~/dilla/"

echo "  ssh $VPS_USER@$VPS_HOST 'doas pkg_add fluidsynth sox'"

echo "  ssh $VPS_USER@$VPS_HOST 'gem33 install midilib --no-document'"

echo ""

read -p "Press Enter when done..."

# ============================================================================
# STEP 6: DEPLOY BOTNET

# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "STEP 6: Deploy Botnet"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""

echo "Run these commands:"

echo ""

echo "  ssh $VPS_USER@$VPS_HOST 'mkdir -p ~/botnet/logs'"

echo "  # Note: botnet.rb needs to be completed first"

echo ""

read -p "Press Enter when done..."

# ============================================================================
# FINAL STEPS

# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "FINAL: Post-Deployment Configuration"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""

echo "SSH into your VPS and run:"

echo ""

echo "  ssh $VPS_USER@$VPS_HOST"

echo ""

echo "Then set API keys:"

echo ""

echo '  echo "export REPLICATE_API_TOKEN=\"your_token\"" >> ~/.profile'

echo '  echo "export ANTHROPIC_API_KEY=\"your_key\"" >> ~/.profile'

echo "  source ~/.profile"

echo ""

echo "Run post-point setup:"

echo ""

echo "  ./openbsd.sh --post-point"

echo ""

echo "Test each tool:"

echo ""

echo "  cd ~/repligen && ruby33 repligen.rb --stats"

echo "  cd ~/postpro && ruby33 postpro.rb"

echo "  cd ~/dilla && ruby33 dilla.rb list"

echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║             MANUAL DEPLOYMENT COMPLETE! 🎉                   ║"

echo "╚═══════════════════════════════════════════════════════════════╝"

echo ""

