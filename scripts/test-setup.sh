#!/bin/bash
# SearXNG + OpenClaw Setup - Test Suite
# Usage: bash scripts/test-setup.sh

echo "=========================================="
echo "  SearXNG + OpenClaw Test Suite"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

test_pass() { echo -e "${GREEN}✅ PASS:${NC} $1"; PASS=$((PASS + 1)); }
test_fail() { echo -e "${RED}❌ FAIL:${NC} $1"; FAIL=$((FAIL + 1)); }
test_warn() { echo -e "${YELLOW}⚠️  WARN:${NC} $1"; WARN=$((WARN + 1)); }

# Test 1: SearXNG Service
echo "[Test 1/8] Checking SearXNG service..."
if sudo systemctl is-active --quiet searxng.service 2>/dev/null; then
    test_pass "SearXNG service is running"
else
    test_fail "SearXNG service is NOT running"
fi

# Test 2: Redis Service
echo "[Test 2/8] Checking Redis service..."
if redis-cli ping &>/dev/null; then
    test_pass "Redis is running"
else
    test_fail "Redis is NOT running"
fi

# Test 3: HTTP Endpoint
echo "[Test 3/8] Testing HTTP endpoint..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    test_pass "HTTP endpoint accessible"
else
    test_fail "HTTP endpoint NOT accessible"
fi

# Test 4: JSON API
echo "[Test 4/8] Testing JSON API..."
RESPONSE=$(curl -s "http://localhost:8080/search?q=test&format=json" 2>/dev/null)
RESULT_COUNT=$(echo "$RESPONSE" | jq -r '.results | length' 2>/dev/null || echo "0")

if [ "$RESULT_COUNT" -gt 0 ]; then
    test_pass "JSON API working ($RESULT_COUNT results)"
else
    test_fail "JSON API returned NO results"
fi

# Test 5: Multi-Page Search
echo "[Test 5/8] Testing multi-page search..."
PAGE2_COUNT=$(curl -s "http://localhost:8080/search?q=test&format=json&pageno=2" 2>/dev/null | jq -r '.results | length' 2>/dev/null || echo "0")

if [ "$PAGE2_COUNT" -gt 0 ]; then
    test_pass "Multi-page search working ($PAGE2_COUNT results on page 2)"
else
    test_warn "Multi-page search may not be working"
fi

# Test 6: OpenClaw Installation
echo "[Test 6/8] Checking OpenClaw installation..."
if command -v openclaw &>/dev/null; then
    test_pass "OpenClaw is installed"
else
    test_warn "OpenClaw is NOT installed (optional)"
fi

# Test 7: OpenClaw Plugin
if command -v openclaw &>/dev/null; then
    echo "[Test 7/8] Checking OpenClaw plugin..."
    if openclaw doctor 2>&1 | grep -qi "searxng"; then
        test_pass "SearXNG plugin detected in OpenClaw"
    else
        test_warn "SearXNG plugin NOT detected in OpenClaw"
    fi
else
    echo "[Test 7/8] Skipping OpenClaw plugin check (OpenClaw not installed)"
fi

# Test 8: Disk Space
echo "[Test 8/8] Checking disk space..."
DISK_AVAILABLE=$(df -h / | tail -1 | awk '{print $4}')
DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$DISK_PERCENT" -lt 90 ]; then
    test_pass "Disk space available ($DISK_AVAILABLE free)"
else
    test_fail "Disk space critically low ($DISK_AVAILABLE free)"
fi

# Summary
echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed:${NC}  $PASS"
echo -e "${RED}Failed:${NC}  $FAIL"
echo -e "${YELLOW}Warnings:${NC} $WARN"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Your installation is working correctly!"
    echo ""
    echo "Next steps:"
    echo "  1. Test search: curl \"http://localhost:8080/search?q=python&format=json\" | jq '.results | length'"
    echo "  2. Configure OpenClaw: See CONFIGURATION.md"
    echo "  3. Start using: Send message to your OpenClaw bot"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Please check TROUBLESHOOTING.md for solutions"
    exit 1
fi
