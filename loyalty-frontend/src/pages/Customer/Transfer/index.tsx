// File: src/pages/Customer/Transfer/index.tsx

import React, { useState } from 'react';
import { Card, Form, Input, Button, Typography, Modal, message, InputNumber, Space, Divider, Row, Col } from 'antd';
import { SwapOutlined, UserOutlined, ExclamationCircleOutlined, WalletOutlined, SendOutlined } from '@ant-design/icons';

interface TransferFormData {
    targetCustomerId: string;
    amount: number;
    description: string;
}

const TransferPage: React.FC = () => {
    const [form] = Form.useForm();
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [transferData, setTransferData] = useState<TransferFormData | null>(null);
    
    // Số dư điểm hiện tại của người dùng (giả lập)
    const currentBalance = 1500;
    const currentUserId = "CUST001"; // ID người gửi (giả lập)

    // 4. Xử lý khi submit form
    const onFinish = (values: TransferFormData) => {
        console.log('Transfer form data:', values);
        
        // Kiểm tra không thể chuyển cho chính mình
        if (values.targetCustomerId === currentUserId) {
            message.error('Không thể chuyển điểm cho chính mình!');
            return;
        }

        // Kiểm tra số dư đủ không
        if (values.amount > currentBalance) {
            message.error('Số dư điểm không đủ để thực hiện giao dịch!');
            return;
        }

        // Lưu dữ liệu và hiển thị Modal xác nhận
        setTransferData(values);
        setIsModalVisible(true);
    };

    const onFinishFailed = (errorInfo: any) => {
        console.log('Form validation failed:', errorInfo);
        message.error('Vui lòng kiểm tra lại thông tin đã nhập!');
    };

    // 5. Xử lý xác nhận chuyển điểm
    const handleConfirmTransfer = () => {
        if (transferData) {
            // Đóng Modal và hiển thị thông báo thành công
            setIsModalVisible(false);
            message.success(
                `Chuyển ${transferData.amount.toLocaleString()} điểm đến ${transferData.targetCustomerId} thành công!`
            );
            
            // Reset form sau khi chuyển thành công
            form.resetFields();
            setTransferData(null);
            
            // TODO: Tích hợp API thật ở các bước sau
            console.log('Transfer completed:', transferData);
        }
    };

    // Xử lý hủy Modal
    const handleCancel = () => {
        setIsModalVisible(false);
        setTransferData(null);
    };

    return (
        <div style={{ padding: '0' }}>
            {/* 1. Tiêu đề chính cho trang */}
            <div style={{ marginBottom: '24px' }}>
                <Typography.Title level={2} style={{ margin: 0, color: '#1890ff' }}>
                    <SwapOutlined style={{ marginRight: '12px' }} />
                    Chuyển điểm Loyalty
                </Typography.Title>
                <Typography.Text type="secondary" style={{ fontSize: '16px' }}>
                    Chuyển điểm loyalty cho bạn bè và người thân một cách dễ dàng
                </Typography.Text>
            </div>

            <Row gutter={[24, 24]}>
                {/* Hiển thị số dư hiện tại */}
                <Col xs={24} lg={8}>
                    <Card 
                        style={{ 
                            borderRadius: '12px',
                            background: 'linear-gradient(135deg, #e8f4ff 0%, #ffffff 100%)',
                            border: '1px solid #d6e4ff',
                            height: 'fit-content'
                        }}
                    >
                        <div style={{ textAlign: 'center', padding: '16px 0' }}>
                            <WalletOutlined style={{ fontSize: '32px', color: '#1890ff', marginBottom: '16px' }} />
                            <Typography.Title level={3} style={{ margin: '0 0 8px 0', color: '#1890ff' }}>
                                {currentBalance.toLocaleString()} điểm
                            </Typography.Title>
                            <Typography.Text type="secondary">Số dư hiện tại</Typography.Text>
                            <Divider style={{ margin: '16px 0' }} />
                            <Typography.Text type="secondary" style={{ fontSize: '12px' }}>
                                ID của bạn: <strong>{currentUserId}</strong>
                            </Typography.Text>
                        </div>
                    </Card>

                    {/* Thông tin hướng dẫn */}
                    <Card 
                        title="📋 Hướng dẫn chuyển điểm"
                        style={{ 
                            marginTop: '16px',
                            borderRadius: '12px'
                        }}
                        size="small"
                    >
                        <ul style={{ paddingLeft: '16px', margin: 0 }}>
                            <li style={{ marginBottom: '8px' }}>
                                <Typography.Text type="secondary" style={{ fontSize: '13px' }}>
                                    Nhập chính xác ID người nhận
                                </Typography.Text>
                            </li>
                            <li style={{ marginBottom: '8px' }}>
                                <Typography.Text type="secondary" style={{ fontSize: '13px' }}>
                                    Số điểm chuyển tối thiểu: 1 điểm
                                </Typography.Text>
                            </li>
                            <li style={{ marginBottom: '8px' }}>
                                <Typography.Text type="secondary" style={{ fontSize: '13px' }}>
                                    Không thể chuyển cho chính mình
                                </Typography.Text>
                            </li>
                            <li>
                                <Typography.Text type="secondary" style={{ fontSize: '13px' }}>
                                    Giao dịch không thể hoàn tác
                                </Typography.Text>
                            </li>
                        </ul>
                    </Card>
                </Col>

                {/* 2. Form chuyển điểm */}
                <Col xs={24} lg={16}>
                    <Card 
                        title={
                            <Space>
                                <SendOutlined />
                                <span>Thông tin chuyển điểm</span>
                            </Space>
                        }
                        style={{ 
                            borderRadius: '12px',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
                        }}
                    >
                        <Form
                            form={form}
                            name="transferForm"
                            layout="vertical"
                            onFinish={onFinish}
                            onFinishFailed={onFinishFailed}
                            autoComplete="off"
                            size="large"
                        >
                            {/* 3. ID người nhận */}
                            <Form.Item
                                label="ID người nhận"
                                name="targetCustomerId"
                                rules={[
                                    {
                                        required: true,
                                        message: 'Vui lòng nhập ID người nhận!'
                                    },
                                    {
                                        min: 3,
                                        message: 'ID người nhận phải có ít nhất 3 ký tự!'
                                    },
                                    {
                                        validator: (_, value) => {
                                            if (value && value === currentUserId) {
                                                return Promise.reject(new Error('Không thể chuyển điểm cho chính mình!'));
                                            }
                                            return Promise.resolve();
                                        }
                                    }
                                ]}
                            >
                                <Input 
                                    prefix={<UserOutlined />}
                                    placeholder="Nhập ID người nhận (VD: CUST002)"
                                    style={{ borderRadius: '6px' }}
                                />
                            </Form.Item>

                            {/* 3. Số điểm cần chuyển */}
                            <Form.Item
                                label="Số điểm cần chuyển"
                                name="amount"
                                rules={[
                                    {
                                        required: true,
                                        message: 'Vui lòng nhập số điểm cần chuyển!'
                                    },
                                    {
                                        type: 'number',
                                        min: 1,
                                        message: 'Số điểm phải lớn hơn 0!'
                                    },
                                    {
                                        type: 'number',
                                        max: currentBalance,
                                        message: `Số điểm không được vượt quá ${currentBalance.toLocaleString()}!`
                                    }
                                ]}
                            >
                                <InputNumber
                                    style={{ width: '100%', borderRadius: '6px' }}
                                    placeholder="Nhập số điểm cần chuyển"
                                    formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                                    parser={value => value!.replace(/\$\s?|(,*)/g, '')}
                                    addonAfter="điểm"
                                />
                            </Form.Item>

                            {/* 3. Lời nhắn */}
                            <Form.Item
                                label="Lời nhắn"
                                name="description"
                                rules={[
                                    {
                                        required: true,
                                        message: 'Vui lòng nhập lời nhắn!'
                                    },
                                    {
                                        min: 5,
                                        message: 'Lời nhắn phải có ít nhất 5 ký tự!'
                                    },
                                    {
                                        max: 200,
                                        message: 'Lời nhắn không được vượt quá 200 ký tự!'
                                    }
                                ]}
                            >
                                <Input.TextArea
                                    rows={4}
                                    placeholder="Nhập lời nhắn kèm theo (VD: Chúc mừng sinh nhật!)"
                                    style={{ borderRadius: '6px' }}
                                    showCount
                                    maxLength={200}
                                />
                            </Form.Item>

                            {/* Submit button */}
                            <Form.Item style={{ marginBottom: 0, marginTop: '32px' }}>
                                <Button
                                    type="primary"
                                    htmlType="submit"
                                    block
                                    size="large"
                                    style={{
                                        height: '48px',
                                        borderRadius: '6px',
                                        fontSize: '16px',
                                        fontWeight: '500'
                                    }}
                                    icon={<SwapOutlined />}
                                >
                                    Chuyển điểm ngay
                                </Button>
                            </Form.Item>
                        </Form>
                    </Card>
                </Col>
            </Row>

            {/* 4. Modal xác nhận chuyển điểm */}
            <Modal
                title={
                    <Space>
                        <ExclamationCircleOutlined style={{ color: '#faad14' }} />
                        <span>Xác nhận chuyển điểm</span>
                    </Space>
                }
                open={isModalVisible}
                onOk={handleConfirmTransfer}
                onCancel={handleCancel}
                okText="Xác nhận chuyển"
                cancelText="Hủy"
                okType="primary"
                centered
                width={550}
            >
                {transferData && (
                    <div style={{ padding: '16px 0' }}>
                        <Typography.Text style={{ fontSize: '16px', marginBottom: '16px', display: 'block' }}>
                            Bạn có chắc chắn muốn thực hiện giao dịch chuyển điểm này không?
                        </Typography.Text>
                        
                        <div style={{ 
                            background: '#f8f9fa', 
                            padding: '20px', 
                            borderRadius: '8px', 
                            margin: '16px 0',
                            border: '1px solid #e9ecef'
                        }}>
                            <Row gutter={[16, 12]}>
                                <Col span={8}>
                                    <Typography.Text strong>Từ:</Typography.Text>
                                </Col>
                                <Col span={16}>
                                    <Typography.Text>{currentUserId}</Typography.Text>
                                </Col>
                                
                                <Col span={8}>
                                    <Typography.Text strong>Đến:</Typography.Text>
                                </Col>
                                <Col span={16}>
                                    <Typography.Text style={{ color: '#1890ff' }}>
                                        {transferData.targetCustomerId}
                                    </Typography.Text>
                                </Col>
                                
                                <Col span={8}>
                                    <Typography.Text strong>Số điểm:</Typography.Text>
                                </Col>
                                <Col span={16}>
                                    <Typography.Text style={{ color: '#fa8c16', fontSize: '16px', fontWeight: 'bold' }}>
                                        {transferData.amount.toLocaleString()} điểm
                                    </Typography.Text>
                                </Col>
                                
                                <Col span={8}>
                                    <Typography.Text strong>Lời nhắn:</Typography.Text>
                                </Col>
                                <Col span={16}>
                                    <Typography.Text italic>"{transferData.description}"</Typography.Text>
                                </Col>
                            </Row>
                            
                            <Divider style={{ margin: '16px 0' }} />
                            
                            <Row gutter={[16, 8]}>
                                <Col span={12}>
                                    <Typography.Text type="secondary">
                                        Số dư hiện tại: {currentBalance.toLocaleString()} điểm
                                    </Typography.Text>
                                </Col>
                                <Col span={12}>
                                    <Typography.Text type="secondary">
                                        Số dư sau giao dịch: {(currentBalance - transferData.amount).toLocaleString()} điểm
                                    </Typography.Text>
                                </Col>
                            </Row>
                        </div>
                        
                        <Typography.Text type="warning" style={{ fontSize: '13px' }}>
                            ⚠️ Lưu ý: Giao dịch chuyển điểm không thể hoàn tác sau khi xác nhận.
                        </Typography.Text>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default TransferPage;