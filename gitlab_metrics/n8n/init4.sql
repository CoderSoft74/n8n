-- init-db.sql

-- Tabla de proyectos
CREATE TABLE IF NOT EXISTS gitlab_projects (
    id SERIAL PRIMARY KEY,
    project_id INTEGER UNIQUE NOT NULL,
    project_name VARCHAR(255) NOT NULL,
    project_path VARCHAR(255),
    description TEXT,
    web_url TEXT,
    created_at TIMESTAMP,
    last_activity_at TIMESTAMP,
    collected_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de ramas
CREATE TABLE IF NOT EXISTS gitlab_branches (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    branch_name VARCHAR(255) NOT NULL,
    is_default BOOLEAN DEFAULT false,
    protected BOOLEAN DEFAULT false,
    last_commit_id VARCHAR(255),
    last_commit_date TIMESTAMP,
    collected_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(project_id, branch_name)
);

-- Tabla de commits
CREATE TABLE IF NOT EXISTS gitlab_commits (
    id SERIAL PRIMARY KEY,
    commit_id VARCHAR(255) UNIQUE NOT NULL,
    project_id INTEGER NOT NULL,
    branch_name VARCHAR(255),
    author_name VARCHAR(255),
    author_email VARCHAR(255),
    committer_name VARCHAR(255),
    committer_email VARCHAR(255),
    commit_title TEXT,
    commit_message TEXT,
    committed_date TIMESTAMP,
    authored_date TIMESTAMP,
    additions INTEGER DEFAULT 0,
    deletions INTEGER DEFAULT 0,
    total_changes INTEGER DEFAULT 0,
    collected_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de contribuidores/autores
CREATE TABLE IF NOT EXISTS gitlab_contributors (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    author_name VARCHAR(255) NOT NULL,
    author_email VARCHAR(255) NOT NULL,
    total_commits INTEGER DEFAULT 0,
    total_additions INTEGER DEFAULT 0,
    total_deletions INTEGER DEFAULT 0,
    total_changes INTEGER DEFAULT 0,
    first_commit_date TIMESTAMP,
    last_commit_date TIMESTAMP,
    collected_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(project_id, author_email)
);

-- Tabla de estadísticas diarias (agregación)
CREATE TABLE IF NOT EXISTS gitlab_daily_stats (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    branch_name VARCHAR(255),
    author_email VARCHAR(255),
    stat_date DATE NOT NULL,
    commits_count INTEGER DEFAULT 0,
    additions INTEGER DEFAULT 0,
    deletions INTEGER DEFAULT 0,
    total_changes INTEGER DEFAULT 0,
    estimated_hours DECIMAL(10,2) DEFAULT 0,
    collected_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(project_id, branch_name, author_email, stat_date)
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_commits_project_id ON gitlab_commits(project_id);
CREATE INDEX idx_commits_author_email ON gitlab_commits(author_email);
CREATE INDEX idx_commits_committed_date ON gitlab_commits(committed_date);
CREATE INDEX idx_commits_branch ON gitlab_commits(branch_name);
CREATE INDEX idx_contributors_project_id ON gitlab_contributors(project_id);
CREATE INDEX idx_daily_stats_date ON gitlab_daily_stats(stat_date);
CREATE INDEX idx_daily_stats_project ON gitlab_daily_stats(project_id);

-- Vista para análisis de actividad por autor
CREATE OR REPLACE VIEW vw_author_activity AS
SELECT 
    c.project_id,
    p.project_name,
    c.author_name,
    c.author_email,
    COUNT(DISTINCT c.commit_id) as total_commits,
    COUNT(DISTINCT c.branch_name) as branches_worked,
    SUM(c.total_changes) as total_lines_changed,
    MIN(c.committed_date) as first_commit,
    MAX(c.committed_date) as last_commit,
    ROUND(COUNT(DISTINCT c.commit_id) * 0.5, 2) as estimated_hours
FROM gitlab_commits c
LEFT JOIN gitlab_projects p ON c.project_id = p.project_id
GROUP BY c.project_id, p.project_name, c.author_name, c.author_email;

-- Vista para actividad por proyecto y rama
CREATE OR REPLACE VIEW vw_branch_activity AS
SELECT 
    c.project_id,
    p.project_name,
    c.branch_name,
    COUNT(DISTINCT c.commit_id) as total_commits,
    COUNT(DISTINCT c.author_email) as unique_authors,
    SUM(c.additions) as total_additions,
    SUM(c.deletions) as total_deletions,
    MIN(c.committed_date) as first_commit_date,
    MAX(c.committed_date) as last_commit_date
FROM gitlab_commits c
LEFT JOIN gitlab_projects p ON c.project_id = p.project_id
GROUP BY c.project_id, p.project_name, c.branch_name;
