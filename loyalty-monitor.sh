#!/bin/bash

# =============================================================================
# LOYALTY BLOCKCHAIN SYSTEM MONITORING & HEALTH CHECK
# =============================================================================
# Comprehensive monitoring script for all system components
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="/home/ubuntu/loyalty-project"
LOG_FILE="/tmp/loyalty-system-monitor.log"
HEALTH_CHECK_INTERVAL=30
ALERT_EMAIL=""  # Set email for alerts

# Health check thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85

print_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

log_message() {
    echo "$(print_timestamp) $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_message "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_message "WARNING: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log_message "ERROR: $1"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Function to check container health
check_container_health() {
    local container_name=$1
    local service_name=$2
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
        local uptime=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" | awk '{print $2, $3, $4}')
        print_success "$service_name is healthy ($uptime)"
        return 0
    elif docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Exited"; then
        print_error "$service_name has exited"
        return 1
    else
        print_error "$service_name is not running"
        return 1
    fi
}

# Function to check container resource usage
check_container_resources() {
    local container_name=$1
    local service_name=$2
    
    if docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -q "$container_name"; then
        local stats=$(docker stats --no-stream --format "{{.CPUPerc}}\t{{.MemPerc}}" "$container_name" 2>/dev/null | head -1)
        local cpu_percent=$(echo "$stats" | cut -f1 | tr -d '%')
        local mem_percent=$(echo "$stats" | cut -f2 | tr -d '%')
        
        # Remove decimal points for comparison
        cpu_percent=${cpu_percent%.*}
        mem_percent=${mem_percent%.*}
        
        print_info "$service_name - CPU: ${cpu_percent}%, Memory: ${mem_percent}%"
        
        # Check thresholds
        if [ "$cpu_percent" -gt "$CPU_THRESHOLD" ]; then
            print_warning "$service_name CPU usage is high: ${cpu_percent}%"
        fi
        
        if [ "$mem_percent" -gt "$MEMORY_THRESHOLD" ]; then
            print_warning "$service_name Memory usage is high: ${mem_percent}%"
        fi
    fi
}

# Function to check Fabric network health
check_fabric_health() {
    print_header "FABRIC NETWORK HEALTH CHECK"
    
    # Check orderer
    check_container_health "orderer.loyalty.com" "Fabric Orderer"
    check_container_resources "orderer.loyalty.com" "Fabric Orderer"
    
    # Check peers
    check_container_health "peer0.bank.loyalty.com" "Fabric Peer0"
    check_container_resources "peer0.bank.loyalty.com" "Fabric Peer0"
    
    check_container_health "peer1.bank.loyalty.com" "Fabric Peer1"
    check_container_resources "peer1.bank.loyalty.com" "Fabric Peer1"
    
    # Check CLI
    check_container_health "cli" "Fabric CLI"
    
    # Check channel accessibility
    if docker exec cli peer channel list >/dev/null 2>&1; then
        print_success "Channel access is working"
    else
        print_error "Cannot access channels"
    fi
    
    # Check chaincode status
    if docker exec cli peer lifecycle chaincode querycommitted -C loyaltychannel 2>/dev/null | grep -q "loyalty"; then
        local chaincode_info=$(docker exec cli peer lifecycle chaincode querycommitted -C loyaltychannel | grep "Name: loyalty" | cut -d, -f1-3)
        print_success "Chaincode status: $chaincode_info"
    else
        print_error "Chaincode is not deployed or accessible"
    fi
    
    # Check chaincode container
    if docker ps | grep -q "dev-peer.*loyalty"; then
        local cc_container=$(docker ps --format "{{.Names}}" | grep "dev-peer.*loyalty")
        print_success "Chaincode container is running: $cc_container"
        check_container_resources "$cc_container" "Chaincode Container"
    else
        print_warning "Chaincode container is not running"
    fi
}

# Function to check application services health
check_app_health() {
    print_header "APPLICATION SERVICES HEALTH CHECK"
    
    # Check database
    check_container_health "loyalty_postgres" "PostgreSQL Database"
    check_container_resources "loyalty_postgres" "PostgreSQL Database"
    
    # Check database connectivity
    if docker exec loyalty_postgres pg_isready -U loyalty_user >/dev/null 2>&1; then
        print_success "Database connectivity is working"
    else
        print_error "Database is not accessible"
    fi
    
    # Check backend
    check_container_health "loyalty_backend" "Backend API"
    check_container_resources "loyalty_backend" "Backend API"
    
    # Check backend API
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        print_success "Backend API is responding"
    else
        print_error "Backend API is not responding"
    fi
    
    # Check frontend
    check_container_health "loyalty_frontend" "Frontend Web"
    check_container_resources "loyalty_frontend" "Frontend Web"
    
    # Check frontend accessibility
    if curl -s http://localhost >/dev/null 2>&1; then
        print_success "Frontend is accessible"
    else
        print_error "Frontend is not accessible"
    fi
}

# Function to check Explorer health
check_explorer_health() {
    print_header "HYPERLEDGER EXPLORER HEALTH CHECK"
    
    # Check Explorer DB
    if docker ps | grep -q "explorerdb"; then
        check_container_health "explorerdb" "Explorer Database"
        check_container_resources "explorerdb" "Explorer Database"
        
        if docker exec $(docker ps --format "{{.Names}}" | grep explorerdb) pg_isready -U hppoc >/dev/null 2>&1; then
            print_success "Explorer database connectivity is working"
        else
            print_error "Explorer database is not accessible"
        fi
    else
        print_warning "Explorer database is not running"
    fi
    
    # Check Explorer
    if docker ps | grep -q "explorer"; then
        check_container_health "explorer" "Hyperledger Explorer"
        check_container_resources "explorer" "Hyperledger Explorer"
        
        if curl -s http://localhost:8090 >/dev/null 2>&1; then
            print_success "Explorer web interface is accessible"
        else
            print_error "Explorer web interface is not responding"
        fi
    else
        print_warning "Hyperledger Explorer is not running"
    fi
}

# Function to check system resources
check_system_resources() {
    print_header "SYSTEM RESOURCES CHECK"
    
    # Check disk usage
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        print_warning "Disk usage is high: ${disk_usage}%"
    else
        print_success "Disk usage is normal: ${disk_usage}%"
    fi
    
    # Check memory usage
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -gt "$MEMORY_THRESHOLD" ]; then
        print_warning "System memory usage is high: ${mem_usage}%"
    else
        print_success "System memory usage is normal: ${mem_usage}%"
    fi
    
    # Check load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | tr -d ' ')
    print_info "System load average: $load_avg"
    
    # Check Docker daemon
    if docker system info >/dev/null 2>&1; then
        print_success "Docker daemon is healthy"
    else
        print_error "Docker daemon is not responding"
    fi
}

