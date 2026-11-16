-- V2: Create delivery agent table
CREATE TABLE delivery_agent (
    agent_id UUID PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    agency_id UUID REFERENCES agency(agency_id)
);

