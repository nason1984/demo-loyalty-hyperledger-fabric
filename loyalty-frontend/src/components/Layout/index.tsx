// File: src/components/Layout/index.tsx
import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  PieChartOutlined,
  HistoryOutlined,
  GiftOutlined,
  UserOutlined,
  LogoutOutlined,
  SwapOutlined,
} from '@ant-design/icons';
import type { MenuProps } from 'antd';
import { Layout, Menu, theme, Dropdown, Space, Avatar } from 'antd';

const { Header, Content, Footer, Sider } = Layout;

const AppLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
	const [collapsed, setCollapsed] = useState(false);
	const { token: { colorBgContainer, borderRadiusLG } } = theme.useToken();

	const menuItems: MenuProps['items'] = [
		{ key: '/dashboard', icon: <PieChartOutlined />, label: <Link to="/dashboard">Tổng quan</Link> },
		{ key: '/history', icon: <HistoryOutlined />, label: <Link to="/history">Lịch sử giao dịch</Link> },
		{ key: '/redeem', icon: <GiftOutlined />, label: <Link to="/redeem">Quy đổi điểm</Link> },
		{ key: '/transfer', icon: <SwapOutlined />, label: <Link to="/transfer">Chuyển điểm</Link> },
	];
	
	const location = useLocation();

	const userMenuItems: MenuProps['items'] = [
		{ key: 'profile', icon: <UserOutlined />, label: 'Thông tin cá nhân' },
		{ key: 'logout', icon: <LogoutOutlined />, label: 'Đăng xuất', danger: true },
	];

	return (
		<Layout style={{ minHeight: '100vh' }}>
			<Sider collapsible collapsed={collapsed} onCollapse={(value) => setCollapsed(value)}>
				<div style={{ height: '32px', margin: '16px', background: 'rgba(255, 255, 255, 0.2)' }} />
				<Menu theme="dark" selectedKeys={[location.pathname]} mode="inline" items={menuItems} />
			</Sider>
			<Layout>
				<Header style={{ padding: '0 16px', background: colorBgContainer, display: 'flex', justifyContent: 'flex-end', alignItems: 'center' }}>
                    <Dropdown menu={{ items: userMenuItems }}>
                        <a onClick={(e) => e.preventDefault()}><Space><Avatar icon={<UserOutlined />} /><span>Admin</span></Space></a>
                    </Dropdown>
                </Header>
				<Content style={{ margin: '0 16px' }}><div style={{ padding: 24, minHeight: 360, background: colorBgContainer, borderRadius: borderRadiusLG, marginTop: 16 }}>{children}</div></Content>
				<Footer style={{ textAlign: 'center' }}>Loyalty System ©{new Date().getFullYear()}</Footer>
			</Layout>
		</Layout>
	);
};

export default AppLayout;