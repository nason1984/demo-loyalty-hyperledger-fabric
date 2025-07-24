// File: src/pages/Employee/IssuePointsModal.tsx

import React, { useEffect } from 'react';
import { Modal, Form, Input, InputNumber, message, Typography } from 'antd';


interface CustomerInfo {
  id: string;
  name: string;
}

interface IssuePointsModalProps {
  open: boolean;
  onCancel: () => void;
  onSubmit: (values: { amount: number; description: string }) => void;
  customerInfo: CustomerInfo | null;
}

const IssuePointsModal: React.FC<IssuePointsModalProps> = ({ open, onCancel, onSubmit, customerInfo }) => {
    const [form] = Form.useForm();

    useEffect(() => {
        if (!open) {
            form.resetFields();
        }
    }, [open, form]);

    const handleOk = () => {
        form.validateFields()
            .then((values) => {
                onSubmit(values);
                form.resetFields();
                message.success(`Đã phát hành ${values.amount} điểm cho khách hàng ${customerInfo?.name}!`);
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
            title="Phát hành điểm cho khách hàng"
            open={open}
            onOk={handleOk}
            onCancel={handleCancel}
            okText="Phát hành điểm"
            cancelText="Hủy"
            width={500}
            destroyOnClose
        >
            {/* Hiển thị thông tin khách hàng */}
            {customerInfo && (
                <div style={{ 
                    backgroundColor: '#f5f5f5', 
                    padding: '16px', 
                    borderRadius: '8px', 
                    marginBottom: '24px' 
                }}>
                    <Typography.Title level={5} style={{ margin: '0 0 8px 0' }}>
                        Thông tin khách hàng:
                    </Typography.Title>
                    <Typography.Text strong>ID: </Typography.Text>
                    <Typography.Text>{customerInfo.id}</Typography.Text>
                    <br />
                    <Typography.Text strong>Tên: </Typography.Text>
                    <Typography.Text>{customerInfo.name}</Typography.Text>
                </div>
            )}

            <Form
                form={form}
                layout="vertical"
                autoComplete="off"
            >
                <Form.Item
                    label="Số điểm cần phát hành"
                    name="amount"
                    rules={[
                        {
                            required: true,
                            message: 'Vui lòng nhập số điểm cần phát hành!'
                        },
                        {
                            type: 'number',
                            min: 1,
                            message: 'Số điểm phải lớn hơn 0!'
                        },
                        {
                            type: 'number',
                            max: 10000,
                            message: 'Số điểm không được vượt quá 10,000!'
                        }
                    ]}
                >
                    <InputNumber
                        placeholder="Nhập số điểm (ví dụ: 100)"
                        size="large"
                        style={{ width: '100%' }}
                        min={1}
                        max={10000}
                    />
                </Form.Item>

                <Form.Item
                    label="Lý do/Mô tả"
                    name="description"
                    rules={[
                        {
                            required: true,
                            message: 'Vui lòng nhập lý do phát hành điểm!'
                        },
                        {
                            min: 10,
                            message: 'Mô tả phải có ít nhất 10 ký tự!'
                        },
                        {
                            max: 500,
                            message: 'Mô tả không được vượt quá 500 ký tự!'
                        }
                    ]}
                >
                    <Input.TextArea
                        placeholder="Nhập lý do phát hành điểm (ví dụ: Thưởng cho khách hàng thân thiết, Hoàn điểm do lỗi hệ thống...)"
                        rows={4}
                        showCount
                        maxLength={500}
                    />
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default IssuePointsModal;