# Function to test blockchain functionality
test_blockchain_functionality() {
    print_header "BLOCKCHAIN FUNCTIONALITY TEST"
    
    local test_customer="HEALTH_CHECK_$(date +%s)"
    
    # Test account creation
    print_info "Testing account creation..."
    local create_result=$(docker exec cli peer chaincode invoke \
        -o orderer.loyalty.com:7050 \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/msp/tlscacerts/tlsca.loyalty.com-cert.pem \
        -C loyaltychannel \
        -n loyalty \
        --peerAddresses peer0.bank.loyalty.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/peers/peer0.bank.loyalty.com/msp/tlscacerts/tlsca.bank.loyalty.com-cert.pem \
        -c "{\"function\":\"CreateLoyaltyAccount\",\"Args\":[\"$test_customer\"]}" 2>&1)
    
    if echo "$create_result" | grep -q "Chaincode invoke successful"; then
        print_success "Account creation test: PASSED"
    else
        print_error "Account creation test: FAILED"
        print_info "Error: $create_result"
        return 1
    fi
    
    # Test account query
    print_info "Testing account query..."
    local query_result=$(docker exec cli peer chaincode query \
        -C loyaltychannel \
        -n loyalty \
        -c "{\"function\":\"QueryLoyaltyAccount\",\"Args\":[\"$test_customer\"]}" 2>&1)
    
    if echo "$query_result" | grep -q "$test_customer"; then
        print_success "Account query test: PASSED"
    else
        print_error "Account query test: FAILED"
        print_info "Error: $query_result"
        return 1
    fi
    
    print_success "All blockchain functionality tests passed"
}

