// File: src/pages/Customer/History/index.tsx

import React, { useState } from 'react';
import { Table, Tag, Typography, Card, Input, Space, Badge } from 'antd';
import { SearchOutlined, HistoryOutlined } from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';

// =========================================================================================
// Sprint 3 - Task 4: Xây dựng Trang Lịch sử Giao dịch
// Yêu cầu: VIEW-CUS-02
//
// Logic chính:
// 1. Hiển thị một tiêu đề chính cho trang, ví dụ: "Lịch sử Giao dịch".
// 2. Sử dụng component `Table` của Ant Design để hiển thị danh sách các giao dịch.
// 3. Bảng bao gồm các cột: "ID Giao dịch", "Loại", "Số điểm", "Mô tả", và "Thời gian".
// 4. Sử dụng dữ liệu giả lập (hardcoded data) để điền vào bảng với ít nhất 3-4 giao dịch mẫu (bao gồm các loại ISSUE, REDEEM, TRANSFER_OUT, TRANSFER_IN).
// 5. Trong cột "Loại", sử dụng component `Tag` của Ant Design để hiển thị các loại giao dịch với màu sắc khác nhau cho dễ phân biệt (ví dụ: green cho ISSUE/TRANSFER_IN, orange cho REDEEM/TRANSFER_OUT).
// 6. Thêm một ô `Input.Search` phía trên bảng để người dùng có thể (giả lập) tìm kiếm theo mô tả.
// =========================================================================================
// Gợi ý cho Copilot:
interface TransactionDataType {
  key: string;
  transactionId: string;
  type: string;
  amount: number;
  description: string;
  timestamp: string;
}

