import React from 'react';
import { Card, Form, Input, Button, Typography, message } from 'antd';
import { useNavigate } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import { loginSuccess } from '../../redux/slices/authSlice';
import axiosClient from '../../api/axiosClient';

const LoginPage: React.FC = () => {
    const navigate = useNavigate();
    const dispatch = useDispatch();
    const [loading, setLoading] = React.useState(false);

    const onFinish = async (values: any) => {
        console.log('Login form submitted with values:', values);
        setLoading(true);
        try {
            console.log('Sending login request to backend...');
            const response = await axiosClient.post('/login', {
                username: values.username,
                password: values.password,
            });
            console.log('Login response received:', response);
            
            // Safely extract token from response
            let token = null;
            if (response && response.data && response.data.data && response.data.data.token) {
                token = response.data.data.token;
            } else if (response && response.data && response.data.token) {
                token = response.data.token;
            }
            
            console.log('Extracted token:', token);
            
            if (!token) {
                throw new Error('Token not found in response');
            }
            
            // Dispatch action để cập nhật Redux state
            dispatch(loginSuccess(token));
            console.log('Redux loginSuccess dispatched');
            
            message.success('Đăng nhập thành công!');

            // Navigate to home page (role-based routing will handle from there)
            console.log('Navigating to home page...');
            navigate('/');

        } catch (error: any) {
            console.error('Login error:', error);
            
            // Log full error object for debugging
            console.log('Full error object:', {
                error,
                response: error.response,
                data: error.response?.data,
                status: error.response?.status
            });
            
            // Extract error message with proper field name (Error vs error)
            let errorMessage = 'Đăng nhập thất bại!';
            if (error.response?.data?.Error) {
                errorMessage = error.response.data.Error;
            } else if (error.response?.data?.error) {
                errorMessage = error.response.data.error;
            } else if (error.response?.data?.message) {
                errorMessage = error.response.data.message;
            } else if (error.message) {
                errorMessage = error.message;
            }
            
            message.error(errorMessage);
        } finally {
            setLoading(false);
            console.log('Login process completed');
        }
    };

    return (
        <div style={{ minHeight: '100vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <Card title={<Typography.Title level={3} style={{ textAlign: 'center' }}>Đăng nhập</Typography.Title>} style={{ width: 400 }}>
                <Form name="login" onFinish={onFinish} layout="vertical">
                    <Form.Item label="Tên đăng nhập" name="username" rules={[{ required: true, message: 'Vui lòng nhập tên đăng nhập!' }]} initialValue="admin">
                        <Input />
                    </Form.Item>
                    <Form.Item label="Mật khẩu" name="password" rules={[{ required: true, message: 'Vui lòng nhập mật khẩu!' }]} initialValue="123456">
                        <Input.Password />
                    </Form.Item>
                    <Form.Item>
                        <Button type="primary" htmlType="submit" block loading={loading}>Đăng nhập</Button>
                    </Form.Item>
                </Form>
            </Card>
        </div>
    );
};

export default LoginPage;