# Function to run full health check
run_health_check() {
    print_header "LOYALTY BLOCKCHAIN SYSTEM HEALTH CHECK"
    log_message "Starting health check..."
    
    check_system_resources
    echo ""
    
    check_fabric_health
    echo ""
    
    check_app_health
    echo ""
    
    check_explorer_health
    echo ""
    
    test_blockchain_functionality
    echo ""
    
    print_header "HEALTH CHECK SUMMARY"
    log_message "Health check completed"
    
    # Count issues
    local error_count=$(grep "ERROR:" "$LOG_FILE" | wc -l)
    local warning_count=$(grep "WARNING:" "$LOG_FILE" | wc -l)
    
    if [ "$error_count" -eq 0 ] && [ "$warning_count" -eq 0 ]; then
        print_success "System is healthy with no issues detected"
    elif [ "$error_count" -eq 0 ]; then
        print_warning "System is operational with $warning_count warnings"
    else
        print_error "System has $error_count errors and $warning_count warnings"
    fi
    
    print_info "Full health check log: $LOG_FILE"
}

# Function to monitor continuously
monitor_continuous() {
    print_header "STARTING CONTINUOUS MONITORING"
    print_info "Monitoring interval: ${HEALTH_CHECK_INTERVAL}s"
    print_info "Press Ctrl+C to stop monitoring"
    
    while true; do
        run_health_check
        echo ""
        print_info "Next check in ${HEALTH_CHECK_INTERVAL} seconds..."
        sleep "$HEALTH_CHECK_INTERVAL"
        echo ""
    done
}

# Function to generate system report
generate_report() {
    local report_file="/tmp/loyalty-system-report-$(date +%Y%m%d-%H%M%S).txt"
    
    print_header "GENERATING SYSTEM REPORT"
    
    {
        echo "========================================"
        echo "LOYALTY BLOCKCHAIN SYSTEM REPORT"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""
        
        echo "SYSTEM INFORMATION:"
        echo "- Hostname: $(hostname)"
        echo "- OS: $(uname -a)"
        echo "- Docker Version: $(docker --version)"
        echo "- Uptime: $(uptime)"
        echo ""
        
        echo "CONTAINER STATUS:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        echo "FABRIC NETWORK STATUS:"
        docker exec cli peer channel list 2>/dev/null || echo "Channel access failed"
        docker exec cli peer lifecycle chaincode querycommitted -C loyaltychannel 2>/dev/null || echo "Chaincode query failed"
        echo ""
        
        echo "SYSTEM RESOURCES:"
        df -h
        echo ""
        free -h
        echo ""
        
        echo "RECENT LOGS (last 50 lines):"
        tail -50 "$LOG_FILE" 2>/dev/null || echo "No log file found"
        
    } > "$report_file"
    
    print_success "System report generated: $report_file"
}

# Function to show usage
usage() {
    echo -e "${BLUE}Loyalty Blockchain System Monitoring${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} $0 [COMMAND]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  health                    Run one-time health check"
    echo "  monitor                   Start continuous monitoring"
    echo "  fabric                    Check only Fabric network health"
    echo "  app                       Check only application services health"
    echo "  explorer                  Check only Explorer health"
    echo "  test                      Test blockchain functionality"
    echo "  resources                 Check system resources only"
    echo "  report                    Generate comprehensive system report"
    echo "  help                      Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 health                 # Quick health check"
    echo "  $0 monitor                # Continuous monitoring"
    echo "  $0 test                   # Test blockchain functions"
}

# Main script logic
case "${1}" in
    "health"|"check")
        run_health_check
        ;;
    "monitor")
        monitor_continuous
        ;;
    "fabric")
        check_fabric_health
        ;;
    "app")
        check_app_health
        ;;
    "explorer")
        check_explorer_health
        ;;
    "test")
        test_blockchain_functionality
        ;;
    "resources")
        check_system_resources
        ;;
    "report")
        generate_report
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
