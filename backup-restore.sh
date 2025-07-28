#!/bin/bash

# =============================================================================
# LOYALTY SYSTEM BACKUP & RESTORE SCRIPT
# =============================================================================
# Description: Backup and restore configurations for loyalty system
# Author: AI Assistant  
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="/home/ubuntu/loyalty-project"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="loyalty_backup_$TIMESTAMP"

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

# Create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    print_success "Created backup directory: $BACKUP_DIR/$BACKUP_NAME"
}

# Backup chaincode source
backup_chaincode() {
    print_info "Backing up chaincode source..."
    cp -r "$PROJECT_ROOT/loyalty-chaincode" "$BACKUP_DIR/$BACKUP_NAME/"
    print_success "Chaincode source backed up"
}

# Backup network configuration
backup_network_config() {
    print_info "Backing up network configuration..."
    cp -r "$PROJECT_ROOT/loyalty-network" "$BACKUP_DIR/$BACKUP_NAME/"
    print_success "Network configuration backed up"
}

# Backup docker-compose and scripts
backup_configs() {
    print_info "Backing up configurations and scripts..."
    cp "$PROJECT_ROOT/docker-compose.yml" "$BACKUP_DIR/$BACKUP_NAME/"
    cp "$PROJECT_ROOT"/*.sh "$BACKUP_DIR/$BACKUP_NAME/"
    print_success "Configurations backed up"
}

# Backup deployed chaincode info
backup_chaincode_info() {
    print_info "Backing up deployed chaincode information..."
    
    if docker ps | grep -q "cli"; then
        # Save chaincode info
        cat > "$BACKUP_DIR/$BACKUP_NAME/chaincode-info.txt" << EOF
# Chaincode Deployment Information
# Generated: $(date)

CHAINCODE_NAME=loyalty
CHANNEL_NAME=loyaltychannel

# Installed chaincodes:
$(docker exec cli peer lifecycle chaincode queryinstalled 2>/dev/null || echo "No chaincodes installed")

# Committed chaincodes:
$(docker exec cli peer lifecycle chaincode querycommitted --channelID loyaltychannel 2>/dev/null || echo "No chaincodes committed")
EOF
        print_success "Chaincode info saved"
    else
        print_warning "CLI container not running, skipping chaincode info backup"
    fi
}

# Create deployment state file
create_deployment_state() {
    print_info "Creating deployment state file..."
    
    cat > "$BACKUP_DIR/$BACKUP_NAME/deployment-state.sh" << 'EOF'
#!/bin/bash
# Auto-generated deployment state
# This file contains the deployment sequence for restoring the system

CHAINCODE_NAME="loyalty"
CHAINCODE_VERSION="1.3"
CHAINCODE_SEQUENCE="1"
CHANNEL_NAME="loyaltychannel"

# Deployment commands (to be run after network start)
deploy_from_backup() {
    echo "🔄 Restoring chaincode from backup..."
    
    # Deploy chaincode
    /home/ubuntu/loyalty-project/deploy-chaincode.sh $CHAINCODE_VERSION $CHAINCODE_SEQUENCE
    
    if [ $? -eq 0 ]; then
        echo "✅ Chaincode restored successfully"
    else
        echo "❌ Failed to restore chaincode"
        return 1
    fi
}

# Run deployment if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    deploy_from_backup
fi
EOF
    
    chmod +x "$BACKUP_DIR/$BACKUP_NAME/deployment-state.sh"
    print_success "Deployment state file created"
}

# Main backup function
backup_system() {
    print_header "BACKING UP LOYALTY SYSTEM"
    
    create_backup_dir
    backup_chaincode
    backup_network_config
    backup_configs
    backup_chaincode_info
    create_deployment_state
    
    # Create backup summary
    cat > "$BACKUP_DIR/$BACKUP_NAME/backup-info.txt" << EOF
Loyalty System Backup
=====================
Backup Name: $BACKUP_NAME
Timestamp: $(date)
System Status: $(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Docker not running")

Restore Instructions:
1. Stop current system: ./manage-loyalty-system.sh stop-all
2. Restore from backup: ./backup-restore.sh restore $BACKUP_NAME
3. Start system: ./manage-loyalty-system.sh start-all
EOF
    
    print_header "BACKUP COMPLETED"
    print_success "System backed up to: $BACKUP_DIR/$BACKUP_NAME"
    print_info "Backup size: $(du -sh "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"
}

# List available backups
list_backups() {
    print_header "AVAILABLE BACKUPS"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        print_warning "No backups found"
        return 0
    fi
    
    echo -e "${BLUE}Backup Name${NC}\t\t\t${BLUE}Date${NC}\t\t\t${BLUE}Size${NC}"
    echo "------------------------------------------------------------"
    
    for backup in "$BACKUP_DIR"/loyalty_backup_*; do
        if [ -d "$backup" ]; then
            backup_name=$(basename "$backup")
            backup_date=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S")
            backup_size=$(du -sh "$backup" | cut -f1)
            echo -e "${GREEN}$backup_name${NC}\t${YELLOW}$backup_date${NC}\t${CYAN}$backup_size${NC}"
        fi
    done
}

# Restore from backup
restore_system() {
    local backup_name=$1
    
    if [ -z "$backup_name" ]; then
        print_error "Please specify backup name to restore"
        list_backups
        return 1
    fi
    
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [ ! -d "$backup_path" ]; then
        print_error "Backup not found: $backup_name"
        list_backups
        return 1
    fi
    
    print_header "RESTORING FROM BACKUP: $backup_name"
    
    # Stop current system
    print_info "Stopping current system..."
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh stop-all 2>/dev/null || true
    
    # Restore files
    print_info "Restoring chaincode source..."
    rm -rf "$PROJECT_ROOT/loyalty-chaincode"
    cp -r "$backup_path/loyalty-chaincode" "$PROJECT_ROOT/"
    
    print_info "Restoring network configuration..."
    rm -rf "$PROJECT_ROOT/loyalty-network"
    cp -r "$backup_path/loyalty-network" "$PROJECT_ROOT/"
    
    print_info "Restoring configurations..."
    cp "$backup_path/docker-compose.yml" "$PROJECT_ROOT/"
    cp "$backup_path"/*.sh "$PROJECT_ROOT/" 2>/dev/null || true
    
    # Make scripts executable
    chmod +x "$PROJECT_ROOT"/*.sh
    
    print_success "Files restored successfully"
    
    # Start system
    print_info "Starting system..."
    ./manage-loyalty-system.sh start-all
    
    # Deploy chaincode
    if [ -f "$backup_path/deployment-state.sh" ]; then
        print_info "Restoring chaincode deployment..."
        sleep 10  # Wait for network to be fully ready
        bash "$backup_path/deployment-state.sh"
    fi
    
    print_header "RESTORE COMPLETED"
    print_success "System restored from backup: $backup_name"
}

# Clean old backups
clean_backups() {
    local keep_days=${1:-7}
    
    print_header "CLEANING OLD BACKUPS"
    print_info "Removing backups older than $keep_days days..."
    
    if [ -d "$BACKUP_DIR" ]; then
        find "$BACKUP_DIR" -name "loyalty_backup_*" -type d -mtime +$keep_days -exec rm -rf {} \; 2>/dev/null || true
        print_success "Old backups cleaned"
    fi
}

# Usage function
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  backup                Create a backup of the current system"
    echo "  restore [BACKUP_NAME] Restore from a specific backup"
    echo "  list                  List available backups"
    echo "  clean [DAYS]          Clean backups older than DAYS (default: 7)"
    echo ""
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 restore loyalty_backup_20250728_101530"
    echo "  $0 list"
    echo "  $0 clean 30"
}

# Main execution
case "${1:-}" in
    "backup")
        backup_system
        ;;
    "restore")
        restore_system "$2"
        ;;
    "list")
        list_backups
        ;;
    "clean")
        clean_backups "$2"
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
