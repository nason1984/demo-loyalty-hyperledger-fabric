// File: src/App.tsx
import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import AppLayout from './components/Layout';
import CustomerDashboard from './pages/Customer/Dashboard';
import TransactionHistoryPage from './pages/Customer/History';
import RedeemPage from './pages/Customer/Redeem';
import TransferPage from './pages/Customer/Transfer';
import EmployeeDashboard from './pages/Employee/Dashboard'; 
import './App.css';

const ProtectedRoutes: React.FC = () => (
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

const App: React.FC = () => {
  const [isLoggedIn, setIsLoggedIn] = useState(true); // Tạm thời để true để test
  const handleLoginSuccess = () => setIsLoggedIn(true);

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage onLoginSuccess={handleLoginSuccess} />} />
        {/* Thêm route cho employee dashboard, tạm thời không cần login */}
        <Route path="/employee/dashboard" element={<EmployeeDashboard />} />
        <Route path="/*" element={isLoggedIn ? <ProtectedRoutes /> : <Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;