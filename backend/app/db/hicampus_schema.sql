-- 1. 기초 마스터 데이터 테이블
CREATE TABLE country (
    iso2 CHAR(2) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE language (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE schools (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    website_url TEXT,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8)
);

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL
);

-- 2. 사용자 관련 테이블
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(100) NOT NULL,
    nationality_iso2 CHAR(2) NOT NULL REFERENCES country(iso2),
    main_language VARCHAR(10) NOT NULL REFERENCES language(code),
    school_id INTEGER REFERENCES schools(id),
    department_id INTEGER REFERENCES departments(id),
    -- 한국 국적('KR')일 경우 자동으로 is_helper true
    is_helper BOOLEAN GENERATED ALWAYS AS (nationality_iso2 = 'KR') STORED,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE
);

-- 3. 매칭 및 채팅 테이블
CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id), -- 유학생
    helper_id INTEGER NOT NULL REFERENCES users(id),  -- 한국인 도우미
    status VARCHAR(20) DEFAULT 'active', -- active, completed, cancelled
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_different_user CHECK (student_id <> helper_id)
);

CREATE TABLE chat_rooms (
    id SERIAL PRIMARY KEY,
    match_id INTEGER REFERENCES matches(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chat_messages (
    id SERIAL PRIMARY KEY,
    room_id INTEGER REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id INTEGER REFERENCES users(id),
    message_content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. 커뮤니티 및 다국어 지원 테이블
CREATE TABLE boards (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    board_id INTEGER REFERENCES boards(id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_translations (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    language_code VARCHAR(10) REFERENCES language(code),
    translated_title VARCHAR(255),
    translated_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. 파일 관리 (다형성 관계)
CREATE TABLE attachments (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL, -- post_id, message_id, user_id 등
    owner_type VARCHAR(50) NOT NULL, -- 'POST', 'MESSAGE', 'PROFILE', 'PLACE'
    file_path TEXT NOT NULL,
    file_name VARCHAR(255),
    file_size INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. 알림 및 지도 정보
CREATE TABLE reminders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(50), -- 'VISA', 'ADMIN', 'SCHOOL'
    title VARCHAR(255) NOT NULL,
    due_date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE places (
    place_id SERIAL PRIMARY KEY,
    api_id VARCHAR(100) UNIQUE, -- 네이버 지도 등 외부 API ID
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE, -- 특정 학교 근처 장소임을 명시
    name_ko VARCHAR(255) NOT NULL,
    name_en VARCHAR(255),
    category VARCHAR(50) NOT NULL,
    address TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    is_official BOOLEAN DEFAULT FALSE, -- 운영자 제공 공식 정보 여부 구분
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    place_id INTEGER NOT NULL REFERENCES places(place_id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. 이메일 인증 코드
CREATE TABLE verification_codes (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    code CHAR(6) NOT NULL,
    expiry_time TIMESTAMP WITH TIME ZONE NOT NULL
);