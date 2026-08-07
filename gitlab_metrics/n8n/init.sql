-- ============================================
-- ESQUEMA PARA MÉTRICAS GITLAB COMPLETAS
-- ============================================

-- 1. TABLA DE USUARIOS (ya existe, pero mejorada)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    gitlab_id INTEGER UNIQUE NOT NULL,
    username VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    avatar_url TEXT,
    email VARCHAR(255),
    state VARCHAR(50),
    web_url TEXT,
    is_active BOOLEAN DEFAULT true,
    is_bot BOOLEAN DEFAULT false,
    last_sync TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. TABLA DE PROYECTOS
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    gitlab_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    name_with_namespace VARCHAR(500),
    description TEXT,
    path VARCHAR(255),
    path_with_namespace VARCHAR(500),
    web_url TEXT,
    ssh_url TEXT,
    http_url TEXT,
    default_branch VARCHAR(100),
    visibility VARCHAR(50),
    owner_id INTEGER REFERENCES users(gitlab_id),
    namespace_id INTEGER,
    namespace_name VARCHAR(255),
    last_activity_at TIMESTAMP,
    created_at_gitlab TIMESTAMP,
    updated_at_gitlab TIMESTAMP,
    archived BOOLEAN DEFAULT false,
    forks_count INTEGER DEFAULT 0,
    star_count INTEGER DEFAULT 0,
    open_issues_count INTEGER DEFAULT 0,
    creator_id INTEGER,
    is_active BOOLEAN DEFAULT true,
    last_sync TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. TABLA DE RELACIONES USUARIO-PROYECTO (NUEVA - CRÍTICA)
CREATE TABLE IF NOT EXISTS user_project_relations (
    id SERIAL PRIMARY KEY,
    user_gitlab_id INTEGER NOT NULL,
    project_gitlab_id INTEGER NOT NULL,
    username VARCHAR(255),
    user_name VARCHAR(255),
    project_name VARCHAR(255),
    project_path_with_namespace VARCHAR(500),
    access_level INTEGER NOT NULL,
    user_role VARCHAR(50),
    membership_type VARCHAR(20),
    -- Roles: Guest(10), Reporter(20), Developer(30), Maintainer(40), Owner(50)
    notification_level INTEGER,
    expires_at TIMESTAMP,
    is_direct_member BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMP,
    created_at_gitlab TIMESTAMP,
    sync_timestamp TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_gitlab_id, project_gitlab_id)
);

-- 4. TABLA DE COMMITS
CREATE TABLE IF NOT EXISTS commits (
    id SERIAL PRIMARY KEY,
    gitlab_id VARCHAR(100) UNIQUE NOT NULL,
    project_gitlab_id INTEGER NOT NULL,
    title TEXT,
    message TEXT,
    author_name VARCHAR(255),
    author_email VARCHAR(255),
    author_username VARCHAR(255),
    committer_name VARCHAR(255),
    committer_email VARCHAR(255),
    created_at_gitlab TIMESTAMP,
    committed_date TIMESTAMP,
    web_url TEXT,
    stats_additions INTEGER DEFAULT 0,
    stats_deletions INTEGER DEFAULT 0,
    stats_total INTEGER DEFAULT 0,
    -- Para análisis temporal
    commit_date DATE,
    commit_hour INTEGER,
    commit_weekday INTEGER,
    commit_month INTEGER,
    commit_year INTEGER,
    -- Metadata
    processed_at TIMESTAMP DEFAULT NOW(),
    is_merge_commit BOOLEAN DEFAULT false,
    parent_ids TEXT[], -- Array de IDs parent
    INDEX idx_commits_author_email (author_email),
    INDEX idx_commits_project_date (project_gitlab_id, commit_date)
);

