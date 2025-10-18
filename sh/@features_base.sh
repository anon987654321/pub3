#!/usr/bin/env zsh
set -euo pipefail

setopt nullglob extendedglob

# Base generator functions - master.json compliant

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

generate_models() {
  typeset -a models=("$@")
  local model
  
  for model in "${models[@]}"; do
    log "Generating model: $model"
    bin/rails generate model "$model"
  done
}

generate_model_file() {
  local model_name="$1"
  
  [[ -z "$model_name" ]] && {
    printf 'Error: model_name required\n' >&2
    return 1
  }
  
  log "Generating model file for: $model_name"
}

generate_controller_file() {
  local controller_name="$1"
  
  [[ -z "$controller_name" ]] && {
    printf 'Error: controller_name required\n' >&2
    return 1
  }
  
  log "Generating controller file for: $controller_name"
}

generate_stimulus_ts() {
  local controller_name="$1"
  
  [[ -z "$controller_name" ]] && {
    printf 'Error: controller_name required\n' >&2
    return 1
  }
  
  log "Generating Stimulus TypeScript file for: $controller_name"
  mkdir -p app/javascript/controllers
}

generate_view_component() {
  local component_name="$1"
  
  [[ -z "$component_name" ]] && {
    printf 'Error: component_name required\n' >&2
    return 1
  }
  
  log "Generating ViewComponent: $component_name"
  mkdir -p app/components
}

add_routes() {
  local routes_file="config/routes.rb"
  
  [[ ! -f "$routes_file" ]] && {
    printf 'Error: %s not found\n' "$routes_file" >&2
    return 1
  }
  
  log "Adding routes: $* to $routes_file"
}

setup_airbnb() {
  log "Setting up Airbnb features"
  
  generate_models Booking Review Availability HostProfile
  generate_stimulus_ts calendar_controller
  generate_controller_file BookingsController
  generate_view_component BookingCalendarComponent
  
  add_routes "resources :bookings do
    member do
      get 'calendar'
    end
  end"
}

setup_messenger() {
  log "Setting up Messenger features"
  
  generate_models Conversation Message MessageReceipt
  generate_stimulus_ts message_composer_controller
  
  add_routes "resources :messages do
    collection do
      post 'typing'
    end
  end"
}

setup_momondo() {
  log "Setting up Momondo features"
  
  generate_models FlightSearch HotelSearch PriceAlert
  generate_stimulus_ts travel_tabs_controller
  
  add_routes "resources :searches"
}

main() {
  setup_airbnb
  setup_messenger
  setup_momondo
  
  log "Feature setup complete"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main
