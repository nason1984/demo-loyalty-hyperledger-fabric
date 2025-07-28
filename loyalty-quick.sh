#!/bin/bash

# =============================================================================
# QUICK START SCRIPT FOR LOYALTY BLOCKCHAIN NETWORK
# =============================================================================
# This script provides quick commands for daily operations
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/home/ubuntu/loyalty-project"

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Quick start everything
quick_start() {
    print_info "Starting Loyalty Blockchain System..."
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh start-all
}

# Quick stop everything  
quick_stop() {
    print_info "Stopping Loyalty Blockchain System..."
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh stop-all
}

# Quick status check
quick_status() {
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh status
}

# Quick restart
quick_restart() {
    print_info "Restarting Loyalty Blockchain System..."
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh restart-all
}

# Quick test
quick_test() {
    print_info "Testing chaincode..."
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh test-chaincode
}

case "${1}" in
    "start"|"up")
        quick_start
        ;;
    "stop"|"down")
        quick_stop
        ;;
    "restart"|"reboot")
        quick_restart
        ;;
    "status"|"check")
        quick_status
        ;;
    "test")
        quick_test
        ;;
    *)
        echo -e "${YELLOW}Loyalty Blockchain Quick Commands:${NC}"
        echo "  $0 start     - Start all services"
        echo "  $0 stop      - Stop all services"  
        echo "  $0 restart   - Restart all services"
        echo "  $0 status    - Check system status"
        echo "  $0 test      - Test chaincode"
        ;;
esac
