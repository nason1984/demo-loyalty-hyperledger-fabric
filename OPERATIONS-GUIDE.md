# 🚀 Loyalty Blockchain Network - Hướng Dẫn Vận Hành

## 📋 Tổng Quan

Hệ thống Loyalty Blockchain Network bao gồm:
- **Hyperledger Fabric Network**: Mạng blockchain với 1 orderer, 2 peers
- **Loyalty Chaincode**: Smart contract quản lý điểm loyalty 
- **Backend API**: REST API Node.js/Go kết nối blockchain
- **Frontend Web**: Giao diện React cho người dùng
- **Hyperledger Explorer**: Dashboard giám sát blockchain
- **PostgreSQL**: Database cho backend và Explorer

## 🛠️ Kịch Bản Vận Hành

### 1. Script Quản Lý Chính
```bash
# Script quản lý toàn bộ hệ thống
./manage-loyalty-system.sh [command] [options]
```

**Các lệnh chính:**
- `start-all`: Khởi động toàn bộ hệ thống
- `stop-all`: Dừng toàn bộ hệ thống  
- `restart-all`: Khởi động lại toàn bộ hệ thống
- `status`: Kiểm tra trạng thái hệ thống
- `deploy-chaincode [version]`: Deploy/upgrade chaincode
- `test-chaincode`: Test chức năng chaincode

### 2. Script Khởi Động Nhanh
```bash
# Lệnh nhanh cho các thao tác thường dùng
./loyalty-quick.sh [command]
```

**Các lệnh nhanh:**
- `start`: Khởi động hệ thống
- `stop`: Dừng hệ thống
- `restart`: Khởi động lại
- `status`: Kiểm tra trạng thái
- `test`: Test chaincode

### 3. Script Giám Sát
```bash
# Giám sát và health check
./loyalty-monitor.sh [command]
```

**Các lệnh giám sát:**
- `health`: Kiểm tra sức khỏe hệ thống
- `monitor`: Giám sát liên tục
- `fabric`: Kiểm tra Fabric network
- `app`: Kiểm tra application services
- `explorer`: Kiểm tra Explorer
- `test`: Test blockchain functionality
- `report`: Tạo báo cáo hệ thống

### 4. Script Backup & Restore
```bash
# Sao lưu và phục hồi
./loyalty-backup.sh [command]
```

**Các lệnh backup:**
- `backup`: Tạo backup toàn bộ hệ thống
- `list`: Liệt kê các backup có sẵn
- `restore <backup-name>`: Phục hồi từ backup
- `clean [days]`: Xóa backup cũ

## 🚀 Hướng Dẫn Khởi Động

### Lần Đầu Khởi Động
```bash
# 1. Khởi động toàn bộ hệ thống
./manage-loyalty-system.sh start-all

# 2. Kiểm tra trạng thái
./manage-loyalty-system.sh status

# 3. Test chaincode
./manage-loyalty-system.sh test-chaincode
```

### Khởi Động Hàng Ngày
```bash
# Khởi động nhanh
./loyalty-quick.sh start

# Kiểm tra trạng thái
./loyalty-quick.sh status
```

### Sau Reboot Server
```bash
# 1. Khởi động network trước
./manage-loyalty-system.sh start-network

# 2. Khởi động backend services
./manage-loyalty-system.sh start-backend

# 3. Khởi động Explorer (optional)
./manage-loyalty-system.sh start-explorer

# Hoặc khởi động tất cả cùng lúc
./loyalty-quick.sh start
```

## 🔧 Các Tình Huống Xử Lý

### 1. Chaincode Bị Lỗi
```bash
# Deploy lại chaincode với version mới
./manage-loyalty-system.sh deploy-chaincode 1.4

# Test chaincode
./manage-loyalty-system.sh test-chaincode
```

### 2. Database Bị Lỗi
```bash
# Dừng services
./manage-loyalty-system.sh stop-backend

# Khởi động lại
./manage-loyalty-system.sh start-backend
```

### 3. Network Bị Disconnect
```bash
# Khởi động lại network
./manage-loyalty-system.sh stop-network
./manage-loyalty-system.sh start-network

# Deploy lại chaincode nếu cần
./manage-loyalty-system.sh deploy-chaincode
```

