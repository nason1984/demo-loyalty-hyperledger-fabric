// File: src/pages/Customer/Dashboard/index.tsx

import React from 'react';
import { Row, Col, Card, Statistic, Typography } from 'antd';
import { WalletOutlined, RiseOutlined, FallOutlined } from '@ant-design/icons';

// =========================================================================================
// Sprint 3 - Task 3: Xây dựng Dashboard Khách hàng
// Yêu cầu: VIEW-CUS-01
//
// Logic chính:
// 1. Hiển thị một tiêu đề chào mừng người dùng, ví dụ: "Tổng quan tài khoản của bạn".
// 2. Sử dụng `Row` và `Col` để tạo một lưới hiển thị các thông tin chính.
// 3. Sử dụng component `Statistic` bên trong các `Card` để hiển thị các số liệu sau (dùng dữ liệu giả lập - hardcoded data):
//    - "Số dư hiện tại" (ví dụ: 1,500 điểm) với icon `WalletOutlined`.
//    - "Tổng điểm đã tích lũy" (ví dụ: 2,500 điểm) với icon `RiseOutlined`.
//    - "Tổng điểm đã sử dụng" (ví dụ: 1,000 điểm) với icon `FallOutlined`.
// =========================================================================================
// Gợi ý cho Copilot:
const CustomerDashboard: React.FC = () => {
    // Dữ liệu giả lập (hardcoded data)
    const accountData = {
        currentBalance: 1500,
        totalEarned: 2500,
        totalUsed: 1000,
        customerName: "Nguyễn Văn A",
        lastUpdated: "2025-01-23 14:30:00"
    };

    return (
        <div style={{ padding: '0' }}>
            {/* 1. Tiêu đề chào mừng người dùng */}
            <div style={{ marginBottom: '24px' }}>
                <Typography.Title level={2} style={{ margin: 0, color: '#1890ff' }}>
                    Tổng quan tài khoản của bạn
                </Typography.Title>
                <Typography.Text type="secondary" style={{ fontSize: '16px' }}>
                    Xin chào <strong>{accountData.customerName}</strong>, chào mừng bạn quay trở lại!
                </Typography.Text>
            </div>

            {/* 2. & 3. Lưới hiển thị các thông tin chính */}
            <Row gutter={[24, 24]}>
                {/* Số dư hiện tại */}
                <Col xs={24} sm={12} md={8}>
                    <Card
                        style={{
                            borderRadius: '12px',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                            border: '1px solid #e8f4ff',
                            background: 'linear-gradient(135deg, #e8f4ff 0%, #ffffff 100%)'
                        }}
                        bodyStyle={{ padding: '24px' }}
                    >
                        <Statistic
                            title={
                                <span style={{ 
                                    fontSize: '16px', 
                                    fontWeight: '500',
                                    color: '#595959'
                                }}>
                                    Số dư hiện tại
                                </span>
                            }
                            value={accountData.currentBalance}
                            suffix="điểm"
                            valueStyle={{ 
                                color: '#1890ff',
                                fontSize: '32px',
                                fontWeight: 'bold'
                            }}
                            prefix={<WalletOutlined style={{ marginRight: '8px' }} />}
                        />
                        <Typography.Text type="secondary" style={{ fontSize: '12px' }}>
                            Cập nhật lần cuối: {accountData.lastUpdated}
                        </Typography.Text>
                    </Card>
                </Col>

                {/* Tổng điểm đã tích lũy */}
                <Col xs={24} sm={12} md={8}>
                    <Card
                        style={{
                            borderRadius: '12px',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                            border: '1px solid #f6ffed',
                            background: 'linear-gradient(135deg, #f6ffed 0%, #ffffff 100%)'
                        }}
                        bodyStyle={{ padding: '24px' }}
                    >
                        <Statistic
                            title={
                                <span style={{ 
                                    fontSize: '16px', 
                                    fontWeight: '500',
                                    color: '#595959'
                                }}>
                                    Tổng điểm đã tích lũy
                                </span>
                            }
                            value={accountData.totalEarned}
                            suffix="điểm"
                            valueStyle={{ 
                                color: '#52c41a',
                                fontSize: '32px',
                                fontWeight: 'bold'
                            }}
                            prefix={<RiseOutlined style={{ marginRight: '8px' }} />}
                        />
                        <Typography.Text type="secondary" style={{ fontSize: '12px' }}>
                            Tích lũy từ các giao dịch
                        </Typography.Text>
                    </Card>
                </Col>

                {/* Tổng điểm đã sử dụng */}
                <Col xs={24} sm={12} md={8}>
                    <Card
                        style={{
                            borderRadius: '12px',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                            border: '1px solid #fff2e8',
                            background: 'linear-gradient(135deg, #fff2e8 0%, #ffffff 100%)'
                        }}
                        bodyStyle={{ padding: '24px' }}
                    >
                        <Statistic
                            title={
                                <span style={{ 
                                    fontSize: '16px', 
                                    fontWeight: '500',
                                    color: '#595959'
                                }}>
                                    Tổng điểm đã sử dụng
                                </span>
                            }
                            value={accountData.totalUsed}
                            suffix="điểm"
                            valueStyle={{ 
                                color: '#fa8c16',
                                fontSize: '32px',
                                fontWeight: 'bold'
                            }}
                            prefix={<FallOutlined style={{ marginRight: '8px' }} />}
                        />
                        <Typography.Text type="secondary" style={{ fontSize: '12px' }}>
                            Sử dụng cho quy đổi và chuyển khoản
                        </Typography.Text>
                    </Card>
                </Col>
            </Row>

            {/* Thông tin bổ sung */}
            <Row style={{ marginTop: '24px' }}>
                <Col span={24}>
                    <Card
                        title={
                            <Typography.Title level={4} style={{ margin: 0 }}>
                                📊 Thống kê nhanh
                            </Typography.Title>
                        }
                        style={{
                            borderRadius: '12px',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                        }}
                    >
                        <Row gutter={[16, 16]}>
                            <Col xs={24} sm={12} md={6}>
                                <div style={{ textAlign: 'center', padding: '16px' }}>
                                    <Typography.Title level={3} style={{ color: '#722ed1', margin: '0 0 8px 0' }}>
                                        {Math.round((accountData.totalUsed / accountData.totalEarned) * 100)}%
                                    </Typography.Title>
                                    <Typography.Text type="secondary">Tỷ lệ sử dụng</Typography.Text>
                                </div>
                            </Col>
                            <Col xs={24} sm={12} md={6}>
                                <div style={{ textAlign: 'center', padding: '16px' }}>
                                    <Typography.Title level={3} style={{ color: '#13c2c2', margin: '0 0 8px 0' }}>
                                        {accountData.totalEarned - accountData.totalUsed}
                                    </Typography.Title>
                                    <Typography.Text type="secondary">Điểm tiết kiệm</Typography.Text>
                                </div>
                            </Col>
                            <Col xs={24} sm={12} md={6}>
                                <div style={{ textAlign: 'center', padding: '16px' }}>
                                    <Typography.Title level={3} style={{ color: '#eb2f96', margin: '0 0 8px 0' }}>
                                        15
                                    </Typography.Title>
                                    <Typography.Text type="secondary">Giao dịch tháng này</Typography.Text>
                                </div>
                            </Col>
                            <Col xs={24} sm={12} md={6}>
                                <div style={{ textAlign: 'center', padding: '16px' }}>
                                    <Typography.Title level={3} style={{ color: '#52c41a', margin: '0 0 8px 0' }}>
                                        VIP
                                    </Typography.Title>
                                    <Typography.Text type="secondary">Hạng thành viên</Typography.Text>
                                </div>
                            </Col>
                        </Row>
                    </Card>
                </Col>
            </Row>
        </div>
    );
};

export default CustomerDashboard;