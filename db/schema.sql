-- Postgres DDL generated from db/schema.rb

CREATE TABLE daily_metrics (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    date_logged DATE,
    calories_consumed INTEGER,
    protein_consumed INTEGER,
    steps INTEGER,
    weight FLOAT,
    raw_message_content TEXT,
    compliant BOOLEAN,
    ai_parsed_json JSONB,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    user_dietary_plan_id BIGINT
);

CREATE INDEX index_daily_metrics_on_user_dietary_plan_id ON daily_metrics (user_dietary_plan_id);
CREATE INDEX index_daily_metrics_on_user_id ON daily_metrics (user_id);

CREATE TABLE dietary_plans (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    calories_target INTEGER,
    protein_target INTEGER,
    notes TEXT
);

CREATE TABLE exercises (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    video_link VARCHAR(255),
    muscle_group VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

CREATE TABLE programs (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    duration_weeks INTEGER,
    description TEXT,
    user_id BIGINT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    google_sheet_link VARCHAR(255)
);

CREATE INDEX index_programs_on_user_id ON programs (user_id);

CREATE TABLE routine_exercises (
    id BIGSERIAL PRIMARY KEY,
    routine_id BIGINT NOT NULL,
    exercise_id BIGINT NOT NULL,
    sets INTEGER,
    reps VARCHAR(255),
    rir VARCHAR(255),
    rest_seconds INTEGER,
    order_index INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    day_number INTEGER,
    day_name VARCHAR(255),
    warmup BOOLEAN,
    load VARCHAR(255),
    sub_option INTEGER,
    instructions TEXT
);

CREATE INDEX index_routine_exercises_on_exercise_id ON routine_exercises (exercise_id);
CREATE INDEX index_routine_exercises_on_routine_id ON routine_exercises (routine_id);

CREATE TABLE routines (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    user_id BIGINT,
    is_template BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    program_id BIGINT,
    duration_weeks INTEGER
);

CREATE INDEX index_routines_on_program_id ON routines (program_id);
CREATE INDEX index_routines_on_user_id ON routines (user_id);

CREATE TABLE user_dietary_plans (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    calories_target INTEGER,
    protein_target INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    dietary_plan_id BIGINT,
    start_date DATE,
    end_date DATE,
    active BOOLEAN DEFAULT TRUE
);

CREATE INDEX index_user_dietary_plans_on_dietary_plan_id ON user_dietary_plans (dietary_plan_id);
CREATE INDEX index_user_dietary_plans_on_user_id ON user_dietary_plans (user_id);

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL DEFAULT '',
    encrypted_password VARCHAR(255) NOT NULL DEFAULT '',
    reset_password_token VARCHAR(255),
    reset_password_sent_at TIMESTAMP WITHOUT TIME ZONE,
    remember_created_at TIMESTAMP WITHOUT TIME ZONE,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone VARCHAR(255),
    status INTEGER DEFAULT 0,
    plan_tier INTEGER,
    discarded_at TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    category INTEGER
);

CREATE INDEX index_users_on_discarded_at ON users (discarded_at);
CREATE UNIQUE INDEX index_users_on_email ON users (email);
CREATE UNIQUE INDEX index_users_on_reset_password_token ON users (reset_password_token);

ALTER TABLE daily_metrics ADD CONSTRAINT fk_daily_metrics_user_dietary_plans FOREIGN KEY (user_dietary_plan_id) REFERENCES user_dietary_plans(id);
ALTER TABLE daily_metrics ADD CONSTRAINT fk_daily_metrics_users FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE programs ADD CONSTRAINT fk_programs_users FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE routine_exercises ADD CONSTRAINT fk_routine_exercises_exercises FOREIGN KEY (exercise_id) REFERENCES exercises(id);
ALTER TABLE routine_exercises ADD CONSTRAINT fk_routine_exercises_routines FOREIGN KEY (routine_id) REFERENCES routines(id);
ALTER TABLE routines ADD CONSTRAINT fk_routines_programs FOREIGN KEY (program_id) REFERENCES programs(id);
ALTER TABLE routines ADD CONSTRAINT fk_routines_users FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE user_dietary_plans ADD CONSTRAINT fk_user_dietary_plans_dietary_plans FOREIGN KEY (dietary_plan_id) REFERENCES dietary_plans(id);
ALTER TABLE user_dietary_plans ADD CONSTRAINT fk_user_dietary_plans_users FOREIGN KEY (user_id) REFERENCES users(id);
