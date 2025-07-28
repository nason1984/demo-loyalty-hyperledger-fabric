# LOYALTY BLOCKCHAIN SYSTEM - OPERATIONS GUIDE

## 📋 Tổng Quan

Hệ thống Loyalty Blockchain bao gồm:
- **Hyperledger Fabric Network** (Orderer, 2 Peers, CouchDB)
- **Loyalty Chaincode** (Smart contract cho quản lý điểm loyalty)
- **Backend API** (RESTful API service)
- **Frontend Web App** (React application)
- **Hyperledger Explorer** (Blockchain explorer)
- **Monitoring** (Prometheus + Grafana)

## 🚀 Khởi Động Nhanh

### 1. Khởi động toàn bộ hệ thống:
```bash
cd /home/ubuntu/loyalty-project
./manage-loyalty-system.sh start-all
```

### 2. Kiểm tra trạng thái:
```bash
./manage-loyalty-system.sh status
```

### 3. Truy cập giao diện:
- **Frontend:** http://192.168.64.3
- **Explorer:** http://192.168.64.3:8090
- **Backend API:** http://192.168.64.3:8080

## 🔧 Quản Lý Hệ Thống

### Scripts Chính:

#### `manage-loyalty-system.sh` - Script quản lý chính
```bash
# Khởi động/Dừng
./manage-loyalty-system.sh start-all          # Khởi động toàn bộ
./manage-loyalty-system.sh stop-all           # Dừng toàn bộ
./manage-loyalty-system.sh restart-all        # Khởi động lại

# Quản lý từng thành phần
./manage-loyalty-system.sh start-network      # Chỉ Fabric network
./manage-loyalty-system.sh start-backend      # Chỉ backend services
./manage-loyalty-system.sh start-explorer     # Chỉ explorer

# Chaincode
./manage-loyalty-system.sh deploy-chaincode   # Deploy chaincode
./manage-loyalty-system.sh test-chaincode     # Test chaincode
./manage-loyalty-system.sh auto-deploy        # Auto-deploy nếu thiếu

# Trạng thái
./manage-loyalty-system.sh status             # Hiển thị trạng thái
```

#### `deploy-chaincode.sh` - Script deploy chaincode
```bash
# Deploy chaincode tự động
./deploy-chaincode.sh                         # Version 1.3, sequence 1
./deploy-chaincode.sh 1.4                     # Version 1.4, sequence 1
./deploy-chaincode.sh 1.4 2                   # Version 1.4, sequence 2
```

#### `backup-restore.sh` - Script backup & restore
```bash
# Backup
./backup-restore.sh backup                    # Tạo backup

# Restore
./backup-restore.sh list                      # Liệt kê backups
./backup-restore.sh restore backup_name       # Restore từ backup

# Cleanup
./backup-restore.sh clean 30                  # Xóa backup >30 ngày
```

#### `service-manager.sh` - Quản lý systemd service
```bash
# Cài đặt service auto-start
./service-manager.sh install                  # Cài đặt service
./service-manager.sh start                    # Khởi động service
./service-manager.sh status                   # Trạng thái service
./service-manager.sh logs                     # Xem logs
```

## 🔄 Giải Quyết Vấn Đề "Chaincode Not Found"

### Nguyên Nhân:
Mỗi lần `stop-all` và `start-all`, chaincode bị mất vì:
1. Docker containers bị recreate
2. Chaincode không được tự động deploy lại

### Giải Pháp Tự Động:
Script `manage-loyalty-system.sh` đã được cập nhật với `auto_deploy_chaincode()`:

```bash
# Hàm này tự động:
# 1. Kiểm tra chaincode có tồn tại không
# 2. Nếu không có, tự động deploy
# 3. Sử dụng script deploy-chaincode.sh

auto_deploy_chaincode() {
    if chaincode exists; then
        return "OK"
    else
        ./deploy-chaincode.sh
    fi
}
```

### Kiểm Tra Thủ Công:
```bash
# Kiểm tra chaincode
docker exec cli peer lifecycle chaincode querycommitted --channelID loyaltychannel --name loyalty

# Nếu không có, deploy lại
./deploy-chaincode.sh
```

## 📦 Backup & Recovery

### Tạo Backup Trước Khi Stop:
```bash
# Luôn backup trước khi stop
./backup-restore.sh backup
./manage-loyalty-system.sh stop-all
```

### Recovery Sau Reboot:
```bash
# Phương án 1: Automatic (nếu đã cài service)
sudo systemctl start loyalty-blockchain

# Phương án 2: Manual
./manage-loyalty-system.sh start-all

# Phương án 3: Restore từ backup
./backup-restore.sh restore backup_name
```

