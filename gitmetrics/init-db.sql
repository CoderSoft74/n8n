CREATE SCHEMA IF NOT EXISTS gitmetrics;

CREATE TABLE gitmetrics.projects (
    id SERIAL PRIMARY KEY,
    gitlab_id INTEGER NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    path_with_namespace VARCHAR(255) NOT NULL,
    web_url VARCHAR(500),
    created_at TIMESTAMP,
    last_activity_at TIMESTAMP
);

CREATE TABLE gitmetrics.users (
    id SERIAL PRIMARY KEY,
    gitlab_id INTEGER NOT NULL UNIQUE,
    username VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    state VARCHAR(50),
    web_url VARCHAR(500)
);

CREATE TABLE gitmetrics.project_members (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES gitmetrics.projects (id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES gitmetrics.users (id) ON DELETE CASCADE,
    access_level INTEGER,
    created_at TIMESTAMP,
    UNIQUE (project_id, user_id)
);

CREATE TABLE gitmetrics.commits (
    id SERIAL PRIMARY KEY,
    gitlab_id VARCHAR(100) NOT NULL,
    project_id INTEGER NOT NULL REFERENCES gitmetrics.projects (id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES gitmetrics.users (id),
    author_name VARCHAR(255),
    author_email VARCHAR(255),
    title VARCHAR(500),
    message TEXT,
    committed_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (gitlab_id, project_id)
);

CREATE TABLE gitmetrics.merge_requests (
    id SERIAL PRIMARY KEY,
    gitlab_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL REFERENCES gitmetrics.projects (id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES gitmetrics.users (id),
    title VARCHAR(500),
    state VARCHAR(50),
    source_branch VARCHAR(255),
    target_branch VARCHAR(255),
    created_at TIMESTAMP,
    merged_at TIMESTAMP,
    closed_at TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE (gitlab_id, project_id)
);

-- Tabla de métricas agregadas por día, usuario y proyecto
CREATE TABLE gitmetrics.daily_user_metrics (
    id SERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,
    project_id INTEGER NOT NULL REFERENCES gitmetrics.projects (id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES gitmetrics.users (id) ON DELETE CASCADE,
    commits_count INTEGER NOT NULL DEFAULT 0,
    merge_requests_opened INTEGER NOT NULL DEFAULT 0,
    merge_requests_merged INTEGER NOT NULL DEFAULT 0,
    -- horas aproximadas trabajadas, heurística basada en dispersión de commits
    estimated_hours NUMERIC(5, 2) NOT NULL DEFAULT 0,
    UNIQUE (
        metric_date,
        project_id,
        user_id
    )
);