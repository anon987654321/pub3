# Stimulus JavaScript Framework Guide

Stimulus is a modest JavaScript framework for the HTML you already have. Part of Hotwire, it works alongside Turbo to provide reactive behavior without complex state management.

## Core Concepts

### The Stimulus Trinity

1. **Controllers** - JavaScript classes that add behavior
2. **Actions** - Event handlers defined in HTML
3. **Targets** - Important DOM elements referenced by controllers
4. **Values** - Typed data attributes for state

## Controller Lifecycle

**Critical pattern** from `master.json`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. Initialize - setup constants, NO DOM access
  initialize() {
    this.apiEndpoint = "/api/endpoint"
    this.refreshInterval = 5000
  }
  
  // 2. Connect - setup listeners, DOM manipulation, API calls
  connect() {
    this.element.addEventListener("turbo:submit-end", this.handleSubmit)
    this.startPolling()
  }
  
  // 3. Actions - event handlers
  handleClick(event) {
    event.preventDefault()
    // Implementation
  }
  
  // 4. Disconnect - ALWAYS cleanup timers, listeners
  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.handleSubmit)
    this.stopPolling()
  }
  
  // Private helpers
  startPolling() {
    this.pollingTimer = setInterval(() => {
      this.refresh()
    }, this.refreshInterval)
  }
  
  stopPolling() {
    if (this.pollingTimer) {
      clearInterval(this.pollingTimer)
    }
  }
}
```

**Critical**: Always cleanup in `disconnect()` to prevent memory leaks.

## Lifecycle Methods

### initialize()

- Called once when controller is instantiated
- Setup constants and initial state
- **NO DOM access** - element may not be in DOM yet

```javascript
initialize() {
  this.debounceTimeout = 300
  this.maxRetries = 3
}
```

### connect()

- Called each time controller connects to DOM
- Setup event listeners
- Make API calls
- Start intervals/timers
- Access DOM elements

```javascript
connect() {
  this.observer = new IntersectionObserver(this.handleIntersection)
  this.observer.observe(this.element)
  this.fetchData()
}
```

### disconnect()

- Called when controller removed from DOM
- **Required for cleanup**
- Remove event listeners
- Clear timers/intervals
- Abort pending requests
- Disconnect observers

```javascript
disconnect() {
  if (this.observer) {
    this.observer.disconnect()
  }
  if (this.timer) {
    clearTimeout(this.timer)
  }
  if (this.controller) {
    this.controller.abort()
  }
}
```

## Targets

Reference important DOM elements:

```html
<div data-controller="search">
  <input data-search-target="query" type="text">
  <div data-search-target="results"></div>
</div>
```

```javascript
export default class extends Controller {
  static targets = ["query", "results"]
  
  search() {
    const query = this.queryTarget.value
    this.resultsTarget.innerHTML = `Searching for: ${query}`
  }
}
```

**Target methods**:
- `this.queryTarget` - First matching element (throws if missing)
- `this.hasQueryTarget` - Boolean check
- `this.queryTargets` - Array of all matching elements

## Values

Typed data attributes for reactive state:

```html
<div data-controller="counter"
     data-counter-count-value="0"
     data-counter-step-value="1">
  <button data-action="counter#increment">+</button>
  <span data-counter-target="display"></span>
</div>
```

```javascript
export default class extends Controller {
  static values = {
    count: { type: Number, default: 0 },
    step: { type: Number, default: 1 }
  }
  
  increment() {
    this.countValue += this.stepValue
  }
  
  // Called when count value changes
  countValueChanged() {
    this.element.querySelector("[data-counter-target='display']")
      .textContent = this.countValue
  }
}
```

**Supported types**: `String`, `Number`, `Boolean`, `Object`, `Array`

## Actions

Connect DOM events to controller methods:

```html
<!-- Basic action -->
<button data-action="click->gallery#next">Next</button>

<!-- Default event (click for buttons, submit for forms) -->
<button data-action="gallery#next">Next</button>

<!-- Multiple actions -->
<input data-action="input->search#query keydown->search#navigate">

<!-- Global events -->
<div data-action="resize@window->layout#resize"></div>

<!-- Capture phase -->
<form data-action="submit->form#validate:capture"></form>

<!-- Custom events -->
<div data-action="custom:event->handler#method"></div>
```

## Common Patterns

### Debounced Search

```javascript
export default class extends Controller {
  static targets = ["input", "results"]
  static values = { delay: { type: Number, default: 300 } }
  
  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.delayValue)
  }
  
  async performSearch() {
    const query = this.inputTarget.value
    const response = await fetch(`/search?q=${query}`)
    const html = await response.text()
    this.resultsTarget.innerHTML = html
  }
  
  disconnect() {
    clearTimeout(this.timeout)
  }
}
```

### Infinite Scroll

```javascript
export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = { page: Number }
  
  connect() {
    this.observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) this.loadMore()
    })
    
    if (this.hasPaginationTarget) {
      this.observer.observe(this.paginationTarget)
    }
  }
  
  async loadMore() {
    this.pageValue += 1
    const response = await fetch(`/posts?page=${this.pageValue}`)
    const html = await response.text()
    this.entriesTarget.insertAdjacentHTML("beforeend", html)
  }
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}
```

### Modal Dialog

```javascript
export default class extends Controller {
  static targets = ["backdrop", "dialog"]
  
