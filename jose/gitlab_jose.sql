-- Database: gitlab_metrics

CREATE DATABASE gitlab_metrics;

\c gitlab_metrics;

-- Tabla de proyectos
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    gitlab_project_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    default_branch VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de usuarios/desarrolladores
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    gitlab_user_id INTEGER UNIQUE NOT NULL,
    username VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    email VARCHAR(255),
    is_bot BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla principal de métricas de commits
CREATE TABLE commit_metrics (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id),
    user_id INTEGER REFERENCES users(id),
    commit_sha VARCHAR(40) NOT NULL,
    commit_date TIMESTAMP NOT NULL,
    commit_message TEXT,
    message_length INTEGER,
    message_quality BOOLEAN,
    additions INTEGER DEFAULT 0,
    deletions INTEGER DEFAULT 0,
    total_changes INTEGER DEFAULT 0,
    files_changed INTEGER DEFAULT 0,
    branch VARCHAR(255),
    is_merge_commit BOOLEAN DEFAULT FALSE,
    is_revert BOOLEAN DEFAULT FALSE,
    has_issue_reference BOOLEAN DEFAULT FALSE,
    has_mr_reference BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, commit_sha)
);

-- Tabla de archivos modificados por commit
CREATE TABLE commit_files (
    id SERIAL PRIMARY KEY,
    commit_metric_id INTEGER REFERENCES commit_metrics(id),
    file_path TEXT NOT NULL,
    file_extension VARCHAR(50),
    additions INTEGER DEFAULT 0,
    deletions INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de métricas agregadas por día
CREATE TABLE daily_metrics (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id),
    user_id INTEGER REFERENCES users(id),
    metric_date DATE NOT NULL,
    commits_count INTEGER DEFAULT 0,
    total_additions INTEGER DEFAULT 0,
    total_deletions INTEGER DEFAULT 0,
    total_files_changed INTEGER DEFAULT 0,
    avg_commit_size DECIMAL(10,2),
    commits_outside_work_hours INTEGER DEFAULT 0,
    commits_weekend INTEGER DEFAULT 0,
    commits_with_quality_message INTEGER DEFAULT 0,
    commits_with_issue_ref INTEGER DEFAULT 0,
    commits_with_mr_ref INTEGER DEFAULT 0,
    revert_commits INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id, metric_date)
);

-- Tabla de métricas agregadas por semana
CREATE TABLE weekly_metrics (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id),
    user_id INTEGER REFERENCES users(id),
    year INTEGER NOT NULL,
    week INTEGER NOT NULL,
    commits_count INTEGER DEFAULT 0,
    active_days INTEGER DEFAULT 0,
    total_additions INTEGER DEFAULT 0,
    total_deletions INTEGER DEFAULT 0,
    avg_commit_size DECIMAL(10,2),
    avg_files_per_commit DECIMAL(10,2),
    commits_outside_work_hours INTEGER DEFAULT 0,
    commits_weekend INTEGER DEFAULT 0,
    commits_main_branch INTEGER DEFAULT 0,
    code_churn INTEGER DEFAULT 0,
    revert_rate DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id, year, week)
);

-- Tabla de alertas y umbrales
CREATE TABLE alert_thresholds (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id),
    metric_name VARCHAR(100) NOT NULL,
    min_threshold DECIMAL(10,2),
    max_threshold DECIMAL(10,2),
    severity VARCHAR(50) DEFAULT 'warning',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de alertas generadas
CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id),
    user_id INTEGER REFERENCES users(id),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,2),
    threshold_value DECIMAL(10,2),
    severity VARCHAR(50),
    message TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar performance
CREATE INDEX idx_commit_metrics_date ON commit_metrics(commit_date);
CREATE INDEX idx_commit_metrics_project ON commit_metrics(project_id);
CREATE INDEX idx_commit_metrics_user ON commit_metrics(user_id);
CREATE INDEX idx_daily_metrics_date ON daily_metrics(metric_date);
CREATE INDEX idx_weekly_metrics_week ON weekly_metrics(year, week);
CREATE INDEX idx_commit_files_extension ON commit_files(file_extension);

-- Insertar umbrales por defecto
INSERT INTO alert_thresholds (project_id, metric_name, min_threshold, max_threshold, severity) VALUES
(NULL, 'commit_frequency', 2, 10, 'warning'),
(NULL, 'commit_size_loc', 50, 300, 'warning'),
(NULL, 'commit_granularity', 1, 5, 'warning'),
(NULL, 'work_hours_distribution', NULL, 20, 'warning'),
(NULL, 'active_days_ratio', 60, 80, 'info'),
(NULL, 'branch_discipline', NULL, 10, 'critical'),
(NULL, 'revert_rate', NULL, 5, 'critical'),
(NULL, 'issue_linked_commits', 80, NULL, 'warning');

-- Función para actualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para actualizar updated_at
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_metrics_updated_at BEFORE UPDATE ON daily_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_metrics_updated_at BEFORE UPDATE ON weekly_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();