#!/usr/bin/env bash
# frozen_string_literal: false
# aight/ AI Framework Validation Script

set -euo pipefail

MASTER_JSON="../master.json"
ERRORS=0
WARNINGS=0

echo "🔍 Validating aight/ AI framework..."
echo

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if master.json exists and contains aight section
if [[ ! -f "$MASTER_JSON" ]]; then
  echo "${RED}❌ master.json not found${NC}"
  ((ERRORS++))
else
  if ! jq -e '.aight' "$MASTER_JSON" > /dev/null 2>&1; then
    echo "${RED}❌ aight section not found in master.json${NC}"
    ((ERRORS++))
  else
    echo "${GREEN}✅ master.json aight section found${NC}"
  fi
fi

# Check file sizes (20KB limit = 20480 bytes)
echo
echo "📏 Checking file sizes (20KB limit)..."
shopt -s globstar nullglob
for rb in **/*.rb; do
  [[ -f "$rb" ]] || continue
  
  size=$(stat -f%z "$rb" 2>/dev/null || stat -c%s "$rb" 2>/dev/null)
  if [[ $size -gt 20480 ]]; then
    echo -e "${RED}❌ $rb: exceeds 20KB limit (${size} bytes)${NC}"
    ((ERRORS++))
  elif [[ $size -gt 18432 ]]; then  # Warning at 18KB (90%)
    echo -e "${YELLOW}⚠️  $rb: approaching limit (${size} bytes)${NC}"
    ((WARNINGS++))
  fi
done

if [[ $ERRORS -eq 0 ]]; then
  echo "${GREEN}✅ All Ruby files under 20KB limit${NC}"
fi

# Check for langchainrb integration
echo
echo "🔗 Checking langchainrb integration..."
if grep -q "langchainrb" aight.rb 2>/dev/null; then
  echo -e "${GREEN}✅ langchainrb imported in main file${NC}"
else
  echo -e "${YELLOW}⚠️  langchainrb not found in aight.rb${NC}"
  ((WARNINGS++))
fi

if grep -rq "Langchain::" lib/ 2>/dev/null; then
  echo -e "${GREEN}✅ Langchain classes used in modules${NC}"
else
  echo -e "${YELLOW}⚠️  Langchain classes not found in modules${NC}"
  ((WARNINGS++))
fi

# Check modular structure
echo
echo "📦 Checking modular structure..."
required_modules=(
  "lib/aight/config.rb"
  "lib/aight/prompts.rb"
  "lib/aight/tools.rb"
  "lib/aight/assistant.rb"
  "lib/aight/cli.rb"
)

for module in "${required_modules[@]}"; do
  if [[ -f "$module" ]]; then
    echo -e "${GREEN}✅ $module exists${NC}"
  else
    echo -e "${RED}❌ $module missing${NC}"
    ((ERRORS++))
  fi
done

# Check documentation
echo
echo "📚 Checking documentation..."
required_docs=(
  "README.md"
  "RESTORATION_PLAN.md"
)

for doc in "${required_docs[@]}"; do
  if [[ -f "$doc" ]]; then
    echo -e "${GREEN}✅ $doc exists${NC}"
  else
    echo -e "${YELLOW}⚠️  $doc missing${NC}"
    ((WARNINGS++))
  fi
done

# Check assistants
echo
echo "👥 Checking assistants..."
assistant_count=$(find assistants -name "*.rb" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "Found ${assistant_count} assistant files"

if [[ $assistant_count -ge 15 ]]; then
  echo -e "${GREEN}✅ Sufficient number of assistants (${assistant_count})${NC}"
else
  echo -e "${YELLOW}⚠️  Only ${assistant_count} assistants found${NC}"
  ((WARNINGS++))
fi

# Check for oversized assistants
shopt -s nullglob
for assistant in assistants/*.rb; do
  [[ -f "$assistant" ]] || continue
  
  size=$(stat -f%z "$assistant" 2>/dev/null || stat -c%s "$assistant" 2>/dev/null)
  if [[ $size -gt 20480 ]]; then
    echo -e "${RED}❌ $assistant: exceeds limit (${size} bytes)${NC}"
    ((ERRORS++))
  fi
done

# Summary
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GREEN}✅ aight/ framework fully compliant${NC}"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YELLOW}⚠️  ${WARNINGS} warning(s) found${NC}"
  exit 0
else
  echo -e "${RED}❌ ${ERRORS} error(s) and ${WARNINGS} warning(s) found${NC}"
  exit 1
fi
