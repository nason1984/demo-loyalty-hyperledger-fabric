-- Create system_config table for application settings
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    data_type VARCHAR(20) DEFAULT 'string' CHECK (data_type IN ('string', 'number', 'boolean', 'json')),
    is_secret BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_system_config_key ON system_config(config_key);

-- Insert default configuration
INSERT INTO system_config (config_key, config_value, description, data_type) VALUES 
('app_name', 'Loyalty Management System', 'Application name', 'string'),
('app_version', '1.0.0', 'Application version', 'string'),
('default_points_rate', '1', 'Default points earning rate per dollar', 'number'),
('max_points_per_transaction', '10000', 'Maximum points that can be issued in one transaction', 'number'),
('points_expiry_days', '365', 'Number of days before points expire', 'number'),
('enable_point_transfer', 'true', 'Whether point transfer between customers is enabled', 'boolean')
ON CONFLICT (config_key) DO NOTHING;
