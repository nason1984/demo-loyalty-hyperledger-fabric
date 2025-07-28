import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { RootState } from './redux/store';
import LoginPage from './pages/LoginPage';
import AppLayout from './components/Layout';
import CustomerDashboard from './pages/Customer/Dashboard';
import TransactionHistoryPage from './pages/Customer/History';
import RedeemPage from './pages/Customer/Redeem';
import TransferPage from './pages/Customer/Transfer';
import EmployeeDashboard from './pages/Employee/Dashboard'; 
import './App.css';

// Customer Routes Component
const CustomerRoutes: React.FC = () => (
  <AppLayout>
    <Routes>
      <Route path="/dashboard" element={<CustomerDashboard />} />
      <Route path="/history" element={<TransactionHistoryPage />} />
      <Route path="/redeem" element={<RedeemPage />} />
      <Route path="/transfer" element={<TransferPage />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  </AppLayout>
);

// Employee Routes Component
const EmployeeRoutes: React.FC = () => (
  <AppLayout>
    <Routes>
      <Route path="/dashboard" element={<EmployeeDashboard />} />
      <Route path="/employee/dashboard" element={<EmployeeDashboard />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  </AppLayout>
);

// Default Routes for users without clear role
const DefaultRoutes: React.FC = () => (
  <AppLayout>
    <Routes>
      <Route path="*" element={
        <div style={{ padding: '20px', textAlign: 'center' }}>
          <h2>Không thể xác định vai trò người dùng</h2>
          <p>Vui lòng đăng nhập lại</p>
        </div>
      } />
    </Routes>
  </AppLayout>
);

const App: React.FC = () => {
  const isLoggedIn = useSelector((state: RootState) => state.auth.isLoggedIn);
  const user = useSelector((state: RootState) => state.auth.user);
  
  console.log('App render - isLoggedIn:', isLoggedIn);
  console.log('App render - user:', user);

  // Render routes based on authentication and user role
  const renderAuthenticatedRoutes = () => {
    if (!user || !user.role) {
      return <DefaultRoutes />;
    }

    switch (user.role) {
      case 'customer':
        return <CustomerRoutes />;
      case 'employee':
        return <EmployeeRoutes />;
      default:
        return <DefaultRoutes />;
    }
  };

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/*" element={
          isLoggedIn ? renderAuthenticatedRoutes() : <Navigate to="/login" replace />
        } />
      </Routes>
    </BrowserRouter>
  );
};

export default App;