  connect() {
    document.addEventListener("turbo:submit-end", this.handleSubmit)
  }
  
  open() {
    this.element.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }
  
  close() {
    this.element.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
  
  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }
  
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
  
  handleSubmit = (event) => {
    if (event.detail.success) {
      this.close()
    }
  }
  
  disconnect() {
    document.removeEventListener("turbo:submit-end", this.handleSubmit)
    document.body.classList.remove("overflow-hidden")
  }
}
```

Usage:
```html
<div data-controller="modal" 
     data-action="keydown@window->modal#closeOnEscape"
     class="hidden">
  <div data-modal-target="backdrop" 
       data-action="click->modal#closeOnBackdrop">
    <div data-modal-target="dialog">
      <button data-action="modal#close">×</button>
      <!-- Dialog content -->
    </div>
  </div>
</div>
```

### Auto-Submit Form

```javascript
export default class extends Controller {
  static targets = ["form"]
  static values = { delay: { type: Number, default: 500 } }
  
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, this.delayValue)
  }
  
  disconnect() {
    clearTimeout(this.timeout)
  }
}
```

Usage:
```html
<form data-controller="auto-submit"
      data-auto-submit-target="form"
      data-turbo-frame="results">
  <input data-action="input->auto-submit#submit" 
         name="query" type="text">
</form>
```

### Clipboard Copy

```javascript
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { 
    successMessage: String,
    successDuration: { type: Number, default: 2000 }
  }
  
  copy() {
    const text = this.sourceTarget.textContent
    navigator.clipboard.writeText(text).then(() => {
      this.showSuccess()
    })
  }
  
  showSuccess() {
    const originalText = this.buttonTarget.textContent
    this.buttonTarget.textContent = this.successMessageValue || "Copied!"
    
    setTimeout(() => {
      this.buttonTarget.textContent = originalText
    }, this.successDurationValue)
  }
}
```

## Integration with Turbo

Stimulus works seamlessly with Turbo Drive and Turbo Frames:

```html
<!-- Turbo Frame with Stimulus -->
<turbo-frame id="messages" data-controller="messages">
  <div data-messages-target="list">
    <!-- Messages -->
  </div>
</turbo-frame>

<!-- Form updates frame -->
<form data-turbo-frame="messages" 
      data-action="turbo:submit-end->messages#scrollToBottom">
  <input name="content">
  <button>Send</button>
</form>
```

## Controller Composition

### Extending Controllers

```javascript
// base_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  showAlert(message) {
    alert(message)
  }
}

// feature_controller.js
import BaseController from "./base_controller"

export default class extends BaseController {
  action() {
    this.showAlert("Feature action")
  }
}
```

### Mixins

```javascript
// mixins/confirmable.js
export const Confirmable = {
  confirm(message, callback) {
    if (window.confirm(message)) {
      callback()
    }
  }
}

// delete_controller.js
import { Controller } from "@hotwired/stimulus"
import { Confirmable } from "../mixins/confirmable"

export default class extends Controller {
  delete(event) {
    Confirmable.confirm("Are you sure?", () => {
      event.target.closest("form").requestSubmit()
    })
  }
}
```

## Naming Conventions

- **File names**: `kebab-case_controller.js`
- **Controller identifiers**: `kebab-case` (matches file name without `_controller.js`)
- **Actions**: `camelCase`
- **Targets**: `camelCase`
- **Values**: `camelCase`

## Testing

```javascript
// test/controllers/search_controller_test.js
import { Application } from "@hotwired/stimulus"
import SearchController from "../../app/javascript/controllers/search_controller"

describe("SearchController", () => {
  let application, container
  
  beforeEach(() => {
    container = document.createElement("div")
    container.innerHTML = `
      <div data-controller="search">
        <input data-search-target="query" type="text">
        <div data-search-target="results"></div>
      </div>
    `
    document.body.appendChild(container)
    
    application = Application.start()
    application.register("search", SearchController)
  })
  
  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
  })
  
  it("updates results on search", async () => {
    const input = container.querySelector("[data-search-target='query']")
    input.value = "test"
    input.dispatchEvent(new Event("input"))
    
    // Assert results updated
  })
})
```

## Best Practices

1. **Always cleanup in disconnect()** - Prevent memory leaks
2. **Use targets for important elements** - Avoid querySelector
3. **Use values for reactive state** - Get change callbacks
4. **Keep controllers focused** - Single responsibility
5. **Use descriptive names** - `search-results` not `sr`
6. **Handle missing targets gracefully** - Use `hasTarget` checks
7. **Debounce expensive operations** - Network requests, calculations
8. **Use Turbo when possible** - Less JavaScript, more HTML

## References

- **Stimulus Handbook**: https://stimulus.hotwired.dev/handbook/introduction
- **Master configuration**: `master.json` - `dependencies.stimulus_reflex.lifecycle`
- **Code style**: `.gldd/code-style.md`
- **Workflows**: `.gldd/workflows.md`
- **StimulusReflex**: For real-time server interactions (20-30ms round-trip)
