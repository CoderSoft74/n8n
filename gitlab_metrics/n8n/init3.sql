-- init.sql
-- Tabla principal para almacenar el contexto de la ejecución diaria
CREATE TABLE IF NOT EXISTS execution_log (
    execution_id SERIAL PRIMARY KEY,
    execution_date DATE NOT NULL DEFAULT CURRENT_DATE,
    start_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    total_projects_scanned INTEGER,
    status VARCHAR(20) CHECK (status IN ('running', 'success', 'error')),
    error_message TEXT
);

-- Tabla de proyectos de GitLab
CREATE TABLE IF NOT EXISTS gitlab_projects (
    project_id SERIAL PRIMARY KEY,
    gitlab_project_id INTEGER NOT NULL,
    project_name VARCHAR(500) NOT NULL,
    path_with_namespace VARCHAR(1000) NOT NULL,
    web_url VARCHAR(1000),
    last_activity_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(gitlab_project_id)
);

-- Tabla de commits por autor
CREATE TABLE IF NOT EXISTS commit_metrics_author (
    metric_id SERIAL PRIMARY KEY,
    execution_id INTEGER REFERENCES execution_log(execution_id),
    project_id INTEGER REFERENCES gitlab_projects(project_id),
    author_name VARCHAR(500) NOT NULL,
    author_email VARCHAR(500),
    commit_count INTEGER NOT NULL,
    metric_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(execution_id, project_id, author_email, metric_date)
);

-- Tabla de commits por rama
CREATE TABLE IF NOT EXISTS commit_metrics_branch (
    metric_id SERIAL PRIMARY KEY,
    execution_id INTEGER REFERENCES execution_log(execution_id),
    project_id INTEGER REFERENCES gitlab_projects(project_id),
    branch_name VARCHAR(500) NOT NULL,
    commit_count INTEGER NOT NULL,
    metric_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(execution_id, project_id, branch_name, metric_date)
);

-- Tabla para líneas de código (estimadas vía estadísticas del repositorio)
CREATE TABLE IF NOT EXISTS code_line_metrics (
    metric_id SERIAL PRIMARY KEY,
    execution_id INTEGER REFERENCES execution_log(execution_id),
    project_id INTEGER REFERENCES gitlab_projects(project_id),
    total_lines INTEGER,
    added_lines INTEGER,
    deleted_lines INTEGER,
    metric_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(execution_id, project_id, metric_date)
);

-- Tabla de frecuencia de commits (por día de la semana y hora)
CREATE TABLE IF NOT EXISTS commit_frequency (
    metric_id SERIAL PRIMARY KEY,
    execution_id INTEGER REFERENCES execution_log(execution_id),
    project_id INTEGER REFERENCES gitlab_projects(project_id),
    week_day INTEGER CHECK (week_day BETWEEN 0 AND 6), -- 0=Sunday
    hour_of_day INTEGER CHECK (hour_of_day BETWEEN 0 AND 23),
    commit_count INTEGER NOT NULL,
    metric_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(execution_id, project_id, week_day, hour_of_day, metric_date)
);


-- execution_log - Hacer columnas NULLables temporalmente
ALTER TABLE execution_log 
ALTER COLUMN end_time DROP NOT NULL,
ALTER COLUMN status DROP NOT NULL;

-- gitlab_projects - Añadir si no existe
ALTER TABLE gitlab_projects 
ADD COLUMN IF NOT EXISTS metric_date DATE,
ADD COLUMN IF NOT EXISTS execution_id INTEGER REFERENCES execution_log(execution_id);

-- commit_metrics_author - Permitir email null
ALTER TABLE commit_metrics_author 
ALTER COLUMN author_email DROP NOT NULL;

-- Índices para mejorar el rendimiento de las consultas de Grafana
CREATE INDEX idx_commit_author_metrics ON commit_metrics_author (project_id, metric_date);
CREATE INDEX idx_commit_branch_metrics ON commit_metrics_branch (project_id, metric_date);
CREATE INDEX idx_code_line_metrics ON code_line_metrics (project_id, metric_date);
CREATE INDEX idx_commit_frequency ON commit_frequency (project_id, metric_date);