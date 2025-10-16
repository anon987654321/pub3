# BACKUP RESTORATION PLAN

## Instructions for Extracting .tgz Archives from pub/__OLD_BACKUPS

### Priority 1: Extract egpt_20240806.tgz
- **Destination:** pub3/aight/
- **Rename:** AI3 → Aight, ai3 → aight
- **Command:**  
tar -xzf pub/__OLD_BACKUPS/egpt_20240806.tgz -C pub3/aight/

### Priority 2: Selectively Extract brgen_ANCIENT_20240622.tgz
- **Destination:** pub3/rails/brgen.sh
- **Notes:** Extract only generators and scripts, NOT the full Rails app.
- **Command:**  
tar -xzf pub/__OLD_BACKUPS/brgen_ANCIENT_20240622.tgz --wildcards --no-anchored 'generators/*' 'scripts/*' -C pub3/rails/

### Priority 3: Extract openbsd_20240806.tgz
- **Destination:** pub3/openbsd/
- **Command:**  
tar -xzf pub/__OLD_BACKUPS/openbsd_20240806.tgz -C pub3/openbsd/

### Priority 4: Extract sh_20240806.tgz and Compare
- **Destination:** pub3/sh/
- **Command:**  
tar -xzf pub/__OLD_BACKUPS/sh_20240806.tgz -C pub3/sh/
- **Comparison:** Use `diff` or similar tools to compare with existing pub3/sh/

### Priority 5: Extract __docs_20240804.tgz
- **Destination:** pub3/bplans/
- **Notes:** Extract business plan markdown files.
- **Command:**  
tar -xzf pub/__OLD_BACKUPS/__docs_20240804.tgz -C pub3/bplans/

### Priority 6: Rails App Backups
- **Note:** These are for reference only; do not restore full apps.

---

## Extraction Commands
- Use `tar -xzf` for extraction.
- Use `find` and `sed` for renaming files as needed.

## Master.json Compliance Checklist
- **Consolidation > Fragmentation**
- **Anti-Sectionitis:** Ensure documentation is cohesive and clear.

## Safety Rules
- Always perform credential scanning before restoration.
- Validate extracted files against known good checksums.

## Post-Restoration Verification Commands
- Check the integrity of files using `md5sum` or `sha256sum`.
- Ensure all scripts are executable and properly tested.

## Timeline Estimates
- **Total Time:** 7-9 hours

### Note:
- Archives date from 2024-06-22 to 2024-08-06.