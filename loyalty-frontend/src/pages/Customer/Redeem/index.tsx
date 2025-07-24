// File: src/pages/Customer/Redeem/index.tsx

import React, { useState } from 'react';
import { Row, Col, Card, Button, Typography, Modal, message, Badge, Space, Divider } from 'antd';
import { GiftOutlined, WalletOutlined, ExclamationCircleOutlined } from '@ant-design/icons';

const { Meta } = Card;

// =========================================================================================
// Sprint 3 - Task 5: Xây dựng Trang Quy đổi Điểm thưởng
// Yêu cầu: VIEW-CUS-03 & VIEW-CUS-05
//
// Logic chính:
// 1. Hiển thị tiêu đề trang "Quy đổi Điểm thưởng".
// 2. Sử dụng dữ liệu giả lập để tạo ra một danh sách các phần quà.
// 3. Hiển thị danh sách dưới dạng lưới các `Card`, mỗi Card có ảnh, tên, điểm và nút "Quy đổi".
// 4. Khi nhấn nút "Quy đổi", hiển thị một `Modal` xác nhận.
// 5. Khi nhấn "Xác nhận" trong Modal, hiển thị `message.success`.
// =========================================================================================

interface RewardItem {
  id: string;
  name: string;
  points: number;
  imageUrl: string;
  description?: string;
  category?: string;
  stock?: number;
}

