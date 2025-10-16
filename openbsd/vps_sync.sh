#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════╗

# ║  VPS Sync - Complete G:\pub Mirror to Production VPS         ║

# ║  Target: dev@185.52.176.18:/home/dev/pub                     ║

# ╚═══════════════════════════════════════════════════════════════╝

#

# MANIFEST - What Gets Synced:

#   ✓ openbsd.sh           - Complete OpenBSD infrastructure setup

#   ✓ repligen/            - AI generation (scrape, LoRA, masterpieces)

#   ✓ postpro/             - Cinematic image processing (libvips)

#   ✓ dilla/               - J Dilla beat generator (FluidSynth)

#   ✓ botnet/              - Multi-bot orchestration (LangChain)

#   ✓ master.json          - Global configuration

#   ✓ [Rails apps]/        - All Rails applications

#   ✓ *.sh scripts         - All deployment automation

#

# EXCLUDED (auto-generated/temp):

#   ✗ .git/, logs/, tmp/, node_modules/

#   ✗ *.db (SQLite - regenerated on VPS)

#   ✗ *.log files

#

# USAGE:

#   ./vps_sync.sh          # Mirror everything to VPS

#

# POST-SYNC STEPS:

#   ssh dev@185.52.176.18

#   cd ~/pub

#   ./openbsd.sh --pre-point    # Setup infrastructure

#   ./openbsd.sh --post-point   # Configure TLS & services

#

set -euo pipefail

VPS_HOST="185.52.176.18"
VPS_USER="dev"

VPS_BASE="/home/dev/pub"

LOCAL_BASE="/g/pub"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         COMPLETE MIRROR - G:\pub → VPS                       ║"

echo "║              dev@185.52.176.18:/home/dev/pub                 ║"

echo "╚═══════════════════════════════════════════════════════════════╝"

echo ""

# Test connection
echo "🔌 Testing VPS connection..."

if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" "echo 'Connected'" 2>/dev/null; then

    echo "❌ Cannot connect to VPS"

    exit 1

fi

echo "✓ Connection successful"
echo ""

# Create base directory on VPS
echo "📁 Creating base directory on VPS..."

ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_BASE"

# Show what will be synced
echo "📊 Analyzing local directory..."

cd "$LOCAL_BASE"

TOTAL_SIZE=$(du -sh . 2>/dev/null | cut -f1)
FILE_COUNT=$(find . -type f 2>/dev/null | wc -l)

echo "Local directory: $LOCAL_BASE"
echo "Total size: $TOTAL_SIZE"

echo "Files: $FILE_COUNT"

echo ""

# Confirm
read -p "Proceed with full mirror? (Y/n): " -n 1 -r

echo

if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then

    echo "Cancelled."

    exit 0

fi

echo ""
echo "🚀 Starting rsync mirror..."

echo "=" * 70

echo ""

# Rsync with progress
rsync -avz --progress \

    --exclude='.git/' \

    --exclude='*.log' \

    --exclude='tmp/' \

    --exclude='log/' \

    --exclude='node_modules/' \

    --exclude='*.db-journal' \

    --exclude='.DS_Store' \

    --exclude='Thumbs.db' \

    --exclude='*.swp' \

    --exclude='*.swo' \

    --exclude='*~' \

    --exclude='.vscode/' \

    --exclude='.idea/' \

    --exclude='__pycache__/' \

    --exclude='*.pyc' \

    --exclude='coverage/' \

    --exclude='.sass-cache/' \

    --exclude='repligen.db' \

    --exclude='botnet.db' \

    -e "ssh -o StrictHostKeyChecking=no" \

    "$LOCAL_BASE/" \

    "$VPS_USER@$VPS_HOST:$VPS_BASE/"

RSYNC_EXIT=$?
echo ""
echo "=" * 70

if [ $RSYNC_EXIT -eq 0 ]; then
    echo "✓ Mirror complete!"

else

    echo "⚠️  Rsync completed with warnings (exit code: $RSYNC_EXIT)"

fi

echo ""
echo "🔧 Setting permissions on VPS..."

ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" << 'ENDSSH'
cd ~/pub

# Make all .sh and .rb files executable
find . -type f -name "*.sh" -exec chmod +x {} \;

find . -type f -name "*.rb" -exec chmod +x {} \;

# Specific scripts
chmod +x openbsd.sh 2>/dev/null || true

chmod +x repligen/*.rb 2>/dev/null || true

chmod +x postpro/postpro.rb 2>/dev/null || true

chmod +x dilla/dilla.rb 2>/dev/null || true

chmod +x botnet/botnet.rb 2>/dev/null || true

# Create necessary directories
mkdir -p logs tmp output photos repligen/output postpro/output dilla/dilla_output botnet/logs

echo "✓ Permissions set"
ENDSSH

echo ""
echo "📋 Creating deployment manifest..."

ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" << 'ENDSSH'
cd ~/pub

cat > MANIFEST.txt << 'EOF'
╔═══════════════════════════════════════════════════════════════╗

║              COMPLETE MIRROR DEPLOYMENT                      ║

║                   $(date)                        ║

╚═══════════════════════════════════════════════════════════════╝

MIRRORED STRUCTURE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/home/dev/pub/
├── openbsd.sh          OpenBSD infrastructure & Rails apps

├── vps_sync.sh         This mirror script

├── repligen/           AI generation studio (scrape, LoRA, chains)

├── postpro/            Cinematic post-processing (libvips)

├── dilla/              J Dilla beat generator (FluidSynth)

├── botnet/             Multi-bot orchestration

├── master.json         Global configuration

└── [Rails apps]        All Rails applications

PROJECT STATUS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ OpenBSD infrastructure
✓ Repligen (AI generation)

✓ Postpro (image processing)

✓ Dilla (beat generation)

✓ Botnet (bot management)

✓ Master configuration

✓ All deployment scripts

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Set API keys in ~/.profile:
   export REPLICATE_API_TOKEN="..."

   export ANTHROPIC_API_KEY="..."

2. Run OpenBSD setup:
   cd ~/pub

   ./openbsd.sh --pre-point

3. Install project dependencies:
   cd ~/pub/repligen && gem33 install sqlite3 ferrum --no-document

   cd ~/pub/postpro && gem33 install ruby-vips tty-prompt --no-document

   cd ~/pub/dilla && gem33 install midilib --no-document

4. Test each project:
   cd ~/pub/repligen && ruby33 repligen.rb --stats

   cd ~/pub/postpro && ruby33 postpro.rb

   cd ~/pub/dilla && ruby33 dilla.rb list

5. Run post-point setup:
   cd ~/pub

   ./openbsd.sh --post-point

USEFUL COMMANDS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check directory structure
tree -L 2 ~/pub

# View this manifest
cat ~/pub/MANIFEST.txt

# Re-sync from local machine
./vps_sync.sh

# Full deployment
cd ~/pub && ./deploy_all.sh

EOF
cat MANIFEST.txt
ENDSSH

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"

echo "║                MIRROR COMPLETE! 🎉                           ║"

echo "╚═══════════════════════════════════════════════════════════════╝"

echo ""

echo "📍 VPS Location: $VPS_USER@$VPS_HOST:$VPS_BASE"

echo ""

echo "🔗 SSH and view:"

echo "  ssh $VPS_USER@$VPS_HOST"

echo "  cd ~/pub"

echo "  cat MANIFEST.txt"

echo ""

echo "📚 Next steps:"

echo "  1. SSH into VPS"

echo "  2. Set API keys"

echo "  3. Run: cd ~/pub && ./openbsd.sh --pre-point"

echo ""

