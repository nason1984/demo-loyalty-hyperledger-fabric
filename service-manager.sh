#!/bin/bash

# =============================================================================
# LOYALTY SYSTEM SERVICE INSTALLER
# =============================================================================
# Description: Install systemd service for automatic startup
# Author: AI Assistant
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/home/ubuntu/loyalty-project"
SERVICE_NAME="loyalty-blockchain"
SERVICE_FILE="$PROJECT_ROOT/loyalty-blockchain.service"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Install systemd service
install_service() {
    print_header "INSTALLING LOYALTY BLOCKCHAIN SYSTEMD SERVICE"
    
    # Check if service file exists
    if [ ! -f "$SERVICE_FILE" ]; then
        print_error "Service file not found: $SERVICE_FILE"
        exit 1
    fi
    
    # Copy service file to systemd directory
    print_info "Installing service file..."
    sudo cp "$SERVICE_FILE" "/etc/systemd/system/${SERVICE_NAME}.service"
    
    # Set permissions
    sudo chmod 644 "/etc/systemd/system/${SERVICE_NAME}.service"
    
    # Reload systemd daemon
    print_info "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    # Enable service for auto-start
    print_info "Enabling service for auto-start..."
    sudo systemctl enable "$SERVICE_NAME"
    
    print_success "Service installed successfully!"
    
    # Show service status
    print_info "Service status:"
    sudo systemctl status "$SERVICE_NAME" --no-pager || true
}

# Uninstall systemd service
uninstall_service() {
    print_header "UNINSTALLING LOYALTY BLOCKCHAIN SYSTEMD SERVICE"
    
    # Stop service if running
    print_info "Stopping service..."
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    
    # Disable service
    print_info "Disabling service..."
    sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    
    # Remove service file
    print_info "Removing service file..."
    sudo rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    
    # Reload systemd daemon
    print_info "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    print_success "Service uninstalled successfully!"
}

# Start service
start_service() {
    print_header "STARTING LOYALTY BLOCKCHAIN SERVICE"
    
    print_info "Starting service..."
    sudo systemctl start "$SERVICE_NAME"
    
    print_info "Service status:"
    sudo systemctl status "$SERVICE_NAME" --no-pager
}

# Stop service
stop_service() {
    print_header "STOPPING LOYALTY BLOCKCHAIN SERVICE"
    
    print_info "Stopping service..."
    sudo systemctl stop "$SERVICE_NAME"
    
    print_info "Service status:"
    sudo systemctl status "$SERVICE_NAME" --no-pager || true
}

# Show service status
show_status() {
    print_header "LOYALTY BLOCKCHAIN SERVICE STATUS"
    
    sudo systemctl status "$SERVICE_NAME" --no-pager || print_warning "Service not found or not running"
    
    echo ""
    print_info "Service logs (last 20 lines):"
    sudo journalctl -u "$SERVICE_NAME" -n 20 --no-pager || true
}

# Show service logs
show_logs() {
    local lines=${1:-50}
    
    print_header "LOYALTY BLOCKCHAIN SERVICE LOGS"
    
    sudo journalctl -u "$SERVICE_NAME" -n "$lines" --no-pager -f
}

# Test service
test_service() {
    print_header "TESTING LOYALTY BLOCKCHAIN SERVICE"
    
    # Create backup before test
    print_info "Creating backup before test..."
    "$PROJECT_ROOT/backup-restore.sh" backup
    
    # Stop any running system
    print_info "Stopping current system..."
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh stop-all 2>/dev/null || true
    
    # Test service start
    print_info "Testing service start..."
    sudo systemctl start "$SERVICE_NAME"
    
    # Wait for startup
    sleep 30
    
    # Check status
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "Service started successfully!"
        
        # Test connectivity
        print_info "Testing connectivity..."
        if curl -s http://localhost:80 >/dev/null; then
            print_success "Frontend accessible"
        else
            print_warning "Frontend not accessible"
        fi
        
        if curl -s http://localhost:8090 >/dev/null; then
            print_success "Explorer accessible"
        else
            print_warning "Explorer not accessible"
        fi
        
    else
        print_error "Service failed to start"
        show_status
        return 1
    fi
}

# Usage function
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install       Install systemd service"
    echo "  uninstall     Uninstall systemd service"
    echo "  start         Start service"
    echo "  stop          Stop service"
    echo "  status        Show service status"
    echo "  logs [LINES]  Show service logs (default: 50 lines)"
    echo "  test          Test service functionality"
    echo ""
    echo "Examples:"
    echo "  $0 install"
    echo "  $0 start"
    echo "  $0 logs 100"
}

# Ensure running as non-root for some operations
check_permissions() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please run this script as ubuntu user (not root)"
        print_info "Use: sudo -u ubuntu $0 $@"
        exit 1
    fi
}

# Main execution
case "${1:-}" in
    "install")
        check_permissions
        install_service
        ;;
    "uninstall")
        check_permissions
        uninstall_service
        ;;
    "start")
        check_permissions
        start_service
        ;;
    "stop")
        check_permissions
        stop_service
        ;;
    "status")
        check_permissions
        show_status
        ;;
    "logs")
        check_permissions
        show_logs "$2"
        ;;
    "test")
        check_permissions
        test_service
        ;;
    "--help"|"-h"|"")
        usage
        ;;
    *)
        print_error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
