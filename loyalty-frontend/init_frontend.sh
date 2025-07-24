#!/bin/bash

# Di chuyển vào thư mục frontend nếu tồn tại
# if [ -d "loyalty-frontend" ]; then
#   cd loyalty-frontend
# else
#   echo "Lỗi: Thư mục 'frontend' không tồn tại. Vui lòng chạy 'npx create-react-app frontend --template typescript' trước."
#   exit 1
# fi

echo "🚀 Bắt đầu khởi tạo cấu trúc thư mục cho loyalty-frontend..."

# Tạo các thư mục chính trong src/
mkdir -p src/api src/assets src/components src/pages src/redux src/styles src/utils

# --- Tạo các file trong components ---
mkdir -p src/components/Layout
touch src/components/Layout/index.tsx
touch src/components/Layout/Layout.css

# --- Tạo các file trong pages (theo vai trò) ---
# Common
mkdir -p src/pages/LoginPage
touch src/pages/LoginPage/index.tsx
touch src/pages/LoginPage/LoginPage.css

# Customer Role
mkdir -p src/pages/Customer/Dashboard
mkdir -p src/pages/Customer/History
mkdir -p src/pages/Customer/Redeem
mkdir -p src/pages/Customer/Transfer
touch src/pages/Customer/Dashboard/index.tsx
touch src/pages/Customer/History/index.tsx
touch src/pages/Customer/Redeem/index.tsx
touch src/pages/Customer/Transfer/index.tsx

# Employee Role
mkdir -p src/pages/Employee/Dashboard
mkdir -p src/pages/Employee/CustomerDetail
touch src/pages/Employee/Dashboard/index.tsx
touch src/pages/Employee/CustomerDetail/index.tsx

# --- Tạo các file trong redux (quản lý state) ---
mkdir -p src/redux/slices
touch src/redux/store.ts
touch src/redux/slices/authSlice.ts

# --- Tạo các file api ---
touch src/api/axiosClient.ts

echo "✅ Cấu trúc thư mục đã được tạo thành công!"
echo "Cấu trúc thư mục của bạn trong 'src/':"
ls -R src/