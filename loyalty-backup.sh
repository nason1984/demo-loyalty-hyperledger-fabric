#!/bin/bash

# =============================================================================
# LOYALTY BLOCKCHAIN SYSTEM BACKUP & RESTORE
# =============================================================================
# Comprehensive backup and restore solution for the loyalty blockchain system
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="/home/ubuntu/loyalty-project"
BACKUP_ROOT="/home/ubuntu/loyalty-backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="loyalty-backup-$TIMESTAMP"
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_NAME"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
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
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${YELLOW}🔄 $1${NC}"
}

# Create backup directory
create_backup_dir() {
    print_step "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    print_success "Backup directory created: $BACKUP_DIR"
}

# Backup blockchain data
backup_blockchain() {
    print_header "BACKING UP BLOCKCHAIN DATA"
    
    print_step "Backing up Fabric network configuration..."
    cp -r "$PROJECT_ROOT/loyalty-network" "$BACKUP_DIR/"
    
    print_step "Backing up chaincode..."
    cp -r "$PROJECT_ROOT/loyalty-chaincode" "$BACKUP_DIR/"
    
    # Backup Fabric volumes if they exist
    print_step "Backing up Fabric ledger data..."
    mkdir -p "$BACKUP_DIR/fabric-volumes"
    
    # Export peer volumes
    if docker volume ls | grep -q "loyalty-cryptogen_peer0.bank.loyalty.com"; then
        docker run --rm -v loyalty-cryptogen_peer0.bank.loyalty.com:/data -v "$BACKUP_DIR/fabric-volumes":/backup alpine tar czf /backup/peer0-data.tar.gz -C /data .
        print_success "Peer0 data backed up"
    fi
    
    if docker volume ls | grep -q "loyalty-cryptogen_peer1.bank.loyalty.com"; then
        docker run --rm -v loyalty-cryptogen_peer1.bank.loyalty.com:/data -v "$BACKUP_DIR/fabric-volumes":/backup alpine tar czf /backup/peer1-data.tar.gz -C /data .
        print_success "Peer1 data backed up"
    fi
    
    if docker volume ls | grep -q "loyalty-cryptogen_orderer.loyalty.com"; then
        docker run --rm -v loyalty-cryptogen_orderer.loyalty.com:/data -v "$BACKUP_DIR/fabric-volumes":/backup alpine tar czf /backup/orderer-data.tar.gz -C /data .
        print_success "Orderer data backed up"
    fi
    
    print_success "Blockchain data backup completed"
}

# Backup application data
backup_application() {
    print_header "BACKING UP APPLICATION DATA"
    
    print_step "Backing up application source code..."
    cp -r "$PROJECT_ROOT/loyalty-backend" "$BACKUP_DIR/"
    cp -r "$PROJECT_ROOT/loyalty-frontend" "$BACKUP_DIR/"
    
    # Backup database
    print_step "Backing up PostgreSQL database..."
    mkdir -p "$BACKUP_DIR/database"
    
    if docker ps | grep -q "loyalty_postgres"; then
        docker exec loyalty_postgres pg_dump -U loyalty_user loyalty_db > "$BACKUP_DIR/database/loyalty_db.sql"
        print_success "Database backed up"
    else
        print_warning "PostgreSQL container not running, skipping database backup"
    fi
    
    print_success "Application data backup completed"
}

# Backup Explorer data
backup_explorer() {
    print_header "BACKING UP EXPLORER DATA"
    
    print_step "Backing up Explorer configuration..."
    cp -r "$PROJECT_ROOT/blockchain-explorer" "$BACKUP_DIR/"
    
    # Backup Explorer database
    print_step "Backing up Explorer database..."
    mkdir -p "$BACKUP_DIR/explorer-db"
    
    if docker ps | grep -q "explorerdb"; then
        docker exec $(docker ps --format "{{.Names}}" | grep explorerdb) pg_dump -U hppoc fabricexplorer > "$BACKUP_DIR/explorer-db/fabricexplorer.sql"
        print_success "Explorer database backed up"
    else
        print_warning "Explorer database not running, skipping Explorer DB backup"
    fi
    
    print_success "Explorer data backup completed"
}