-- 5. TABLA DE MÉTRICAS HORARIAS
CREATE TABLE IF NOT EXISTS hourly_metrics (
    id SERIAL PRIMARY KEY,
    author_email VARCHAR(255) NOT NULL,
    author_username VARCHAR(255),
    author_name VARCHAR(255),
    metric_date DATE NOT NULL,
    metric_hour INTEGER NOT NULL,
    commit_count INTEGER DEFAULT 0,
    additions_total INTEGER DEFAULT 0,
    deletions_total INTEGER DEFAULT 0,
    files_changed_total INTEGER DEFAULT 0,
    avg_changes_per_commit DECIMAL(10,2),
    first_commit_time TIMESTAMP,
    last_commit_time TIMESTAMP,
    -- Para análisis
    is_weekday BOOLEAN,
    is_working_hours BOOLEAN,
    sync_timestamp TIMESTAMP DEFAULT NOW(),
    UNIQUE(author_email, metric_date, metric_hour)
);

-- 6. TABLA DE MÉTRICAS DIARIAS
CREATE TABLE IF NOT EXISTS daily_metrics (
    id SERIAL PRIMARY KEY,
    author_email VARCHAR(255) NOT NULL,
    author_username VARCHAR(255),
    author_name VARCHAR(255),
    metric_date DATE NOT NULL,
    commit_count INTEGER DEFAULT 0,
    additions_total INTEGER DEFAULT 0,
    deletions_total INTEGER DEFAULT 0,
    files_changed_total INTEGER DEFAULT 0,
    hours_active INTEGER DEFAULT 0, -- Horas distintas con commits
    avg_commits_per_hour DECIMAL(10,2),
    -- Métricas de productividad
    productivity_score DECIMAL(10,2),
    avg_changes_per_commit DECIMAL(10,2),
    -- Tiempos
    first_commit_time TIMESTAMP,
    last_commit_time TIMESTAMP,
    total_active_hours DECIMAL(10,2),
    -- Proyectos trabajados
    projects_worked_count INTEGER DEFAULT 0,
    projects_worked TEXT[], -- Array de proyectos
    sync_timestamp TIMESTAMP DEFAULT NOW(),
    UNIQUE(author_email, metric_date)
);

-- 7. TABLA DE MÉTRICAS SEMANALES (OPCIONAL)
CREATE TABLE IF NOT EXISTS weekly_metrics (
    id SERIAL PRIMARY KEY,
    author_email VARCHAR(255) NOT NULL,
    author_username VARCHAR(255),
    author_name VARCHAR(255),
    year INTEGER NOT NULL,
    week_number INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    commit_count INTEGER DEFAULT 0,
    additions_total INTEGER DEFAULT 0,
    deletions_total INTEGER DEFAULT 0,
    days_active INTEGER DEFAULT 0,
    avg_commits_per_day DECIMAL(10,2),
    -- Proyectos
    projects_worked_count INTEGER DEFAULT 0,
    distinct_projects TEXT[],
    -- Tendencias
    week_over_week_growth DECIMAL(10,2),
    sync_timestamp TIMESTAMP DEFAULT NOW(),
    UNIQUE(author_email, year, week_number)
);

