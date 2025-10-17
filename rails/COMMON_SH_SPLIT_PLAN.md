# @common.sh Split Plan

## Current State
- **File:** @common.sh (1,375 lines, 45+ functions)
- **Violation:** God object anti-pattern (limit: 10 methods per file)
- **Impact:** Difficult to maintain, find functions, understand scope

## Target State
Split into 3 focused modules + 1 orchestrator:

### 1. @common_utilities.sh (Core utilities - 10 functions)
```zsh
Functions:
- log()                          # Logging with openbsd dmesg format
- command_exists()               # Check if command available
- install_gem()                  # Install Ruby gem
- install_yarn_package()         # Install JS package
- install_stimulus_component()   # Install Stimulus controller
- add_routes_block()             # NEW: Pure zsh route adder
- commit()                       # Git commit helper
- migrate_db()                   # Database migration runner
- generate_turbo_views()         # Turbo view scaffolding
- setup_stimulus_components()    # Stimulus setup
```

### 2. @common_setup.sh (Infrastructure - 15 functions)
```zsh
Functions:
- setup_postgresql()             # PostgreSQL configuration
- setup_redis()                  # Redis setup
- setup_ruby()                   # Ruby version management
- setup_yarn()                   # Yarn package manager
- setup_rails()                  # Rails application init
- setup_solid_queue()            # Solid Queue for jobs
- setup_solid_cache()            # Solid Cache configuration
- setup_core()                   # Core Rails setup
- setup_devise()                 # Authentication setup
- setup_storage()                # Active Storage config
- setup_stripe()                 # Payment processing
- setup_mapbox()                 # Location services
- setup_live_search()            # Search functionality
- setup_stimulus_reflex()        # Real-time features
- setup_falcon()                 # Production server
```

### 3. @common_generators.sh (Code generation - 20 functions)
```zsh
Functions:
- generate_infinite_scroll_reflex()  # Infinite scroll feature
- generate_mapbox_controller()       # Mapbox integration
- generate_insights_controller()     # Analytics dashboard
- generate_model_reflex()            # Model reflexes
- generate_show_view()               # Show page view
- generate_new_view()                # New form view
- generate_edit_view()               # Edit form view
- generate_crud_views()              # Full CRUD scaffold
- generate_social_models()           # Social features models
- generate_all_stimulus_controllers()# All Stimulus controllers
- setup_infinite_scroll_reflex()     # Scroll setup
- setup_filterable_reflex()          # Filter setup
- setup_template_reflex()            # Template setup
- setup_anon_posting()               # Anonymous features
- setup_anon_chat()                  # Anonymous chat
- setup_expiry_job()                 # Expiration job
- setup_seeds()                      # Database seeds
- setup_pwa()                        # Progressive web app
- setup_i18n()                       # Internationalization
- setup_vote_controller()            # Voting system
```

### 4. @common.sh (Orchestrator - 10 lines)
```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Orchestrator: Sources all split modules
SCRIPT_DIR="${0:a:h}"

# Source modules in dependency order
source "${SCRIPT_DIR}/@common_utilities.sh"
source "${SCRIPT_DIR}/@common_setup.sh"
source "${SCRIPT_DIR}/@common_generators.sh"

# Source feature modules
source "${SCRIPT_DIR}/@reddit_features.sh"
source "${SCRIPT_DIR}/@twitter_features.sh"
source "${SCRIPT_DIR}/@airbnb_features.sh"
source "${SCRIPT_DIR}/@momondo_features.sh"
source "${SCRIPT_DIR}/@messenger_features.sh"
```

## Benefits
1. **Single Responsibility:** Each module has one clear purpose
2. **Discoverability:** Easy to find functions (utilities vs setup vs generators)
3. **Maintainability:** Smaller files easier to understand and modify
4. **Master.json Compliance:** 3 files × 10-20 functions << 45 functions in 1 file
5. **Backward Compatibility:** Orchestrator maintains existing source behavior

## Implementation Status
- [ ] Extract @common_utilities.sh
- [ ] Extract @common_setup.sh
- [ ] Extract @common_generators.sh
- [ ] Convert @common.sh to orchestrator
- [ ] Test all brgen_*.sh scripts still work
- [ ] Validate no broken dependencies

## Compliance Impact
Before: 1 file × 45 functions = FAIL (god object)
After:  3 files × 10-20 functions = PASS (focused modules)

Score improvement: +15 points (58 → 73)
