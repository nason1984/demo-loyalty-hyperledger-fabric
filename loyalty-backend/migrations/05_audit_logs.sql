-- Create audit_logs table for tracking user actions
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    username VARCHAR(50),
    action VARCHAR(100) NOT NULL,
    resource VARCHAR(100),
    resource_id VARCHAR(100),
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_username ON audit_logs(username);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource);

-- Function to insert audit log
CREATE OR REPLACE FUNCTION log_user_action(
    p_user_id INTEGER,
    p_username VARCHAR(50),
    p_action VARCHAR(100),
    p_resource VARCHAR(100) DEFAULT NULL,
    p_resource_id VARCHAR(100) DEFAULT NULL,
    p_details JSONB DEFAULT '{}'::jsonb,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO audit_logs (
        user_id, username, action, resource, resource_id, 
        details, ip_address, user_agent
    ) VALUES (
        p_user_id, p_username, p_action, p_resource, p_resource_id,
        p_details, p_ip_address, p_user_agent
    );
END;
$$ LANGUAGE plpgsql;
