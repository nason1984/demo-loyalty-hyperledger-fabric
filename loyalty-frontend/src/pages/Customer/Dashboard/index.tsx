// File: src/pages/Customer/Dashboard/index.tsx

import React, { useEffect, useState } from 'react';
import { Row, Col, Card, Statistic, Typography, Button, Table, Spin, Alert, message } from 'antd';
import { WalletOutlined, GiftOutlined, SwapOutlined, EyeOutlined } from '@ant-design/icons';
import { Link } from 'react-router-dom';
import { useSelector } from 'react-redux';
import axiosClient from '../../../api/axiosClient';
import { RootState } from '../../../redux/store';

const { Title, Text } = Typography;

// Interface cho dữ liệu tài khoản
interface AccountData {
    customerID: string;
    balance: number;
    lastUpdated: string;
}

// Interface cho giao dịch
interface Transaction {
    id: string;
    timestamp: string;
    description: string;
    amount: number;
    type: 'earn' | 'redeem' | 'transfer' | 'bonus';
}

const CustomerDashboard: React.FC = () => {
    // Lấy thông tin người dùng từ Redux store
    const { user } = useSelector((state: RootState) => state.auth);
    
    // State management
    const [accountData, setAccountData] = useState<AccountData | null>(null);
    const [recentTransactions, setRecentTransactions] = useState<Transaction[]>([]);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    // Fetch data từ API
    useEffect(() => {
        const fetchDashboardData = async () => {
            if (!user?.username) {
                setError('Không tìm thấy thông tin người dùng');
                setLoading(false);
                return;
            }

            try {
                setLoading(true);
                setError(null);
                
                // Gọi đồng thời 2 API
                const [accountResponse, transactionsResponse] = await Promise.all([
                    axiosClient.get(`/accounts/${user.username}`),
                    axiosClient.get(`/accounts/${user.username}/recent-transactions`)
                ]);
                
                console.log('Account API response:', accountResponse);
                console.log('Transactions API response:', transactionsResponse);
                
                // Xử lý dữ liệu tài khoản
                const accountApiData = accountResponse.data?.data || accountResponse.data;
                console.log('Parsed account data:', accountApiData);
                setAccountData(accountApiData);
                
                // Xử lý dữ liệu giao dịch  
                const transactionsApiData = transactionsResponse.data?.data || transactionsResponse.data;
                console.log('Parsed transactions data:', transactionsApiData);
                setRecentTransactions(Array.isArray(transactionsApiData) ? transactionsApiData : []);
                
            } catch (err: any) {
                console.error('API Error:', err);
                setError(err.response?.data?.error || err.message || 'Có lỗi xảy ra khi tải dữ liệu');
                message.error('Không thể tải dữ liệu dashboard');
            } finally {
                setLoading(false);
            }
        };

        fetchDashboardData();
    }, [user?.username]);

    // Cấu hình columns cho bảng giao dịch
    const transactionColumns = [
        {
            title: 'Thời gian',
            dataIndex: 'timestamp',
            key: 'timestamp',
            width: '25%',
            render: (timestamp: string) => (
                <Text>{new Date(timestamp).toLocaleString('vi-VN')}</Text>
            ),
        },
        {
            title: 'Mô tả',
            dataIndex: 'description',
            key: 'description',
            ellipsis: true,
        },
        {
            title: 'Số điểm',
            dataIndex: 'amount',
            key: 'amount',
            width: '20%',
            render: (amount: number) => (
                <Text style={{ 
                    color: amount > 0 ? '#52c41a' : '#ff4d4f',
                    fontWeight: 'bold'
                }}>
                    {amount > 0 ? '+' : ''}{amount}
                </Text>
            ),
        },
    ];

    // Hiển thị loading
    if (loading) {
        return (
            <div style={{ textAlign: 'center', padding: '50px' }}>
                <Spin size="large" />
                <div style={{ marginTop: '16px' }}>
                    <Text>Đang tải dữ liệu...</Text>
                </div>
            </div>
        );
    }

    // Hiển thị lỗi
    if (error) {
        return (
            <div style={{ padding: '20px' }}>
                <Alert
                    message="Lỗi tải dữ liệu"
                    description={error}
                    type="error"
                    showIcon
                />
            </div>
        );
    }

    return (
        <div style={{ padding: '0' }}>
            <Title level={2} style={{ marginBottom: '24px' }}>
                Chào mừng, {user?.username}!
            </Title>
            
            <Row gutter={[24, 24]}>
                {/* Cột Trái */}
                <Col xs={24} lg={16}>
                    {/* Card Số dư hiện tại */}
                    <Card style={{ marginBottom: '24px' }}>
                        <Statistic
                            title="Số dư hiện tại"
                            value={accountData?.balance || 0}
                            precision={0}
                            valueStyle={{ color: '#3f8600', fontSize: '36px' }}
                            prefix={<WalletOutlined />}
                            suffix="điểm"
                        />
                        <Text type="secondary" style={{ fontSize: '12px' }}>
                            Cập nhật lần cuối: {accountData?.lastUpdated ? 
                                new Date(accountData.lastUpdated).toLocaleString('vi-VN') : 
                                'Chưa có dữ liệu'
                            }
                        </Text>
                    </Card>

                    {/* Card Giao dịch gần đây */}
                    <Card
                        title="Giao dịch gần đây"
                        extra={
                            <Link to="/history">
                                <Button type="link" icon={<EyeOutlined />}>
                                    Xem tất cả
                                </Button>
                            </Link>
                        }
                    >
                        <Table
                            columns={transactionColumns}
                            dataSource={recentTransactions}
                            rowKey="id"
                            pagination={false}
                            size="small"
                            locale={{
                                emptyText: 'Chưa có giao dịch nào'
                            }}
                        />
                    </Card>
                </Col>

                {/* Cột Phải */}
                <Col xs={24} lg={8}>
                    <Card title="Hành động nhanh">
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            <Link to="/redeem" style={{ textDecoration: 'none' }}>
                                <Button 
                                    type="primary" 
                                    size="large" 
                                    block
                                    icon={<GiftOutlined />}
                                    style={{ 
                                        height: '60px',
                                        fontSize: '16px',
                                        fontWeight: 'bold'
                                    }}
                                >
                                    Quy đổi Ngay
                                </Button>
                            </Link>
                            
                            <Link to="/transfer" style={{ textDecoration: 'none' }}>
                                <Button 
                                    type="default" 
                                    size="large" 
                                    block
                                    icon={<SwapOutlined />}
                                    style={{ 
                                        height: '60px',
                                        fontSize: '16px',
                                        fontWeight: 'bold'
                                    }}
                                >
                                    Chuyển Điểm
                                </Button>
                            </Link>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
};

export default CustomerDashboard;