## 🔧 Vận Hành Hàng Ngày

### 1. Khởi Động Sau Reboot:

#### A. Automatic (Khuyến nghị):
```bash
# Cài đặt service một lần
./service-manager.sh install

# Hệ thống sẽ tự động khởi động sau reboot
# Kiểm tra: sudo systemctl status loyalty-blockchain
```

#### B. Manual:
```bash
./manage-loyalty-system.sh start-all
```

### 2. Monitoring Hàng Ngày:
```bash
# Kiểm tra trạng thái
./manage-loyalty-system.sh status

# Kiểm tra logs
docker logs backend
docker logs explorer.mynetwork.com

# Kiểm tra service logs (nếu dùng systemd)
./service-manager.sh logs
```

### 3. Backup Định Kỳ:
```bash
# Tạo cron job cho backup hàng ngày
crontab -e

# Thêm dòng sau (backup lúc 2h sáng):
0 2 * * * /home/ubuntu/loyalty-project/backup-restore.sh backup

# Cleanup hàng tuần (chủ nhật 3h sáng):
0 3 * * 0 /home/ubuntu/loyalty-project/backup-restore.sh clean 7
```

## 🚨 Troubleshooting

### 1. Chaincode Not Found:
```bash
# Solution 1: Auto-deploy
./manage-loyalty-system.sh auto-deploy

# Solution 2: Manual deploy
./deploy-chaincode.sh

# Solution 3: Restart with auto-deploy
./manage-loyalty-system.sh restart-all
```

### 2. Explorer Not Accessible:
```bash
# Restart explorer
docker restart explorer.mynetwork.com

# Check logs
docker logs explorer.mynetwork.com

# Full restart
./manage-loyalty-system.sh stop-explorer
./manage-loyalty-system.sh start-explorer
```

### 3. Network Issues:
```bash
# Check ports
ss -tlnp | grep ":80\|:8090\|:8080"

# Test connectivity
curl http://localhost:80
curl http://localhost:8090

# Restart network
./manage-loyalty-system.sh stop-network
./manage-loyalty-system.sh start-network
```

### 4. Complete System Failure:
```bash
# Stop everything
./manage-loyalty-system.sh stop-all
docker system prune -f

# Restore from backup
./backup-restore.sh list
./backup-restore.sh restore latest_backup_name

# Or fresh start
./manage-loyalty-system.sh start-all
```

## 📊 Health Checks

### Automated Health Check Script:
```bash
#!/bin/bash
# health-check.sh

echo "🔍 Loyalty System Health Check"

# Check containers
echo "📦 Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(backend|frontend|explorer|orderer|peer|postgres)"

# Check chaincode
echo "🔗 Chaincode:"
docker exec cli peer lifecycle chaincode querycommitted --channelID loyaltychannel --name loyalty 2>/dev/null || echo "❌ Chaincode not found"

# Check connectivity
echo "🌐 Connectivity:"
curl -s http://localhost:80 >/dev/null && echo "✅ Frontend OK" || echo "❌ Frontend FAIL"
curl -s http://localhost:8090 >/dev/null && echo "✅ Explorer OK" || echo "❌ Explorer FAIL"
curl -s http://localhost:8080/health >/dev/null && echo "✅ Backend OK" || echo "❌ Backend FAIL"
```

## 📈 Best Practices

### 1. Deployment:
- Luôn backup trước khi deploy
- Test trên môi trường dev trước
- Deploy incremental version/sequence

### 2. Monitoring:
- Kiểm tra daily health
- Monitor disk space cho backups
- Check container logs thường xuyên

### 3. Backup:
- Daily automatic backup
- Weekly cleanup old backups
- Test restore process định kỳ

### 4. Security:
- Regular update containers
- Monitor access logs
- Backup private keys/certificates

## 📞 Support Commands

```bash
# Quick diagnosis
./manage-loyalty-system.sh status
docker ps -a
docker logs backend --tail 20

# Emergency recovery
./backup-restore.sh restore latest_backup
./manage-loyalty-system.sh start-all

# Complete reset (last resort)
./manage-loyalty-system.sh stop-all
docker system prune -af
./manage-loyalty-system.sh start-all
```

---

**🎯 Kết Luận:**
Với kịch bản vận hành này, hệ thống sẽ:
- ✅ Tự động deploy chaincode sau mỗi restart
- ✅ Có backup/restore toàn diện
- ✅ Có systemd service cho auto-start
- ✅ Có monitoring và troubleshooting
- ✅ Đảm bảo high availability
