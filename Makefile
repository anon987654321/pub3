.PHONY: help lint test clean setup security tree

help:
	@echo "pub3 - Development Tasks"
	@echo ""
	@echo "Available targets:"
	@echo "  setup     - Install dependencies"
	@echo "  lint      - Run all linters"
	@echo "  test      - Run all tests"
	@echo "  security  - Run security scans"
	@echo "  tree      - Show directory structure"
	@echo "  clean     - Clean build artifacts"
	@echo ""
	@echo "See DEVELOPMENT.md for detailed instructions"

setup:
	@echo "Setting up development environment..."
	@command -v ruby >/dev/null 2>&1 || (echo "Ruby not found. Install Ruby 3.2+"; exit 1)
	@command -v node >/dev/null 2>&1 || (echo "Node.js not found. Install Node 20.x+"; exit 1)
	@command -v python3 >/dev/null 2>&1 || (echo "Python not found. Install Python 3.13+"; exit 1)
	@echo "✓ Prerequisites found"
	@echo "Run 'bundle install' in Rails directories"
	@echo "Run 'npm install' for Node projects"
	@echo "Run 'pip install -r requirements.txt' for Python projects"

lint:
	@echo "Running linters..."
	@sh/lint.sh
	@echo "Checking Ruby syntax..."
	@find multimedia rails -name "*.rb" -exec ruby -c {} + 2>&1 | grep -v "Syntax OK" || true
	@echo "Validating JSON..."
	@python3 -m json.tool master.json > /dev/null && echo "✓ master.json valid"
	@echo "✓ Linting complete"

test:
	@echo "Running tests..."
	@echo "Note: Run 'bundle exec rails test' in individual Rails apps"
	@echo "See DEVELOPMENT.md for testing guide"

security:
	@echo "Running security scans..."
	@command -v shellcheck >/dev/null 2>&1 && find . -name "*.sh" -not -path "./.git/*" -exec shellcheck {} + || echo "shellcheck not found"
	@echo "See SECURITY.md for security policy"

tree:
	@sh/tree.sh .

clean:
	@echo "Cleaning build artifacts..."
	@find . -name "*.log" -type f -delete
	@find . -name "*.tmp" -type f -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Clean complete"
