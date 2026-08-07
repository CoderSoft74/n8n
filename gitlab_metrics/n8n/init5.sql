-- -- Database: gitlab_metrics
-- CREATE DATABASE gitlab_metrics;

-- -- Conectar a la base de datos
-- \c gitlab_metrics;

-- Tabla de Usuarios
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    gitlab_id INTEGER UNIQUE NOT NULL,
    username VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_sync TIMESTAMP
);

-- Tabla de Proyectos
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    gitlab_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    name_with_namespace VARCHAR(500),
    description TEXT,
    web_url TEXT,
    ssh_url TEXT,
    http_url TEXT,
    default_branch VARCHAR(100),
    visibility VARCHAR(50),
    last_activity_at TIMESTAMP,
    created_at_gitlab TIMESTAMP,
    updated_at_gitlab TIMESTAMP,
    archived BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Relación Usuario-Proyecto
CREATE TABLE user_projects (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    project_id INTEGER REFERENCES projects(project_id) ON DELETE CASCADE,
    access_level INTEGER,
    role VARCHAR(100),
    is_current BOOLEAN DEFAULT TRUE,
    joined_at TIMESTAMP,
    left_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, project_id)
);

-- Tabla de Commits
CREATE TABLE commits (
    commit_id SERIAL PRIMARY KEY,
    gitlab_id VARCHAR(100) UNIQUE NOT NULL,
    project_id INTEGER REFERENCES projects(project_id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES users(user_id),
    author_name VARCHAR(200),
    author_email VARCHAR(255),
    title TEXT NOT NULL,
    message TEXT,
    created_at_gitlab TIMESTAMP NOT NULL,
    committed_date TIMESTAMP,
    web_url TEXT,
    stats_additions INTEGER DEFAULT 0,
    stats_deletions INTEGER DEFAULT 0,
    stats_total INTEGER DEFAULT 0,
    files_changed INTEGER DEFAULT 0,
    is_merge_commit BOOLEAN DEFAULT FALSE,
    branch_name VARCHAR(200),
    pipeline_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_commits_created (created_at_gitlab),
    INDEX idx_commits_author (author_id)
);

-- Tabla de Diffs (Cambios de Código)
CREATE TABLE diffs (
    diff_id SERIAL PRIMARY KEY,
    commit_id INTEGER REFERENCES commits(commit_id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    new_file BOOLEAN DEFAULT FALSE,
    renamed_file BOOLEAN DEFAULT FALSE,
    deleted_file BOOLEAN DEFAULT FALSE,
    additions INTEGER DEFAULT 0,
    deletions INTEGER DEFAULT 0,
    diff_text TEXT,
    language VARCHAR(100),
    file_extension VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_diffs_commit (commit_id),
    INDEX idx_diffs_file (file_path)
);

-- Tabla de Métricas Horarias
CREATE TABLE hourly_metrics (
    metric_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    date DATE NOT NULL,
    hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
    commit_count INTEGER DEFAULT 0,
    additions_total INTEGER DEFAULT 0,
    deletions_total INTEGER DEFAULT 0,
    files_changed_total INTEGER DEFAULT 0,
    projects_active INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date, hour),
    INDEX idx_hourly_date (date),
    INDEX idx_hourly_user_date (user_id, date)
);

-- Tabla de Métricas Diarias
CREATE TABLE daily_metrics (
    metric_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    date DATE NOT NULL UNIQUE,
    commit_count INTEGER DEFAULT 0,
    additions_total INTEGER DEFAULT 0,
    deletions_total INTEGER DEFAULT 0,
    files_changed_total INTEGER DEFAULT 0,
    projects_active INTEGER DEFAULT 0,
    avg_commits_per_hour DECIMAL(5,2),
    peak_hour INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_daily_user (user_id),
    INDEX idx_daily_date (date)
);

-- Tabla de Trends Semanales
CREATE TABLE weekly_trends (
    trend_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    commit_count INTEGER DEFAULT 0,
    avg_daily_commits DECIMAL(5,2),
    total_additions INTEGER DEFAULT 0,
    total_deletions INTEGER DEFAULT 0,
    productivity_score DECIMAL(5,2),
    projects_active INTEGER DEFAULT 0,
    consistency_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, week_start),
    INDEX idx_weekly_user (user_id),
    INDEX idx_weekly_dates (week_start, week_end)
);

-- Tabla de Proyectos Activos (Snapshot diario)
CREATE TABLE active_projects_snapshot (
    snapshot_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    user_id INTEGER REFERENCES users(user_id),
    project_id INTEGER REFERENCES projects(project_id),
    commit_count INTEGER DEFAULT 0,
    last_commit_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date, user_id, project_id),
    INDEX idx_snapshot_date (date),
    INDEX idx_snapshot_user (user_id)
);

-- Vista para Dashboard
CREATE VIEW team_dashboard_view AS
SELECT
    u.user_id,
    u.username,
    u.name,
    u.avatar_url,
    COALESCE(dm.commit_count, 0) as today_commits,
    COALESCE(dm.additions_total, 0) as today_additions,
    COALESCE(dm.deletions_total, 0) as today_deletions,
    COALESCE(dm.projects_active, 0) as active_projects,
    COALESCE(wt.productivity_score, 0) as productivity_score,
    COALESCE(wt.consistency_score, 0) as consistency_score,
    (SELECT COUNT(DISTINCT project_id)
     FROM active_projects_snapshot aps
     WHERE aps.user_id = u.user_id
     AND aps.date = CURRENT_DATE) as current_projects,
    (SELECT ARRAY_AGG(DISTINCT p.name)
     FROM active_projects_snapshot aps
     JOIN projects p ON p.project_id = aps.project_id
     WHERE aps.user_id = u.user_id
     AND aps.date = CURRENT_DATE) as project_names
FROM users u
LEFT JOIN daily_metrics dm ON dm.user_id = u.user_id AND dm.date = CURRENT_DATE
LEFT JOIN weekly_trends wt ON wt.user_id = u.user_id
    AND wt.week_start <= CURRENT_DATE
    AND wt.week_end >= CURRENT_DATE
WHERE u.is_active = true;

-- Función para actualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para auto-update
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_hourly_metrics_updated_at BEFORE UPDATE ON hourly_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_metrics_updated_at BEFORE UPDATE ON daily_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();