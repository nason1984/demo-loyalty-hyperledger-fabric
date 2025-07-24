// File: src/pages/Employee/Dashboard/index.tsx

import React, { useState } from 'react';
import { 
    Card, 
    Input, 
    Button, 
    Typography, 
    Row, 
    Col, 
    Avatar,
    Statistic,
    Divider,
    message,
    Space,
    Tag,
    Badge
} from 'antd';
import { 
    SearchOutlined, 
    UserOutlined, 
    PlusOutlined, 
    SendOutlined, 
    UserAddOutlined,
    HistoryOutlined,
    WalletOutlined,
    CrownOutlined,
    CalendarOutlined,
    TeamOutlined
} from '@ant-design/icons';
import CreateAccountModal from '../CreateAccountModal';
import IssuePointsModal from '../IssuePointsModal';


interface CustomerInfo {
    id: string;
    name: string;
    avatarUrl?: string;
    balance: number;
    memberSince: string;
    totalEarned?: number;
    totalSpent?: number;
    memberLevel?: string;
    lastActivity?: string;
}

const EmployeeDashboard: React.FC = () => {
    const [customerInfo, setCustomerInfo] = useState<CustomerInfo | null>(null);
    const [searchValue, setSearchValue] = useState<string>('');
    const [isSearching, setIsSearching] = useState<boolean>(false);
    const [isCreateModalVisible, setIsCreateModalVisible] = useState<boolean>(false);
    const [isIssueModalVisible, setIsIssueModalVisible] = useState<boolean>(false);

    // =============================================================
    // ĐỊNH NGHĨA HÀM clearSearch NẰM Ở ĐÂY
    // =============================================================
    const clearSearch = () => {
        setCustomerInfo(null);
        setSearchValue('');
    };

    const handleSearch = (value: string) => {
        if (!value.trim()) {
            message.warning('Vui lòng nhập ID hoặc tên khách hàng để tìm kiếm!');
            return;
        }
        setIsSearching(true);
        setSearchValue(value);
        setTimeout(() => {
            const foundCustomer: CustomerInfo = {
                id: 'CUST001', name: 'Nguyễn Văn A', avatarUrl: 'https://via.placeholder.com/80/1890ff/ffffff?text=A',
                balance: 1500, memberSince: '2022-01-15', totalEarned: 3200, totalSpent: 1700,
                memberLevel: 'VIP', lastActivity: '2025-01-20 14:30:00'
            };
            setCustomerInfo(foundCustomer);
            setIsSearching(false);
            message.success(`Tìm thấy khách hàng: ${foundCustomer.name}`);
        }, 1000);
    };

    const handleAction = (action: string) => {
        if (action === 'Tạo tài khoản Loyalty mới') {
            setIsCreateModalVisible(true);
        } else if (action === 'Phát hành điểm') {
            if (customerInfo) {
                setIsIssueModalVisible(true);
            } else {
                message.warning('Vui lòng tìm kiếm một khách hàng trước!');
            }
        } else {
            message.info(`Chức năng "${action}" đang được phát triển`);
        }
    };
    
    const handleCreateAccountSubmit = (values: { customerId: string }) => {
        console.log('Creating new account for:', values.customerId);
        message.success(`Yêu cầu tạo tài khoản cho khách hàng ${values.customerId} đã được gửi!`);
        setIsCreateModalVisible(false);
    };

    const handleIssuePointsSubmit = (values: { amount: number; description: string }) => {
        if (customerInfo) {
            console.log(`Issuing ${values.amount} points to ${customerInfo.id}: ${values.description}`);
            message.success(`Phát hành ${values.amount} điểm cho khách hàng ${customerInfo.name} thành công!`);
            setIsIssueModalVisible(false);
        }
    };

    return (
        <div style={{ padding: '0' }}>
            <div style={{ marginBottom: '32px' }}>
                <Typography.Title level={2} style={{ margin: 0, color: '#1890ff' }}>
                    <TeamOutlined style={{ marginRight: '12px' }} />
                    Bảng điều khiển dành cho Nhân viên
                </Typography.Title>
                <Typography.Text type="secondary" style={{ fontSize: '16px' }}>
                    Quản lý tài khoản loyalty và hỗ trợ khách hàng một cách hiệu quả
                </Typography.Text>
            </div>

            <Row gutter={[24, 24]}>
                <Col xs={24} lg={8}>
                    <Card title={<Space><SearchOutlined /><span>Tìm kiếm Khách hàng</span></Space>} style={{ marginBottom: '24px', borderRadius: '12px' }}>
                        <Input.Search
                            placeholder="Nhập ID hoặc tên khách hàng..."
                            enterButton="Tìm kiếm"
                            size="large"
                            value={searchValue}
                            onChange={(e) => setSearchValue(e.target.value)}
                            onSearch={handleSearch}
                            loading={isSearching}
                            style={{ marginBottom: '16px' }}
                        />
                        
                        {/* ============================================================= */}
                        {/* HÀM clearSearch ĐƯỢC GỌI Ở ĐÂY */}
                        {/* ============================================================= */}
                        {customerInfo && (
                            <Button type="link" onClick={clearSearch} style={{ padding: 0 }}>
                                Xóa kết quả tìm kiếm
                            </Button>
                        )}
                    </Card>

                    <Card title="Hành động nhanh" style={{ borderRadius: '12px' }}>
                        <Button
                            type="primary" icon={<UserAddOutlined />}
                            onClick={() => handleAction('Tạo tài khoản Loyalty mới')}
                            size="large" block
                            style={{ height: '48px', borderRadius: '6px', fontSize: '16px', fontWeight: '500', marginBottom: '12px' }}
                        >
                            Tạo tài khoản Loyalty mới
                        </Button>
                        <Typography.Text type="secondary" style={{ fontSize: '12px' }}>
                            Tạo tài khoản loyalty cho khách hàng mới
                        </Typography.Text>
                    </Card>
                </Col>

                <Col xs={24} lg={16}>
                    {customerInfo ? (
                        <Card title={<Space><UserOutlined /><span>Thông tin Khách hàng</span><Tag color="gold">{customerInfo.memberLevel}</Tag></Space>} style={{ borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
                            <Row gutter={[24, 16]} style={{ marginBottom: '24px' }}>
                                <Col xs={24} sm={6} style={{ textAlign: 'center' }}>
                                    <Badge.Ribbon text={customerInfo.memberLevel} color="gold">
                                        <Avatar src={customerInfo.avatarUrl} size={80} icon={<UserOutlined />} />
                                    </Badge.Ribbon>
                                </Col>
                                <Col xs={24} sm={18}>
                                    <Typography.Title level={3} style={{ margin: '0 0 8px 0' }}>{customerInfo.name}</Typography.Title>
                                    <Space direction="vertical" size="small">
                                        <Typography.Text><strong>ID:</strong> {customerInfo.id}</Typography.Text>
                                        <Typography.Text><CalendarOutlined style={{ marginRight: '4px' }} /><strong>Tham gia từ:</strong> {customerInfo.memberSince}</Typography.Text>
                                        <Typography.Text type="secondary"><strong>Hoạt động cuối:</strong> {customerInfo.lastActivity}</Typography.Text>
                                    </Space>
                                </Col>
                            </Row>
                            <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
                                <Col xs={24} sm={8}>
                                    <Card size="small" style={{ textAlign: 'center', background: '#e8f4ff' }}>
                                        <Statistic title="Số dư hiện tại" value={customerInfo.balance} suffix="điểm" valueStyle={{ color: '#1890ff', fontSize: '20px' }} prefix={<WalletOutlined />} />
                                    </Card>
                                </Col>
                                <Col xs={24} sm={8}>
                                    <Card size="small" style={{ textAlign: 'center', background: '#f6ffed' }}>
                                        <Statistic title="Tổng tích lũy" value={customerInfo.totalEarned} suffix="điểm" valueStyle={{ color: '#52c41a', fontSize: '20px' }} prefix={<CrownOutlined />} />
                                    </Card>
                                </Col>
                                <Col xs={24} sm={8}>
                                    <Card size="small" style={{ textAlign: 'center', background: '#fff2e8' }}>
                                        <Statistic title="Đã sử dụng" value={customerInfo.totalSpent} suffix="điểm" valueStyle={{ color: '#fa8c16', fontSize: '20px' }} prefix={<HistoryOutlined />} />
                                    </Card>
                                </Col>
                            </Row>
                            <Divider />
                            <Row gutter={[16, 16]}>
                                <Col xs={24} sm={12}>
                                    <Button type="primary" icon={<SendOutlined />} onClick={() => handleAction('Phát hành điểm')} size="large" block style={{ height: '44px', borderRadius: '6px', fontSize: '15px' }}>
                                        Phát hành điểm
                                    </Button>
                                </Col>
                                <Col xs={24} sm={12}>
                                    <Button type="default" icon={<HistoryOutlined />} onClick={() => handleAction('Xem lịch sử')} size="large" block style={{ height: '44px', borderRadius: '6px', fontSize: '15px' }}>
                                        Xem lịch sử
                                    </Button>
                                </Col>
                            </Row>
                        </Card>
                    ) : (
                        <Card style={{ borderRadius: '12px', textAlign: 'center', padding: '40px 20px' }}>
                            <div style={{ color: '#bfbfbf' }}>
                                <SearchOutlined style={{ fontSize: '48px', marginBottom: '16px' }} />
                                <Typography.Title level={4} type="secondary">Tìm kiếm khách hàng</Typography.Title>
                                <Typography.Text type="secondary">
                                    Nhập ID hoặc tên khách hàng vào ô tìm kiếm để xem thông tin chi tiết và thực hiện các thao tác quản lý.
                                </Typography.Text>
                            </div>
                        </Card>
                    )}
                </Col>
            </Row>

            {/* Render Modals */}
            <CreateAccountModal
                open={isCreateModalVisible}
                onCancel={() => setIsCreateModalVisible(false)}
                onSubmit={handleCreateAccountSubmit}
            />
            <IssuePointsModal
                open={isIssueModalVisible}
                onCancel={() => setIsIssueModalVisible(false)}
                onSubmit={handleIssuePointsSubmit}
                customerInfo={customerInfo}
            />
        </div>
    );
};

export default EmployeeDashboard;