### 4. Container Bị Crash
```bash
# Kiểm tra trạng thái
docker ps -a

# Khởi động lại hệ thống
./loyalty-quick.sh restart
```

## 📊 Giám Sát Hệ Thống

### Kiểm Tra Sức Khỏe
```bash
# Kiểm tra nhanh
./loyalty-monitor.sh health

# Giám sát liên tục (Ctrl+C để dừng)
./loyalty-monitor.sh monitor

# Tạo báo cáo chi tiết
./loyalty-monitor.sh report
```

### URLs Truy Cập
- **Frontend**: http://localhost
- **Backend API**: http://localhost:8080
- **Hyperledger Explorer**: http://localhost:8090
  - Username: `exploreradmin`
  - Password: `exploreradminpw`

### Kiểm Tra Logs
```bash
# Logs của containers
docker logs loyalty_backend
docker logs loyalty_frontend
docker logs peer0.bank.loyalty.com
docker logs orderer.loyalty.com

# Logs hệ thống
tail -f /tmp/loyalty-system-monitor.log
```

## 💾 Backup & Restore

### Tạo Backup
```bash
# Backup toàn bộ hệ thống
./loyalty-backup.sh backup

# Liệt kê backups
./loyalty-backup.sh list
```

### Phục Hồi Backup
```bash
# Xem danh sách backup
./loyalty-backup.sh list

# Phục hồi backup cụ thể
./loyalty-backup.sh restore loyalty-backup-20250728-143022
```

### Dọn Dẹp Backup Cũ
```bash
# Xóa backup cũ hơn 30 ngày
./loyalty-backup.sh clean

# Xóa backup cũ hơn 7 ngày
./loyalty-backup.sh clean 7
```

## 🔍 Troubleshooting

### Lỗi Thường Gặp

1. **Chaincode không deploy được**
   - Kiểm tra network có đang chạy không
   - Kiểm tra code có lỗi syntax không
   - Thử deploy lại với version mới

2. **Frontend không truy cập được**
   - Kiểm tra container có chạy không: `docker ps`
   - Kiểm tra port 80 có bị conflict không
   - Restart frontend: `docker restart loyalty_frontend`

3. **Backend API không hoạt động**
   - Kiểm tra database connection
   - Kiểm tra Fabric network connection
   - Xem logs: `docker logs loyalty_backend`

4. **Explorer không hiển thị data**
   - Kiểm tra connection-profile cấu hình đúng
   - Restart Explorer: `./manage-loyalty-system.sh restart-explorer`
   - Kiểm tra network có accessible không

### Commands Debug
```bash
# Kiểm tra containers
docker ps -a

# Kiểm tra networks
docker network ls

# Kiểm tra volumes
docker volume ls

# Xem logs real-time
docker logs -f <container-name>

# Truy cập container
docker exec -it <container-name> bash

# Test chaincode manual
docker exec cli peer chaincode query -C loyaltychannel -n loyalty -c '{"function":"QueryLoyaltyAccount","Args":["TEST001"]}'
```

## 📅 Maintenance Schedule

### Hàng Ngày
- Kiểm tra `./loyalty-quick.sh status`
- Xem logs có lỗi bất thường không

### Hàng Tuần  
- Chạy `./loyalty-monitor.sh health`
- Backup hệ thống `./loyalty-backup.sh backup`
- Clean logs cũ

### Hàng Tháng
- Clean backups cũ `./loyalty-backup.sh clean`
- Update dependencies nếu cần
- Review và optimize performance

## 🚨 Emergency Procedures

### Khôi Phục Nhanh
```bash
# Dừng tất cả
./loyalty-quick.sh stop

# Clean Docker
docker system prune -f

# Khởi động lại
./loyalty-quick.sh start
```

### Khôi Phục Từ Backup
```bash
# Dừng hệ thống
./loyalty-quick.sh stop

# Phục hồi backup gần nhất
./loyalty-backup.sh restore <latest-backup>

# Kiểm tra
./loyalty-quick.sh status
```

## 📞 Support Information

- **Repository**: https://github.com/nason1984/demo-loyalty-hyperledger-fabric
- **Documentation**: `/docs` directory
- **Logs Location**: `/tmp/loyalty-system-monitor.log`
- **Backup Location**: `/home/ubuntu/loyalty-backups`

---
*Generated by AI Assistant - Last Updated: $(date)*
