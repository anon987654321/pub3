# Archive Restoration Guide

This guide explains how to restore critical archives from the `pub/__OLD_BACKUPS` repository into `pub3`.

## Overview

We have implemented two methods for restoring archives:

1. **GitHub Workflow** (`.github/workflows/restore_old_backups.yml`) - Automated cloud-based restoration
2. **Local Shell Script** (`sh/restore_phase0.sh`) - Manual local restoration

Both methods perform the same selective extraction with identical security guardrails.

## Archives Restored

### Phase 0: Critical Production Assets

- **BRGEN_OLD.zip** → `rails/brgen_production/`
  - Database schema (`db/schema.rb`)
  - Generators (`lib/generators/`)
  - Rake tasks (`lib/tasks/*.rake`)
  - Sanitized initializers (`config/initializers/`)
  - Deployment configuration (`Capfile`, `config/deploy/`)
  - Dependencies reference (`Gemfile`, `Gemfile.lock`)

- **rails_amber_20240806.tgz** → `rails/amber/`
  - Complete Amber application
  - `amber.sh` deployment script
  - `README.md` documentation

- **rails___shared_20240806.tgz** → `rails/__shared/`
  - Shared Rails components

### Phase 1: Essential Components

- **egpt_20240806.tgz** → `aight/`
  - Extracted with AI3→Aight renames
  - Both case-sensitive (`AI3`→`Aight`) and lowercase (`ai3`→`aight`) variants

- **openbsd_20240806.tgz** → `openbsd/`
  - Merged with no-overwrite policy
  - Existing files are preserved

## Security Guardrails

Both restoration methods implement comprehensive security checks:

### Files Excluded
- `.git/` directories
- `config/master.key`
- `config/credentials.yml.enc`
- `.env*` files
- `node_modules/`
- `vendor/`
- `log/`
- `tmp/`

### Validations
1. **Credential Scan**: Searches for `api_key`, `password`, `secret`, `token` patterns
2. **File Size Check**: Rejects files larger than 10MB
3. **Secret Sanitization**: Skips initializers containing inline secrets

## Method 1: GitHub Workflow (Recommended)

### Prerequisites
- Access to the `anon987654321/pub3` repository
- Permissions to trigger workflows

### Steps

1. Navigate to the Actions tab in GitHub:
   ```
   https://github.com/anon987654321/pub3/actions
   ```

2. Select "Restore Old Backups" workflow

3. Click "Run workflow" → Select branch `main` → Click "Run workflow"

4. Monitor the workflow execution in the Actions tab

5. Once complete, review the automatically created PR:
   - Branch: `auto/restore-old-backups`
   - Title: "feat: restore critical archives from pub/__OLD_BACKUPS (automated)"

6. Review the changes in the PR and merge if satisfied

### Workflow Features
- ✅ Runs on `ubuntu-latest`
- ✅ Downloads archives from `raw.githubusercontent.com`
- ✅ Performs all extractions with security checks
- ✅ Creates a detailed PR with restoration summary
- ✅ Fully auditable and repeatable

## Method 2: Local Shell Script

### Prerequisites
- Local clone of both `pub3` and `pub` repositories
- POSIX-compatible shell (bash, zsh, sh)
- Standard Unix tools: `tar`, `unzip`, `sed`, `grep`, `find`

### Steps

1. Ensure you have both repositories cloned:
   ```bash
   # Recommended directory structure:
   ~/projects/
   ├── pub/          # Contains __OLD_BACKUPS/
   └── pub3/         # This repository
   ```

2. Navigate to the `pub3` repository:
   ```bash
   cd ~/projects/pub3
   ```

3. Run the restoration script:
   ```bash
   # If pub is at ../pub (default):
   ./sh/restore_phase0.sh
   
   # If pub is elsewhere:
   ./sh/restore_phase0.sh /path/to/pub
   ```

4. Review the script output:
   - Archive validation
   - Extraction progress
   - Security scan results
   - Summary of changes

5. Inspect the extracted files:
   ```bash
   git status
   git diff
   ```

6. If satisfied, commit the changes:
   ```bash
   git add .
   git commit -m "feat: restore archives from pub/__OLD_BACKUPS"
   git push
   ```

### Script Features
- ✅ Validates archive presence before extraction
- ✅ Colored output for better readability
- ✅ Detailed logging of all operations
- ✅ Same security checks as workflow
- ✅ Temporary directory cleanup
- ✅ Safe by default (no forced overwrites)

## Expected Directory Structure After Restoration

```
pub3/
├── rails/
│   ├── brgen_production/
│   │   ├── db/
│   │   │   └── schema.rb
│   │   ├── lib/
│   │   │   ├── generators/
│   │   │   └── tasks/
│   │   ├── config/
│   │   │   └── initializers/
│   │   ├── deploy/
│   │   │   ├── Capfile
│   │   │   └── config/deploy/
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   └── PRODUCTION_ANALYSIS.md
│   ├── amber/
│   │   ├── [amber app files]
│   │   ├── amber.sh
│   │   └── README.md
│   └── __shared/
│       ├── @airbnb_features.sh
│       ├── @common.sh
│       ├── @reddit_features.sh
│       └── @twitter_features.sh
├── aight/
│   └── [egpt files with AI3→Aight renames]
└── openbsd/
    └── [merged openbsd files]
```

## Troubleshooting

### Workflow fails with 404 errors
**Cause**: Archives not present in `pub/__OLD_BACKUPS` or incorrect URLs

**Solution**: Verify archives exist in the pub repository:
```
https://github.com/anon987654321/pub/tree/main/__OLD_BACKUPS
```

### Credential scan fails
**Cause**: Extracted files contain secrets

**Solution**: Review the flagged files and ensure no real credentials are present. If they're false positives, update the scan pattern.

### File size check fails
**Cause**: Archive contains files larger than 10MB

**Solution**: Review the large files. If they're necessary, increase the size limit in both the workflow and script.

### Local script: "Pub repository not found"
**Cause**: Incorrect path to pub repository

**Solution**: Provide the correct path:
```bash
./sh/restore_phase0.sh /correct/path/to/pub
```

### Local script: "Missing archive: <filename>"
**Cause**: Archive not present in `__OLD_BACKUPS`

**Solution**: Ensure all required archives are present in `pub/__OLD_BACKUPS/`

## Re-running Restoration

Both methods are **idempotent** - they can be run multiple times safely:

- The workflow creates a new PR each time (previous PRs remain)
- The local script overwrites previously extracted files
- OpenBSD files use no-overwrite policy (existing files preserved)

## Rollback

To rollback a restoration:

1. **If using workflow**: Close/reject the PR without merging

2. **If using local script**:
   ```bash
   git checkout main
   git clean -fd rails/brgen_production rails/amber
   # Or reset specific directories:
   git checkout main -- rails/brgen_production
   git checkout main -- rails/amber
   ```

## Support

For issues or questions:
- Open an issue in the `pub3` repository
- Review workflow logs in GitHub Actions
- Check script output for detailed error messages

## References

- **Workflow File**: `.github/workflows/restore_old_backups.yml`
- **Shell Script**: `sh/restore_phase0.sh`
- **Source Archives**: `https://github.com/anon987654321/pub/tree/main/__OLD_BACKUPS`
- **Analysis Document**: `rails/brgen_production/PRODUCTION_ANALYSIS.md` (created after restoration)
