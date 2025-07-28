import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { jwtDecode } from 'jwt-decode';

interface AuthState {
  isLoggedIn: boolean;
  token: string | null;
  user: {
    username: string;
    role: string;
  } | null;
}

// Initialize state by checking localStorage
const getInitialState = (): AuthState => {
  try {
    const token = localStorage.getItem('authToken');
    if (token) {
      // Verify token is valid
      const decoded: any = jwtDecode(token);
      
      // Check if token is expired
      const currentTime = Date.now() / 1000;
      if (decoded.exp < currentTime) {
        localStorage.removeItem('authToken');
        return { isLoggedIn: false, token: null, user: null };
      }
      
      return {
        isLoggedIn: true,
        token,
        user: {
          username: decoded.username || 'User',
          role: decoded.role || 'customer'
        }
      };
    }
  } catch (error) {
    console.error('Error loading auth state:', error);
    localStorage.removeItem('authToken');
  }
  
  return {
    isLoggedIn: false,
    token: null,
    user: null,
  };
};

const initialState: AuthState = getInitialState();

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    loginSuccess: (state, action: PayloadAction<string>) => {
      const token = action.payload;
      try {
        const decoded: any = jwtDecode(token);
        state.isLoggedIn = true;
        state.token = token;
        state.user = {
          username: decoded.username || decoded.sub || '',
          role: decoded.role || 'customer',
        };
        localStorage.setItem('authToken', token);
      } catch (error) {
        console.error('Invalid token:', error);
      }
    },
    logout: (state) => {
      state.isLoggedIn = false;
      state.token = null;
      state.user = null;
      localStorage.removeItem('authToken');
    },
  },
});

export const { loginSuccess, logout } = authSlice.actions;
export default authSlice.reducer;