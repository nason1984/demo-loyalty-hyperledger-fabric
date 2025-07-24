// File: src/pages/LoginPage/index.tsx

import React from 'react';
import { Card, Form, Input, Button, Typography, Row, Col } from 'antd';
import { useNavigate } from 'react-router-dom'; // Thêm useNavigate để điều hướng

// =========================================================================================
// PROMPT ĐÃ ĐƯỢC CẬP NHẬT
// Nhiệm vụ:
// 1. Nhận một prop là `onLoginSuccess` (một hàm callback).
// 2. Khi form được submit thành công (trong hàm `onFinish`), gọi hàm `onLoginSuccess` này.
// =========================================================================================
const LoginPage: React.FC<{ onLoginSuccess: () => void }> = ({ onLoginSuccess }) => { // <-- THAY ĐỔI Ở ĐÂY: Nhận prop
    
    const navigate = useNavigate();

    // Handle form submission
    const onFinish = (values: any) => {
        console.log('Login form data:', values);
        // TODO: Tích hợp API đăng nhập thật ở đây

        // THAY ĐỔI Ở ĐÂY: Gọi hàm callback để thông báo cho App.tsx biết đăng nhập thành công
        onLoginSuccess(); 

        // Điều hướng đến trang dashboard sau khi đăng nhập thành công
        navigate('/dashboard');
    };

    const onFinishFailed = (errorInfo: any) => {
        console.log('Login failed:', errorInfo);
    };

    return (
        <div style={{
            minHeight: '100vh',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        }}>
            <Row justify="center" align="middle" style={{ width: '100%' }}>
                <Col xs={22} sm={16} md={12} lg={8} xl={6}>
                    <Card
                        title={
                            <Typography.Title level={3} style={{ textAlign: 'center', margin: 0, color: '#1890ff' }}>
                                Đăng nhập
                            </Typography.Title>
                        }
                        style={{ boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)', borderRadius: '8px' }}
                    >
                        <Form
                            name="loginForm"
                            layout="vertical"
                            onFinish={onFinish}
                            onFinishFailed={onFinishFailed}
                            autoComplete="off"
                            size="large"
                        >
                            <Form.Item
                                label="Tên đăng nhập"
                                name="username"
                                rules={[{ required: true, message: 'Vui lòng nhập tên đăng nhập!' }]}
                            >

                                <Input placeholder="Nhập tên đăng nhập" />
                            </Form.Item>

                            <Form.Item
                                label="Mật khẩu"
                                name="password"
                                rules={[{ required: true, message: 'Vui lòng nhập mật khẩu!' }]}
                            >
                                <Input.Password placeholder="Nhập mật khẩu" />
                            </Form.Item>

                            <Form.Item style={{ marginBottom: 0, marginTop: '24px' }}>
                                <Button type="primary" htmlType="submit" block style={{ height: '44px' }}>
                                    Đăng nhập
                                </Button>
                            </Form.Item>
                        </Form>
                    </Card>
                </Col>
            </Row>
        </div>
    );
};

export default LoginPage;