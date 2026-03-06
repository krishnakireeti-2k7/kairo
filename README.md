Technical Architecture README
Kairo - Medical Symptom Logging & Consultation Support App — System Design Specification (v1)

1. Overview

This document defines the technical architecture, system responsibilities, data model, and AI integration strategy for the Medical Symptom Logging Application.

The application is designed to allow users to record health symptoms over time, analyze patterns, and generate structured summaries that can be shared with healthcare professionals.

The system focuses on improving patient–doctor communication by reducing reliance on memory-based symptom recall.
The architecture prioritizes:

long-term data integrity

structured medical history storage

privacy and security

AI-assisted pattern detection

scalable analytics capabilities

This document exists to:

guide development decisions

provide architectural clarity

prevent ad-hoc system design

ensure long-term maintainability

enable AI tools to understand system structure

2. Core Technology Stack
Frontend

Framework: Flutter

Language: Dart

State Management: Riverpod

Navigation: GoRouter

Local Persistence: Hive / SQLite

PDF Generation: Flutter PDF libraries

The frontend handles:

user interaction

symptom logging

timeline display

summary visualizations

report generation requests

Backend Platform

Platform: Supabase

Supabase provides a PostgreSQL-based backend allowing structured relational data modeling and advanced analytics.

Services Used

Supabase Authentication

PostgreSQL Database

Row Level Security

Supabase Storage

Supabase Edge Functions

Supabase was chosen because:

relational data fits medical logs better

SQL enables advanced analysis

PostgreSQL supports AI extensions

scalable architecture

AI Processing Layer

AI is used for pattern detection and discussion suggestion generation, not diagnosis.

AI features include:

symptom frequency analysis

trend detection

correlation detection

discussion point generation

AI processing will run through Edge Functions to ensure:

API key protection

controlled AI prompt formatting

response validation

3. System Architecture
High-Level Flow
User Logs Symptom
        ↓
Flutter Client
        ↓
Supabase Database
        ↓
Analytics Query Layer
        ↓
AI Pattern Analysis
        ↓
Discussion Suggestions
        ↓
Doctor Report Generation
Component Responsibility Breakdown
Flutter Client

Responsible for:

user authentication

symptom logging UI

timeline rendering

summary dashboards

report export interface

user experience management

Not responsible for:

AI processing logic

database analytics queries

AI API key storage

data validation enforcement

The client acts as a presentation layer.

Supabase PostgreSQL Database

Primary system of record.

Responsibilities:

store structured symptom data

maintain relational links

support analytical queries

enable long-term medical history tracking

Chosen for:

relational structure

time-series query support

analytics capability

AI compatibility

Edge Functions

Acts as the secure processing layer.

Responsibilities:

validate incoming requests

run analytics queries

perform AI calls

sanitize outputs

generate summaries

Edge functions isolate sensitive operations from the client.

Storage Layer

Used for:

generated PDF reports

user-exported medical summaries

Storage ensures that reports can be:

downloaded

shared

archived

4. Data Model (Core System Design)

Medical symptom data is inherently time-series data with relational attributes.

The schema is designed to support:

multiple symptoms per event

contextual triggers

medication interactions

long-term analytics

Users Table

Stores minimal identity information.

Fields:

id

email

created_at

preferences (future)

User table remains intentionally lightweight.

Symptoms Table

Reference table of available symptoms.

Fields:

id

name

category

description

Examples:

headache

nausea

fatigue

stomach pain

Logs Table

Represents a single health event.

Fields:

id

user_id

timestamp

severity

duration

notes

created_at

Severity uses a 0–10 scale for consistent analytics.

Log Symptoms Table

Allows multiple symptoms per log.

Fields:

id

log_id

symptom_id

This structure enables flexible event modeling.

Context Tags Table

Stores environmental or lifestyle triggers.

Fields:

id

name

Examples:

poor sleep

stress

heavy meal

dehydration

intense workout

Log Context Table

Links context triggers to logs.

Fields:

id

log_id

context_id

Allows correlation analysis between triggers and symptoms.

Medications Table

Optional medication tracking.

Fields:

id

user_id

medication_name

dosage

start_date

end_date

Medication tracking allows potential future correlation analysis.

5. AI Pattern Analysis Strategy

The AI layer focuses on pattern recognition rather than diagnosis.

AI assists users in identifying trends they may want to discuss with a healthcare professional.

Pattern Detection Types
Frequency Analysis

Example:

Headaches occurred 9 times in the last 30 days.
Trend Detection

Example:

Fatigue severity has increased over the last 6 weeks.
Correlation Detection

Example:

Headaches appear frequently after poor sleep.
Co-occurrence Detection

Example:

Nausea and headaches appear together in multiple events.
AI Output Design

AI generates discussion prompts, not conclusions.

Example:

You may want to discuss the following with your doctor:

• recurring headaches after poor sleep
• increased fatigue in the last month

This approach avoids medical liability.

6. Analytics Layer

PostgreSQL enables powerful symptom analysis queries.

Examples include:

Symptom Frequency
Count occurrences by symptom
Time-Series Trend
Track severity change over time
Trigger Correlation
Analyze context tags associated with symptoms
Long-Term Pattern Detection
Detect recurring symptom clusters
7. Report Generation System

Users can export structured reports summarizing symptom history.

Report sections include:

summary overview

symptom frequency

timeline history

context triggers

discussion suggestions

Reports are generated as PDF documents suitable for clinical consultation.

8. Privacy and Security Principles

Because the system stores sensitive health data, privacy is a core design principle.

Security strategy includes:

Row Level Security for all database access

authenticated user sessions

encrypted communication

user-controlled data sharing

no third-party data sales

Users maintain full control over their data.

9. Scalability Considerations

The architecture supports long-term growth through:

relational data modeling

scalable PostgreSQL infrastructure

serverless edge functions

modular AI integration

The system avoids premature complexity while enabling future expansion.

10. Observability (Future)

Future improvements may include:

analytics dashboards

AI model monitoring

system performance tracking

error logging

crash reporting

These are intentionally deferred for MVP.

11. Development Philosophy

The architecture prioritizes:

clarity of system responsibilities

structured health data modeling

ethical AI usage

simplicity of deployment

extensibility for future analytics

The system intentionally avoids:

premature microservices

complex infrastructure

unnecessary abstraction

12. Guiding Technical Question

When making engineering decisions, ask:

Does this improve the reliability, clarity, or usefulness of the user's medical history?

If not, reconsider implementation complexity.