-- 8. TABLA DE COMMITS IMPORTANTES
CREATE TABLE IF NOT EXISTS important_commits (
    id SERIAL PRIMARY KEY,
    commit_gitlab_id VARCHAR(100) REFERENCES commits(gitlab_id),
    project_gitlab_id INTEGER,
    author_email VARCHAR(255),
    commit_date DATE,
    changes_total INTEGER,
    reason VARCHAR(255), -- 'large_change', 'infrastructure', 'critical_fix'
    diff_summary TEXT,
    processed BOOLEAN DEFAULT false,
    analyzed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

CREATE INDEX idx_users_gitlab_id ON users(gitlab_id);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;

CREATE INDEX idx_projects_gitlab_id ON projects(gitlab_id);
CREATE INDEX idx_projects_activity ON projects(last_activity_at DESC);
CREATE INDEX idx_projects_active ON projects(is_active) WHERE is_active = true;

CREATE INDEX idx_relations_user_project ON user_project_relations(user_gitlab_id, project_gitlab_id);
CREATE INDEX idx_relations_access_level ON user_project_relations(access_level);
CREATE INDEX idx_relations_user ON user_project_relations(user_gitlab_id);
CREATE INDEX idx_relations_project ON user_project_relations(project_gitlab_id);

CREATE INDEX idx_commits_author_date ON commits(author_email, commit_date);
CREATE INDEX idx_commits_project_author ON commits(project_gitlab_id, author_email);
CREATE INDEX idx_commits_date ON commits(commit_date DESC);

CREATE INDEX idx_hourly_metrics_date_hour ON hourly_metrics(metric_date, metric_hour);
CREATE INDEX idx_hourly_metrics_author ON hourly_metrics(author_email);

CREATE INDEX idx_daily_metrics_date ON daily_metrics(metric_date DESC);
CREATE INDEX idx_daily_metrics_author ON daily_metrics(author_email);

-- ============================================
-- VISTAS PARA ANÁLISIS
-- ============================================

-- Vista: Resumen de usuarios activos
CREATE OR REPLACE VIEW vw_active_users_summary AS
SELECT 
    u.gitlab_id,
    u.username,
    u.name,
    COUNT(DISTINCT upr.project_gitlab_id) as total_projects,
    COUNT(DISTINCT 
        CASE WHEN upr.access_level >= 30 THEN upr.project_gitlab_id END
    ) as developer_projects,
    MAX(upr.last_activity_at) as last_project_activity,
    u.last_sync
FROM users u
LEFT JOIN user_project_relations upr ON u.gitlab_id = upr.user_gitlab_id
WHERE u.is_active = true
GROUP BY u.gitlab_id, u.username, u.name, u.last_sync
ORDER BY total_projects DESC;

-- Vista: Métricas de productividad por usuario
CREATE OR REPLACE VIEW vw_user_productivity AS
SELECT 
    u.gitlab_id,
    u.username,
    u.name,
    COUNT(DISTINCT c.id) as total_commits,
    COUNT(DISTINCT c.project_gitlab_id) as projects_with_commits,
    SUM(c.stats_additions) as total_additions,
    SUM(c.stats_deletions) as total_deletions,
    AVG(c.stats_total) as avg_changes_per_commit,
    MIN(c.commit_date) as first_commit_date,
    MAX(c.commit_date) as last_commit_date,
    COUNT(DISTINCT c.commit_date) as active_days
FROM users u
LEFT JOIN commits c ON u.email = c.author_email
WHERE u.is_bot = false
GROUP BY u.gitlab_id, u.username, u.name
ORDER BY total_commits DESC;

-- Vista: Proyectos más activos
CREATE OR REPLACE VIEW vw_active_projects AS
SELECT 
    p.gitlab_id,
    p.name,
    p.path_with_namespace,
    COUNT(DISTINCT c.id) as total_commits,
    COUNT(DISTINCT c.author_email) as unique_authors,
    MAX(c.commit_date) as last_commit_date,
    SUM(c.stats_total) as total_changes,
    p.last_activity_at
FROM projects p
LEFT JOIN commits c ON p.gitlab_id = c.project_gitlab_id
WHERE p.is_active = true
GROUP BY p.gitlab_id, p.name, p.path_with_namespace, p.last_activity_at
ORDER BY last_commit_date DESC;

-- ============================================
-- FUNCIONES DE UTILIDAD
-- ============================================

-- Función: Calcular horas laborables
CREATE OR REPLACE FUNCTION is_working_hour(hour INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN hour BETWEEN 9 AND 17; -- 9AM a 5PM
END;
$$ LANGUAGE plpgsql;

-- Función: Calcular si es día laborable
CREATE OR REPLACE FUNCTION is_weekday(weekday INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN weekday BETWEEN 1 AND 5; -- Lunes(1) a Viernes(5)
END;
$$ LANGUAGE plpgsql;

-- Función: Obtener rol desde access_level
CREATE OR REPLACE FUNCTION get_role_from_access(access_level INTEGER)
RETURNS VARCHAR(50) AS $$
BEGIN
    RETURN CASE 
        WHEN access_level >= 50 THEN 'Owner'
        WHEN access_level >= 40 THEN 'Maintainer'
        WHEN access_level >= 30 THEN 'Developer'
        WHEN access_level >= 20 THEN 'Reporter'
        WHEN access_level >= 10 THEN 'Guest'
        ELSE 'Unknown'
    END;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA
-- ============================================

-- Trigger: Actualizar updated_at en users
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_users_updated_at();

-- Trigger: Actualizar updated_at en projects
CREATE OR REPLACE FUNCTION update_projects_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION update_projects_updated_at();