# Backup system configuration
backup_system_config() {
    print_header "BACKING UP SYSTEM CONFIGURATION"
    
    print_step "Backing up management scripts..."
    cp "$PROJECT_ROOT"/*.sh "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PROJECT_ROOT/docker-compose.yml" "$BACKUP_DIR/" 2>/dev/null || true
    
    print_step "Backing up Docker configuration..."
    mkdir -p "$BACKUP_DIR/docker-config"
    
    # Export Docker networks
    docker network ls --format "{{.Name}}" | grep loyalty > "$BACKUP_DIR/docker-config/networks.txt" 2>/dev/null || true
    
    # Export Docker volumes
    docker volume ls --format "{{.Name}}" | grep loyalty > "$BACKUP_DIR/docker-config/volumes.txt" 2>/dev/null || true
    
    # Export current container states
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$BACKUP_DIR/docker-config/containers.txt"
    
    print_success "System configuration backup completed"
}

# Create backup manifest
create_manifest() {
    print_step "Creating backup manifest..."
    
    cat > "$BACKUP_DIR/BACKUP_MANIFEST.txt" << EOF
====================================
LOYALTY BLOCKCHAIN SYSTEM BACKUP
====================================
Backup Name: $BACKUP_NAME
Backup Date: $(date)
Backup Location: $BACKUP_DIR

CONTENTS:
- loyalty-network/          : Fabric network configuration and certificates
- loyalty-chaincode/        : Smart contract source code
- loyalty-backend/          : Backend API source code
- loyalty-frontend/         : Frontend web application source code
- blockchain-explorer/      : Hyperledger Explorer configuration
- fabric-volumes/           : Fabric ledger data (peer and orderer volumes)
- database/                 : PostgreSQL database dump
- explorer-db/              : Explorer database dump
- docker-config/            : Docker networks, volumes, and container states
- *.sh                      : Management and monitoring scripts
- docker-compose.yml        : Docker Compose configuration

BACKUP COMMANDS:
To restore this backup, use:
    ./loyalty-backup.sh restore $BACKUP_NAME

SYSTEM INFORMATION:
- Hostname: $(hostname)
- Docker Version: $(docker --version)
- System: $(uname -a)
- Total Backup Size: $(du -sh "$BACKUP_DIR" | cut -f1)

VERIFICATION:
$(find "$BACKUP_DIR" -type f | wc -l) files backed up
$(find "$BACKUP_DIR" -type d | wc -l) directories backed up
EOF

    print_success "Backup manifest created"
}

# Compress backup
compress_backup() {
    print_step "Compressing backup..."
    
    cd "$BACKUP_ROOT"
    tar czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
    
    local original_size=$(du -sh "$BACKUP_NAME" | cut -f1)
    local compressed_size=$(du -sh "$BACKUP_NAME.tar.gz" | cut -f1)
    
    print_success "Backup compressed: $original_size -> $compressed_size"
    print_info "Compressed backup: $BACKUP_ROOT/$BACKUP_NAME.tar.gz"
    
    # Optional: Remove uncompressed backup
    read -p "Remove uncompressed backup directory? (y/N): " remove_original
    if [ "$remove_original" = "y" ] || [ "$remove_original" = "Y" ]; then
        rm -rf "$BACKUP_DIR"
        print_info "Uncompressed backup removed"
    fi
}

# Full backup function
full_backup() {
    print_header "CREATING FULL SYSTEM BACKUP"
    
    create_backup_dir
    backup_blockchain
    backup_application
    backup_explorer
    backup_system_config
    create_manifest
    
    print_success "Full backup completed: $BACKUP_DIR"
    
    # Ask if user wants to compress
    read -p "Compress backup? (Y/n): " compress
    if [ "$compress" != "n" ] && [ "$compress" != "N" ]; then
        compress_backup
    fi
}

# List backups
list_backups() {
    print_header "AVAILABLE BACKUPS"
    
    if [ ! -d "$BACKUP_ROOT" ]; then
        print_warning "No backup directory found"
        return
    fi
    
    echo -e "${CYAN}Backup Directory: $BACKUP_ROOT${NC}"
    echo ""
    
    # List compressed backups
    if ls "$BACKUP_ROOT"/*.tar.gz >/dev/null 2>&1; then
        echo -e "${YELLOW}Compressed Backups:${NC}"
        for backup in "$BACKUP_ROOT"/*.tar.gz; do
            local name=$(basename "$backup" .tar.gz)
            local size=$(du -sh "$backup" | cut -f1)
            local date=$(stat -c %y "$backup" | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo -e "  📦 $name (${size}) - $date"
        done
        echo ""
    fi
    
    # List uncompressed backups
    if ls -d "$BACKUP_ROOT"/loyalty-backup-* >/dev/null 2>&1; then
        echo -e "${YELLOW}Uncompressed Backups:${NC}"
        for backup in "$BACKUP_ROOT"/loyalty-backup-*; do
            if [ -d "$backup" ]; then
                local name=$(basename "$backup")
                local size=$(du -sh "$backup" | cut -f1)
                local date=$(stat -c %y "$backup" | cut -d' ' -f1,2 | cut -d'.' -f1)
                echo -e "  📁 $name (${size}) - $date"
            fi
        done
    fi
}

# Restore backup
restore_backup() {
    local backup_name=$1
    
    if [ -z "$backup_name" ]; then
        print_error "Backup name is required"
        echo "Usage: $0 restore <backup-name>"
        list_backups
        return 1
    fi
    
    print_header "RESTORING BACKUP: $backup_name"
    
    # Check if backup exists
    local backup_path=""
    if [ -f "$BACKUP_ROOT/$backup_name.tar.gz" ]; then
        backup_path="$BACKUP_ROOT/$backup_name.tar.gz"
        print_info "Found compressed backup: $backup_path"
    elif [ -d "$BACKUP_ROOT/$backup_name" ]; then
        backup_path="$BACKUP_ROOT/$backup_name"
        print_info "Found uncompressed backup: $backup_path"
    else
        print_error "Backup not found: $backup_name"
        list_backups
        return 1
    fi
    
    # Warning
    print_warning "This will stop all running services and replace current data!"
    read -p "Are you sure you want to continue? (yes/NO): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        return 0
    fi
    
    # Stop all services
    print_step "Stopping all services..."
    cd "$PROJECT_ROOT"
    ./manage-loyalty-system.sh stop-all || true
    
    # Extract if compressed
    local restore_dir=""
    if [[ "$backup_path" == *.tar.gz ]]; then
        print_step "Extracting compressed backup..."
        cd "$BACKUP_ROOT"
        tar xzf "$backup_path"
        restore_dir="$BACKUP_ROOT/$backup_name"
    else
        restore_dir="$backup_path"
    fi
    
    # Restore files
    print_step "Restoring system files..."
    
    # Backup current data before restore
    local current_backup="$PROJECT_ROOT-pre-restore-$(date +%Y%m%d-%H%M%S)"
    print_info "Creating current state backup: $current_backup"
    cp -r "$PROJECT_ROOT" "$current_backup"
    
    # Restore network
    if [ -d "$restore_dir/loyalty-network" ]; then
        rm -rf "$PROJECT_ROOT/loyalty-network"
        cp -r "$restore_dir/loyalty-network" "$PROJECT_ROOT/"
        print_success "Network configuration restored"
    fi
    
    # Restore chaincode
    if [ -d "$restore_dir/loyalty-chaincode" ]; then
        rm -rf "$PROJECT_ROOT/loyalty-chaincode"
        cp -r "$restore_dir/loyalty-chaincode" "$PROJECT_ROOT/"
        print_success "Chaincode restored"
    fi
    
    # Restore backend
    if [ -d "$restore_dir/loyalty-backend" ]; then
        rm -rf "$PROJECT_ROOT/loyalty-backend"
        cp -r "$restore_dir/loyalty-backend" "$PROJECT_ROOT/"
        print_success "Backend restored"
    fi
    
    # Restore frontend
    if [ -d "$restore_dir/loyalty-frontend" ]; then
        rm -rf "$PROJECT_ROOT/loyalty-frontend"
        cp -r "$restore_dir/loyalty-frontend" "$PROJECT_ROOT/"
        print_success "Frontend restored"
    fi
    
    # Restore Explorer
    if [ -d "$restore_dir/blockchain-explorer" ]; then
        rm -rf "$PROJECT_ROOT/blockchain-explorer"
        cp -r "$restore_dir/blockchain-explorer" "$PROJECT_ROOT/"
        print_success "Explorer configuration restored"
    fi
    
    # Restore scripts
    if [ -f "$restore_dir/manage-loyalty-system.sh" ]; then
        cp "$restore_dir"/*.sh "$PROJECT_ROOT/" 2>/dev/null || true
        chmod +x "$PROJECT_ROOT"/*.sh
        print_success "Management scripts restored"
    fi
    
    # Restore Docker Compose
    if [ -f "$restore_dir/docker-compose.yml" ]; then
        cp "$restore_dir/docker-compose.yml" "$PROJECT_ROOT/"
        print_success "Docker Compose configuration restored"
    fi
    
    print_success "File restoration completed"
    print_info "Previous state backed up to: $current_backup"
    
    # Ask about starting services
    read -p "Start services after restore? (Y/n): " start_services
    if [ "$start_services" != "n" ] && [ "$start_services" != "N" ]; then
        print_step "Starting services..."
        cd "$PROJECT_ROOT"
        ./manage-loyalty-system.sh start-all
    fi
    
    print_success "Restore completed successfully!"
}

# Clean old backups
clean_backups() {
    local days=${1:-30}
    
    print_header "CLEANING OLD BACKUPS"
    print_warning "This will remove backups older than $days days"
    
    read -p "Continue? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "Cleanup cancelled"
        return 0
    fi
    
    if [ ! -d "$BACKUP_ROOT" ]; then
        print_warning "No backup directory found"
        return
    fi
    
    local count=0
    
    # Clean compressed backups
    while IFS= read -r -d '' backup; do
        rm -f "$backup"
        print_info "Removed: $(basename "$backup")"
        ((count++))
    done < <(find "$BACKUP_ROOT" -name "loyalty-backup-*.tar.gz" -mtime +$days -print0)
    
    # Clean uncompressed backups
    while IFS= read -r -d '' backup; do
        rm -rf "$backup"
        print_info "Removed: $(basename "$backup")"
        ((count++))
    done < <(find "$BACKUP_ROOT" -name "loyalty-backup-*" -type d -mtime +$days -print0)
    
    if [ $count -eq 0 ]; then
        print_info "No old backups found to clean"
    else
        print_success "Cleaned $count old backups"
    fi
}

# Show usage
usage() {
    echo -e "${BLUE}Loyalty Blockchain System Backup & Restore${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} $0 [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  backup                    Create full system backup"
    echo "  list                      List available backups"
    echo "  restore <backup-name>     Restore from backup"
    echo "  clean [days]              Clean backups older than X days (default: 30)"
    echo "  help                      Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 backup                           # Create full backup"
    echo "  $0 restore loyalty-backup-20250728  # Restore specific backup"
    echo "  $0 clean 7                          # Remove backups older than 7 days"
}

# Main script logic
case "${1}" in
    "backup")
        full_backup
        ;;
    "list")
        list_backups
        ;;
    "restore")
        restore_backup "${2}"
        ;;
    "clean")
        clean_backups "${2}"
        ;;
    "help"|"--help"|"-h")
        usage
        ;;
    *)
        print_error "Invalid command: $1"
        echo ""
        usage
        exit 1
        ;;
esac
