-- Base de datos para métricas de desarrollo DevOps
CREATE TABLE IF NOT EXISTS developers (
    id SERIAL PRIMARY KEY,
    developer_name VARCHAR(100) NOT NULL,
    developer_email VARCHAR(255) UNIQUE NOT NULL,
    gitlab_username VARCHAR(100) UNIQUE NOT NULL,
    team VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS repositories (
    id SERIAL PRIMARY KEY,
    repo_id INTEGER UNIQUE NOT NULL,
    repo_name VARCHAR(255) NOT NULL,
    repo_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS daily_commits (
    id SERIAL PRIMARY KEY,
    developer_id INTEGER REFERENCES developers(id),
    repo_id INTEGER REFERENCES repositories(id),
    commit_date DATE NOT NULL,
    commit_count INTEGER DEFAULT 0,
    lines_added INTEGER DEFAULT 0,
    lines_deleted INTEGER DEFAULT 0,
    files_changed INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(developer_id, repo_id, commit_date)
);

CREATE TABLE IF NOT EXISTS code_frequency (
    id SERIAL PRIMARY KEY,
    repo_id INTEGER REFERENCES repositories(id),
    analysis_date DATE NOT NULL,
    total_lines INTEGER DEFAULT 0,
    total_files INTEGER DEFAULT 0,
    languages JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(repo_id, analysis_date)
);

CREATE TABLE IF NOT EXISTS developer_activity (
    id SERIAL PRIMARY KEY,
    developer_id INTEGER REFERENCES developers(id),
    activity_date DATE NOT NULL,
    active_days_7 INTEGER DEFAULT 0,
    active_days_30 INTEGER DEFAULT 0,
    total_commits INTEGER DEFAULT 0,
    avg_commits_per_day DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(developer_id, activity_date)
);

-- Índices para mejor rendimiento
CREATE INDEX idx_daily_commits_date ON daily_commits(commit_date);
CREATE INDEX idx_daily_commits_dev_repo ON daily_commits(developer_id, repo_id);
CREATE INDEX idx_code_frequency_date ON code_frequency(analysis_date);
CREATE INDEX idx_developer_activity_date ON developer_activity(activity_date);

-- Vista para dashboard
CREATE OR REPLACE VIEW vw_daily_metrics AS
SELECT 
    dc.commit_date,
    d.developer_name,
    d.team,
    r.repo_name,
    dc.commit_count,
    dc.lines_added,
    dc.lines_deleted,
    dc.files_changed,
    COALESCE(dc.lines_added, 0) - COALESCE(dc.lines_deleted, 0) as net_lines
FROM daily_commits dc
JOIN developers d ON dc.developer_id = d.id
JOIN repositories r ON dc.repo_id = r.id;

-- Vista para métricas de equipo
CREATE OR REPLACE VIEW vw_team_metrics AS
SELECT 
    commit_date,
    team,
    COUNT(DISTINCT developer_id) as active_developers,
    SUM(commit_count) as total_commits,
    SUM(lines_added) as total_lines_added,
    SUM(lines_deleted) as total_lines_deleted,
    AVG(commit_count) as avg_commits_per_dev
FROM daily_commits dc
JOIN developers d ON dc.developer_id = d.id
GROUP BY commit_date, team;

-- Tabla para almacenar logs del workflow
CREATE TABLE IF NOT EXISTS workflow_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(255) NOT NULL,
    execution_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL,
    records_processed INTEGER DEFAULT 0,
    error_message TEXT,
    duration_ms INTEGER
);