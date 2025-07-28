// File: src/components/Layout/index.tsx
import React, { useState, useMemo } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { logout } from '../../redux/slices/authSlice';
import { authAPI } from '../../api/authAPI';
import { RootState } from '../../redux/store';
import {
  PieChartOutlined,
  HistoryOutlined,
  GiftOutlined,
  UserOutlined,
  LogoutOutlined,
  SwapOutlined,
  DashboardOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import type { MenuProps } from 'antd';
import { Layout, Menu, theme, Dropdown, Space, Avatar, message } from 'antd';

const { Header, Content, Footer, Sider } = Layout;

const AppLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
	const [collapsed, setCollapsed] = useState(false);
	const { token: { colorBgContainer, borderRadiusLG } } = theme.useToken();
	const dispatch = useDispatch();
	const navigate = useNavigate();
	const { user } = useSelector((state: RootState) => state.auth);

	const handleMenuClick = async (e: { key: string }) => {
		if (e.key === 'logout') {
			try {
				console.log('Logout clicked');
				
				// Gọi API logout để vô hiệu hóa token trên server
				await authAPI.logout();
				
				// Dispatch logout action để xóa thông tin user khỏi Redux store
				dispatch(logout());
				
				// Điều hướng về trang login
				navigate('/login');
				
				message.success('Đăng xuất thành công!');
			} catch (error) {
				console.error('Logout error:', error);
				// Dù có lỗi từ API, vẫn logout ở frontend
				dispatch(logout());
				navigate('/login');
				message.warning('Đã đăng xuất khỏi hệ thống');
			}
		} else if (e.key === 'profile') {
			// TODO: Navigate to profile page
			message.info('Tính năng đang phát triển');
		}
	};

	// Tạo menu items dựa trên vai trò người dùng
	const menuItems: MenuProps['items'] = useMemo(() => {
		const userRole = user?.role;

		if (userRole === 'customer') {
			// Menu cho khách hàng
			return [
				{ key: '/dashboard', icon: <PieChartOutlined />, label: <Link to="/dashboard">Tổng quan</Link> },
				{ key: '/history', icon: <HistoryOutlined />, label: <Link to="/history">Lịch sử giao dịch</Link> },
				{ key: '/redeem', icon: <GiftOutlined />, label: <Link to="/redeem">Quy đổi điểm</Link> },
				{ key: '/transfer', icon: <SwapOutlined />, label: <Link to="/transfer">Chuyển điểm</Link> },
			];
		} else if (userRole === 'employee') {
			// Menu cho nhân viên
			return [
				{ key: '/dashboard', icon: <DashboardOutlined />, label: <Link to="/dashboard">Bảng điều khiển</Link> },
				{ key: '/customers', icon: <TeamOutlined />, label: <Link to="/customers">Quản lý Khách hàng</Link> },
			];
		}

		// Menu mặc định nếu không có vai trò rõ ràng
		return [
			{ key: '/dashboard', icon: <PieChartOutlined />, label: <Link to="/dashboard">Tổng quan</Link> },
		];
	}, [user?.role]);
	
	const location = useLocation();

	const userMenuItems: MenuProps['items'] = [
		{ key: 'profile', icon: <UserOutlined />, label: 'Thông tin cá nhân' },
		{ key: 'logout', icon: <LogoutOutlined />, label: 'Đăng xuất', danger: true },
	];

	// Hiển thị vai trò người dùng trong header
	const getUserDisplayInfo = () => {
		const username = user?.username || 'User';
		const role = user?.role;
		const roleDisplay = role === 'customer' ? 'Khách hàng' : role === 'employee' ? 'Nhân viên' : '';
		
		return (
			<Space direction="vertical" size={0} style={{ textAlign: 'right', lineHeight: '1.2' }}>
				<span style={{ fontWeight: 'bold', fontSize: '14px' }}>{username}</span>
				{roleDisplay && <span style={{ fontSize: '12px', color: '#666', fontStyle: 'italic' }}>{roleDisplay}</span>}
			</Space>
		);
	};

	return (
		<Layout style={{ minHeight: '100vh' }}>
			<Sider collapsible collapsed={collapsed} onCollapse={(value) => setCollapsed(value)}>
				<div style={{ height: '32px', margin: '16px', background: 'rgba(255, 255, 255, 0.2)' }} />
				<Menu theme="dark" selectedKeys={[location.pathname]} mode="inline" items={menuItems} />
			</Sider>
			<Layout>
				<Header style={{ padding: '0 16px', background: colorBgContainer, display: 'flex', justifyContent: 'flex-end', alignItems: 'center' }}>
                    <Dropdown menu={{ items: userMenuItems, onClick: handleMenuClick }} trigger={['click']}>
                        <div style={{ 
							cursor: 'pointer', 
							display: 'flex', 
							alignItems: 'center', 
							gap: '12px',
							padding: '8px 12px',
							borderRadius: '6px',
							transition: 'background-color 0.2s',
						}}
						onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f5f5f5'}
						onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
						>
                            <Avatar 
								icon={<UserOutlined />} 
								style={{ 
									backgroundColor: '#1890ff',
									border: '2px solid #f0f0f0'
								}}
							/>
                            {getUserDisplayInfo()}
                        </div>
                    </Dropdown>
                </Header>
				<Content style={{ margin: '0 16px' }}><div style={{ padding: 24, minHeight: 360, background: colorBgContainer, borderRadius: borderRadiusLG, marginTop: 16 }}>{children}</div></Content>
				<Footer style={{ textAlign: 'center' }}>Loyalty System ©{new Date().getFullYear()}</Footer>
			</Layout>
		</Layout>
	);
};

export default AppLayout;