const TransactionHistoryPage: React.FC = () => {
    const [searchText, setSearchText] = useState<string>('');

    // 4. Dữ liệu giả lập với các loại giao dịch khác nhau
    const transactionData: TransactionDataType[] = [
        {
            key: '1',
            transactionId: 'TXN001',
            type: 'ISSUE',
            amount: 500,
            description: 'Tích điểm từ mua sắm tại cửa hàng ABC',
            timestamp: '2025-01-23 10:30:00',
        },
        {
            key: '2', 
            transactionId: 'TXN002',
            type: 'REDEEM',
            amount: -200,
            description: 'Quy đổi voucher giảm giá 20%',
            timestamp: '2025-01-22 15:45:00',
        },
        {
            key: '3',
            transactionId: 'TXN003', 
            type: 'TRANSFER_IN',
            amount: 300,
            description: 'Nhận chuyển điểm từ tài khoản CUST002',
            timestamp: '2025-01-21 09:15:00',
        },
        {
            key: '4',
            transactionId: 'TXN004',
            type: 'TRANSFER_OUT', 
            amount: -150,
            description: 'Chuyển điểm tặng sinh nhật bạn bè',
            timestamp: '2025-01-20 14:20:00',
        },
        {
            key: '5',
            transactionId: 'TXN005',
            type: 'ISSUE',
            amount: 1000,
            description: 'Bonus điểm chào mừng thành viên mới',
            timestamp: '2025-01-19 08:00:00',
        },
        {
            key: '6',
            transactionId: 'TXN006',
            type: 'REDEEM',
            amount: -800,
            description: 'Đổi thẻ quà tặng 500,000 VND',
            timestamp: '2025-01-18 16:30:00',
        },
    ];

    // Function to get tag color based on transaction type
    const getTagColor = (type: string): string => {
        switch (type) {
            case 'ISSUE':
            case 'TRANSFER_IN':
                return 'green';
            case 'REDEEM':
            case 'TRANSFER_OUT':
                return 'orange';
            default:
                return 'blue';
        }
    };

    // Function to get tag text based on transaction type
    const getTagText = (type: string): string => {
        switch (type) {
            case 'ISSUE':
                return 'Tích điểm';
            case 'REDEEM':
                return 'Quy đổi';
            case 'TRANSFER_IN':
                return 'Nhận chuyển';
            case 'TRANSFER_OUT':
                return 'Chuyển đi';
            default:
                return type;
        }
    };

    // 3. Định nghĩa các cột cho bảng
    const columns: ColumnsType<TransactionDataType> = [
        {
            title: 'ID Giao dịch',
            dataIndex: 'transactionId',
            key: 'transactionId',
            width: 120,
            render: (text: string) => (
                <Typography.Text code strong style={{ color: '#1890ff' }}>
                    {text}
                </Typography.Text>
            ),
        },
        {
            title: 'Loại',
            dataIndex: 'type',
            key: 'type',
            width: 120,
            render: (type: string) => (
                <Tag color={getTagColor(type)} style={{ fontWeight: '500' }}>
                    {getTagText(type)}
                </Tag>
            ),
            filters: [
                { text: 'Tích điểm', value: 'ISSUE' },
                { text: 'Quy đổi', value: 'REDEEM' },
                { text: 'Nhận chuyển', value: 'TRANSFER_IN' },
                { text: 'Chuyển đi', value: 'TRANSFER_OUT' },
            ],
            onFilter: (value, record) => record.type === value,
        },
        {
            title: 'Số điểm',
            dataIndex: 'amount',
            key: 'amount',
            width: 120,
            render: (amount: number) => (
                <Typography.Text 
                    strong 
                    style={{ 
                        color: amount > 0 ? '#52c41a' : '#ff4d4f',
                        fontSize: '16px'
                    }}
                >
                    {amount > 0 ? '+' : ''}{amount.toLocaleString()}
                </Typography.Text>
            ),
            sorter: (a, b) => a.amount - b.amount,
        },
        {
            title: 'Mô tả',
            dataIndex: 'description',
            key: 'description',
            ellipsis: true,
            render: (text: string) => (
                <Typography.Text style={{ color: '#595959' }}>
                    {text}
                </Typography.Text>
            ),
        },
        {
            title: 'Thời gian',
            dataIndex: 'timestamp',
            key: 'timestamp',
            width: 160,
            render: (timestamp: string) => (
                <Typography.Text type="secondary">
                    {timestamp}
                </Typography.Text>
            ),
            sorter: (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
            defaultSortOrder: 'descend',
        },
    ];

    // Filter data based on search text
    const filteredData = transactionData.filter(item =>
        item.description.toLowerCase().includes(searchText.toLowerCase()) ||
        item.transactionId.toLowerCase().includes(searchText.toLowerCase())
    );

    // Handle search
    const handleSearch = (value: string) => {
        setSearchText(value);
        console.log('Searching for:', value);
    };

    // Calculate statistics
    const totalTransactions = transactionData.length;
    const totalEarned = transactionData
        .filter(t => t.amount > 0)
        .reduce((sum, t) => sum + t.amount, 0);
    const totalSpent = Math.abs(transactionData
        .filter(t => t.amount < 0)
        .reduce((sum, t) => sum + t.amount, 0));

    return (
        <div style={{ padding: '0' }}>
            {/* 1. Tiêu đề chính cho trang */}
            <div style={{ marginBottom: '24px' }}>
                <Typography.Title level={2} style={{ margin: 0, color: '#1890ff' }}>
                    <HistoryOutlined style={{ marginRight: '12px' }} />
                    Lịch sử Giao dịch
                </Typography.Title>
                <Typography.Text type="secondary" style={{ fontSize: '16px' }}>
                    Theo dõi tất cả các giao dịch điểm loyalty của bạn
                </Typography.Text>
            </div>

            {/* Statistics Overview */}
            <Card style={{ marginBottom: '24px', borderRadius: '12px' }}>
                <Space size="large" style={{ width: '100%', justifyContent: 'space-around' }}>
                    <div style={{ textAlign: 'center' }}>
                        <Badge count={totalTransactions} style={{ backgroundColor: '#1890ff' }}>
                            <Typography.Title level={4} style={{ margin: 0, color: '#1890ff' }}>
                                Tổng GD
                            </Typography.Title>
                        </Badge>
                        <Typography.Text type="secondary">giao dịch</Typography.Text>
                    </div>
                    <div style={{ textAlign: 'center' }}>
                        <Typography.Title level={4} style={{ margin: 0, color: '#52c41a' }}>
                            +{totalEarned.toLocaleString()}
                        </Typography.Title>
                        <Typography.Text type="secondary">điểm tích lũy</Typography.Text>
                    </div>
                    <div style={{ textAlign: 'center' }}>
                        <Typography.Title level={4} style={{ margin: 0, color: '#ff4d4f' }}>
                            -{totalSpent.toLocaleString()}
                        </Typography.Title>
                        <Typography.Text type="secondary">điểm sử dụng</Typography.Text>
                    </div>
                </Space>
            </Card>

            {/* 6. Search box phía trên bảng */}
            <Card 
                style={{ 
                    marginBottom: '16px', 
                    borderRadius: '12px',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
                }}
            >
                <Input.Search
                    placeholder="Tìm kiếm theo mô tả hoặc ID giao dịch..."
                    allowClear
                    enterButton={<SearchOutlined />}
                    size="large"
                    onSearch={handleSearch}
                    onChange={(e) => setSearchText(e.target.value)}
                    style={{ maxWidth: '500px' }}
                />
                <Typography.Text type="secondary" style={{ marginLeft: '16px' }}>
                    Tìm thấy {filteredData.length} giao dịch
                </Typography.Text>
            </Card>

            {/* 2. Bảng hiển thị danh sách giao dịch */}
            <Card 
                style={{ 
                    borderRadius: '12px',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
                }}
            >
                <Table<TransactionDataType>
                    columns={columns}
                    dataSource={filteredData}
                    pagination={{
                        pageSize: 10,
                        showSizeChanger: true,
                        showQuickJumper: true,
                        showTotal: (total, range) => 
                            `${range[0]}-${range[1]} của ${total} giao dịch`,
                        style: { marginTop: '16px' }
                    }}
                    scroll={{ x: 800 }}
                    style={{ marginTop: '0' }}
                    rowClassName={(record, index) => 
                        index % 2 === 0 ? 'table-row-light' : 'table-row-dark'
                    }
                />
            </Card>
        </div>
    );
};

export default TransactionHistoryPage;