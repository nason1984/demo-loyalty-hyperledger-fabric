import axiosClient from './axiosClient';

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  message?: string;
  data?: {
    token: string;
    user: {
      username: string;
      role: string;
    };
  };
  error?: string;
}

export const authAPI = {
  login: (credentials: LoginRequest): Promise<LoginResponse> => {
    return axiosClient.post('/auth/login', credentials);
  },

  logout: (): Promise<{ success: boolean; message?: string }> => {
    return axiosClient.post('/auth/logout');
  },

  getProfile: (): Promise<any> => {
    return axiosClient.get('/auth/profile');
  },
};
