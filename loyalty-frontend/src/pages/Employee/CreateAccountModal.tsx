// File: src/pages/Employee/CreateAccountModal.tsx

import React from 'react';
import { Modal, Form, Input, message } from 'antd';

interface CreateAccountModalProps {
  open: boolean;
  onCancel: () => void;
  onSubmit: (values: { customerId: string }) => void;
}

const CreateAccountModal: React.FC<CreateAccountModalProps> = ({ open, onCancel, onSubmit }) => {
    const [form] = Form.useForm();

    const handleOk = () => {
        form.validateFields()
            .then((values) => {
                onSubmit(values);
                form.resetFields();
                message.success('Tạo tài khoản Loyalty thành công!');
            })
            .catch((errorInfo) => {
                console.log('Validation failed:', errorInfo);
            });
    };

    const handleCancel = () => {
        form.resetFields();
        onCancel();
    };

    return (
        <Modal
            title="Tạo tài khoản Loyalty mới"
            open={open}
            onOk={handleOk}
            onCancel={handleCancel}
            okText="Tạo tài khoản"
            cancelText="Hủy"
            width={400}
            destroyOnClose
        >
            <Form
                form={form}
                layout="vertical"
                autoComplete="off"
            >
                <Form.Item
                    label="Customer ID"
                    name="customerId"
                    rules={[
                        {
                            required: true,
                            message: 'Vui lòng nhập Customer ID!'
                        },
                        {
                            min: 3,
                            message: 'Customer ID phải có ít nhất 3 ký tự!'
                        },
                        {
                            pattern: /^[A-Za-z0-9]+$/,
                            message: 'Customer ID chỉ được chứa chữ cái và số!'
                        }
                    ]}
                >
                    <Input 
                        placeholder="Nhập Customer ID (ví dụ: CUST001)"
                        size="large"
                    />
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default CreateAccountModal;