const RedeemPage: React.FC = () => {
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [selectedReward, setSelectedReward] = useState<RewardItem | null>(null);
    
    // Số dư điểm hiện tại của người dùng (giả lập)
    const currentBalance = 1500;

    // 2. Dữ liệu giả lập các phần quà có thể quy đổi
    const rewardItems: RewardItem[] = [
        {
            id: 'R001',
            name: 'Voucher Giảm giá 10%',
            points: 200,
            imageUrl: 'https://via.placeholder.com/300x200/1890ff/ffffff?text=Voucher+10%25',
            description: 'Voucher giảm giá 10% cho lần mua hàng tiếp theo',
            category: 'Voucher',
            stock: 50,
        },
        {
            id: 'R002',
            name: 'Thẻ quà tặng 100,000 VND',
            points: 500,
            imageUrl: 'https://via.placeholder.com/300x200/52c41a/ffffff?text=Gift+Card+100K',
            description: 'Thẻ quà tặng trị giá 100,000 VND sử dụng tại cửa hàng',
            category: 'Gift Card',
            stock: 25,
        },
        {
            id: 'R003',
            name: 'Túi Tote Canvas',
            points: 800,
            imageUrl: 'https://via.placeholder.com/300x200/fa8c16/ffffff?text=Tote+Bag',
            description: 'Túi tote canvas cao cấp với logo thương hiệu',
            category: 'Merchandise',
            stock: 15,
        },
        {
            id: 'R004',
            name: 'Voucher Giảm giá 20%',
            points: 400,
            imageUrl: 'https://via.placeholder.com/300x200/722ed1/ffffff?text=Voucher+20%25',
            description: 'Voucher giảm giá 20% cho đơn hàng từ 500,000 VND',
            category: 'Voucher',
            stock: 30,
        },
        {
            id: 'R005',
            name: 'Cốc giữ nhiệt Inox',
            points: 1200,
            imageUrl: 'https://via.placeholder.com/300x200/13c2c2/ffffff?text=Tumbler',
            description: 'Cốc giữ nhiệt inox 304 cao cấp dung tích 500ml',
            category: 'Merchandise',
            stock: 10,
        },
        {
            id: 'R006',
            name: 'Thẻ quà tặng 500,000 VND',
            points: 2000,
            imageUrl: 'https://via.placeholder.com/300x200/eb2f96/ffffff?text=Gift+Card+500K',
            description: 'Thẻ quà tặng trị giá 500,000 VND sử dụng toàn hệ thống',
            category: 'Gift Card',
            stock: 5,
        },
    ];

    // 4. Xử lý khi nhấn nút "Quy đổi"
    const handleRedeemClick = (reward: RewardItem) => {
        setSelectedReward(reward);
        setIsModalVisible(true);
    };

    // 5. Xử lý xác nhận quy đổi
    const handleConfirmRedeem = () => {
        if (selectedReward) {
            // Kiểm tra số dư đủ không
            if (currentBalance < selectedReward.points) {
                message.error('Số dư điểm không đủ để quy đổi phần quà này!');
                setIsModalVisible(false);
                return;
            }

            // Đóng Modal và hiển thị thông báo thành công
            setIsModalVisible(false);
            message.success(`Quy đổi ${selectedReward.name} thành công!`);
            
            // TODO: Tích hợp API thật ở các bước sau
            console.log('Redeeming reward:', selectedReward);
        }
    };

    // Xử lý hủy Modal
    const handleCancel = () => {
        setIsModalVisible(false);
        setSelectedReward(null);
    };

    // Function to get category color
    const getCategoryColor = (category?: string): string => {
        switch (category) {
            case 'Voucher':
                return '#1890ff';
            case 'Gift Card':
                return '#52c41a';
            case 'Merchandise':
                return '#fa8c16';
            default:
                return '#722ed1';
        }
    };

    return (
        <div style={{ padding: '0' }}>
            {/* 1. Tiêu đề trang */}
            <div style={{ marginBottom: '24px' }}>
                <Typography.Title level={2} style={{ margin: 0, color: '#1890ff' }}>
                    <GiftOutlined style={{ marginRight: '12px' }} />
                    Quy đổi Điểm thưởng
                </Typography.Title>
                <Typography.Text type="secondary" style={{ fontSize: '16px' }}>
                    Chọn phần quà yêu thích và quy đổi bằng điểm loyalty của bạn
                </Typography.Text>
            </div>

            {/* Hiển thị số dư hiện tại */}
            <Card 
                style={{ 
                    marginBottom: '24px', 
                    borderRadius: '12px',
                    background: 'linear-gradient(135deg, #e8f4ff 0%, #ffffff 100%)',
                    border: '1px solid #d6e4ff'
                }}
            >
                <Space size="large" style={{ width: '100%', justifyContent: 'center' }}>
                    <div style={{ textAlign: 'center' }}>
                        <WalletOutlined style={{ fontSize: '24px', color: '#1890ff', marginBottom: '8px' }} />
                        <Typography.Title level={3} style={{ margin: 0, color: '#1890ff' }}>
                            {currentBalance.toLocaleString()} điểm
                        </Typography.Title>
                        <Typography.Text type="secondary">Số dư hiện tại</Typography.Text>
                    </div>
                </Space>
            </Card>

            {/* 3. Lưới các Card hiển thị phần quà */}
            <Row gutter={[24, 24]}>
                {rewardItems.map((reward) => {
                    const canAfford = currentBalance >= reward.points;
                    const isOutOfStock = reward.stock === 0;
                    
                    return (
                        <Col key={reward.id} xs={24} sm={12} md={8} lg={6}>
                            <Badge.Ribbon 
                                text={reward.category} 
                                color={getCategoryColor(reward.category)}
                            >
                                <Card
                                    hoverable={canAfford && !isOutOfStock}
                                    cover={
                                        <div style={{ position: 'relative' }}>
                                            <img
                                                alt={reward.name}
                                                src={reward.imageUrl}
                                                style={{ 
                                                    height: 200, 
                                                    objectFit: 'cover',
                                                    filter: (!canAfford || isOutOfStock) ? 'grayscale(50%)' : 'none'
                                                }}
                                            />
                                            {!canAfford && (
                                                <div style={{
                                                    position: 'absolute',
                                                    top: '50%',
                                                    left: '50%',
                                                    transform: 'translate(-50%, -50%)',
                                                    background: 'rgba(0,0,0,0.7)',
                                                    color: 'white',
                                                    padding: '4px 8px',
                                                    borderRadius: '4px',
                                                    fontSize: '12px'
                                                }}>
                                                    Không đủ điểm
                                                </div>
                                            )}
                                            {isOutOfStock && (
                                                <div style={{
                                                    position: 'absolute',
                                                    top: '10px',
                                                    right: '10px',
                                                    background: '#ff4d4f',
                                                    color: 'white',
                                                    padding: '4px 8px',
                                                    borderRadius: '4px',
                                                    fontSize: '12px'
                                                }}>
                                                    Hết hàng
                                                </div>
                                            )}
                                        </div>
                                    }
                                    style={{
                                        borderRadius: '12px',
                                        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                                        opacity: (!canAfford || isOutOfStock) ? 0.6 : 1
                                    }}
                                    actions={[
                                        <Button
                                            key="redeem"
                                            type="primary"
                                            block
                                            disabled={!canAfford || isOutOfStock}
                                            onClick={() => handleRedeemClick(reward)}
                                            style={{
                                                margin: '0 16px',
                                                borderRadius: '6px',
                                                height: '40px',
                                                fontSize: '14px',
                                                fontWeight: '500'
                                            }}
                                        >
                                            {isOutOfStock ? 'Hết hàng' : 'Quy đổi'}
                                        </Button>
                                    ]}
                                >
                                    <Meta
                                        title={
                                            <Typography.Title level={5} style={{ margin: 0 }}>
                                                {reward.name}
                                            </Typography.Title>
                                        }
                                        description={
                                            <div>
                                                <Typography.Text type="secondary" style={{ fontSize: '13px' }}>
                                                    {reward.description}
                                                </Typography.Text>
                                                <Divider style={{ margin: '12px 0' }} />
                                                <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                                                    <Typography.Text strong style={{ color: '#fa8c16', fontSize: '16px' }}>
                                                        {reward.points.toLocaleString()} điểm
                                                    </Typography.Text>
                                                    <Typography.Text type="secondary" style={{ fontSize: '12px' }}>
                                                        Còn: {reward.stock}
                                                    </Typography.Text>
                                                </Space>
                                            </div>
                                        }
                                    />
                                </Card>
                            </Badge.Ribbon>
                        </Col>
                    );
                })}
            </Row>

            {/* 4. Modal xác nhận quy đổi */}
            <Modal
                title={
                    <Space>
                        <ExclamationCircleOutlined style={{ color: '#faad14' }} />
                        <span>Xác nhận quy đổi</span>
                    </Space>
                }
                open={isModalVisible}
                onOk={handleConfirmRedeem}
                onCancel={handleCancel}
                okText="Xác nhận"
                cancelText="Hủy"
                okType="primary"
                centered
                width={500}
            >
                {selectedReward && (
                    <div style={{ padding: '16px 0' }}>
                        <Typography.Text style={{ fontSize: '16px' }}>
                            Bạn có chắc chắn muốn quy đổi phần quà này không?
                        </Typography.Text>
                        
                        <div style={{ 
                            background: '#f8f9fa', 
                            padding: '16px', 
                            borderRadius: '8px', 
                            margin: '16px 0',
                            border: '1px solid #e9ecef'
                        }}>
                            <Typography.Title level={5} style={{ margin: '0 0 8px 0' }}>
                                {selectedReward.name}
                            </Typography.Title>
                            <Typography.Text type="secondary">
                                {selectedReward.description}
                            </Typography.Text>
                            <Divider style={{ margin: '12px 0' }} />
                            <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                                <Typography.Text>
                                    <strong>Số điểm cần:</strong> {selectedReward.points.toLocaleString()} điểm
                                </Typography.Text>
                                <Typography.Text>
                                    <strong>Số dư sau quy đổi:</strong> {(currentBalance - selectedReward.points).toLocaleString()} điểm
                                </Typography.Text>
                            </Space>
                        </div>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default RedeemPage;