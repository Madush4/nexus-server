-- V1: Create initial manufacturer and agency tables
CREATE TABLE manufacturer (
    manufacturer_id UUID PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE agency (
    agency_id UUID PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

