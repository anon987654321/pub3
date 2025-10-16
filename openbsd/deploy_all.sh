#!/usr/bin/env bash
# Master Deployment Script - Deploy ALL projects to VPS

# Target: dev@185.52.176.18 (OpenBSD)

set -euo pipefail
VPS_HOST="185.52.176.18"
VPS_USER="dev"

VPS_PASS="Test1234"

VPS_BASE="/home/dev"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         MASTER DEPLOYMENT - All Projects to VPS              ║"

echo "║              dev@185.52.176.18 (OpenBSD)                     ║"

echo "╚═══════════════════════════════════════════════════════════════╝"

echo ""

# Test connection
echo "🔌 Testing VPS connection..."

if ! sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \

     "$VPS_USER@$VPS_HOST" "echo '✓ Connection successful'" 2>/dev/null; then

    echo "❌ Cannot connect to VPS"

    echo "   Check: ssh $VPS_USER@$VPS_HOST"

    exit 1

fi

echo ""
# ============================================================================
# DEPLOY OPENBSD BOOTSTRAP

# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1/5: OPENBSD BOOTSTRAP & INFRASTRUCTURE"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📦 Deploying openbsd.sh..."
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no \

    openbsd.sh "$VPS_USER@$VPS_HOST:$VPS_BASE/"

echo "🚀 Running pre-point setup (Ruby, PostgreSQL, Redis, DNS)..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "chmod +x openbsd.sh && ./openbsd.sh --pre-point"

echo "✓ OpenBSD infrastructure ready"
echo ""

# ============================================================================
# DEPLOY REPLIGEN

# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2/5: REPLIGEN - AI Generation Studio"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📦 Creating repligen directory..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "mkdir -p $VPS_BASE/repligen"

echo "📤 Uploading repligen files..."
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no \

    repligen/repligen.rb \

    repligen/repligen_nlu.rb \

    repligen/repligen_v2.rb \

    repligen/scrape_replicate_explore.rb \

    repligen/setup.sh \

    repligen/README*.md \

    repligen/QUICKSTART.md \

    "$VPS_USER@$VPS_HOST:$VPS_BASE/repligen/"

echo "🔧 Installing dependencies..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "cd $VPS_BASE/repligen && gem33 install sqlite3 ferrum --no-document"

echo "✓ Repligen deployed"
echo ""

# ============================================================================
# DEPLOY POSTPRO

# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3/5: POSTPRO - Cinematic Post-Processing"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📦 Creating postpro directory..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "mkdir -p $VPS_BASE/postpro"

echo "📤 Uploading postpro files..."
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no \

    postpro/postpro.rb \

    postpro/postpro_README.md \

    "$VPS_USER@$VPS_HOST:$VPS_BASE/postpro/"

# Upload camera profiles if they exist
if [ -d "postpro/__camera_profiles" ]; then

    echo "📸 Uploading camera profiles..."

    sshpass -p "$VPS_PASS" scp -r -o StrictHostKeyChecking=no \

        postpro/__camera_profiles \

        "$VPS_USER@$VPS_HOST:$VPS_BASE/postpro/"

fi

echo "🔧 Installing libvips..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "doas pkg_add vips || echo 'vips may already be installed'"

echo "💎 Installing ruby-vips gem..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "gem33 install ruby-vips tty-prompt --no-document"

echo "✓ Postpro deployed"
echo ""

# ============================================================================
# DEPLOY DILLA

# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4/5: DILLA - J Dilla Beat Generator"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📦 Creating dilla directory..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "mkdir -p $VPS_BASE/dilla"

echo "📤 Uploading dilla files..."
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no \

    dilla/dilla.rb \

    dilla/dilla_README.md \

    "$VPS_USER@$VPS_HOST:$VPS_BASE/dilla/"

echo "🔧 Installing audio tools..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "doas pkg_add fluidsynth sox midilib || echo 'Audio tools may already be installed'"

echo "💎 Installing midilib gem..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "gem33 install midilib --no-document"

echo "✓ Dilla deployed"
echo ""

# ============================================================================
# DEPLOY BOTNET

# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5/5: BOTNET - Multi-Bot Orchestration"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📦 Creating botnet directory..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" \

    "mkdir -p $VPS_BASE/botnet/logs"

echo "📤 Uploading botnet files..."
if [ -f "botnet/botnet_full.rb" ]; then

    sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no \

        botnet/botnet_full.rb \

        "$VPS_USER@$VPS_HOST:$VPS_BASE/botnet/botnet.rb"

else

    echo "⚠️  botnet_full.rb not found, skipping..."

fi

echo "✓ Botnet structure created"
echo ""

# ============================================================================
# POST-DEPLOYMENT SETUP

# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "POST-DEPLOYMENT: Final Configuration"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "🔐 Setting permissions..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" << 'ENDSSH'

cd $HOME

chmod +x openbsd.sh

chmod +x repligen/*.rb repligen/*.sh || true

chmod +x postpro/*.rb || true

chmod +x dilla/*.rb || true

chmod +x botnet/*.rb || true

ENDSSH

echo "📋 Creating deployment manifest..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" << 'ENDSSH'

cat > $HOME/DEPLOYED.txt << EOF

╔═══════════════════════════════════════════════════════════════╗

║              DEPLOYMENT MANIFEST - $(date)         ║

╚═══════════════════════════════════════════════════════════════╝

PROJECTS DEPLOYED:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. OPENBSD BOOTSTRAP (openbsd.sh)
   Location: ~/openbsd.sh

   Purpose: System setup, Rails apps, DNS/DNSSEC

   Run: ./openbsd.sh --pre-point

2. REPLIGEN (AI Generation Studio)
   Location: ~/repligen/

   Files: repligen.rb, repligen_nlu.rb, repligen_v2.rb

   Purpose: Scrape Replicate, train LoRA, create masterpieces

   Run: ruby33 repligen/repligen.rb

3. POSTPRO (Cinematic Post-Processing)
   Location: ~/postpro/

   Files: postpro.rb

   Purpose: Film-grade image processing with libvips

   Run: ruby33 postpro/postpro.rb

4. DILLA (J Dilla Beat Generator)
   Location: ~/dilla/

   Files: dilla.rb

   Purpose: Generate Dilla-style beats with FluidSynth

   Run: ruby33 dilla/dilla.rb gen donuts_classic C 95

5. BOTNET (Multi-Bot Orchestration)
   Location: ~/botnet/

   Files: botnet.rb

   Purpose: Customer service bot management

   Run: ruby33 botnet/botnet.rb

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Set API keys:
   export REPLICATE_API_TOKEN="..."

   export ANTHROPIC_API_KEY="..."

2. Run post-point setup:
   ./openbsd.sh --post-point

3. Test each tool:
   cd repligen && ruby33 repligen.rb --stats

   cd postpro && ruby33 postpro.rb --help

   cd dilla && ruby33 dilla.rb list

EOF
cat $HOME/DEPLOYED.txt
ENDSSH

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"

echo "║             DEPLOYMENT COMPLETE! 🎉                          ║"

echo "╚═══════════════════════════════════════════════════════════════╝"

echo ""

echo "📊 Summary:"

echo "  ✓ OpenBSD infrastructure"

echo "  ✓ Repligen (AI generation)"

echo "  ✓ Postpro (image processing)"

echo "  ✓ Dilla (beat generation)"

echo "  ✓ Botnet (bot orchestration)"

echo ""

echo "📍 VPS: $VPS_USER@$VPS_HOST"

echo "📁 Base: $VPS_BASE"

echo ""

echo "🔗 SSH into VPS:"

echo "  ssh $VPS_USER@$VPS_HOST"

echo ""

echo "📚 View deployment manifest:"

echo "  ssh $VPS_USER@$VPS_HOST 'cat ~/DEPLOYED.txt'"

echo ""

