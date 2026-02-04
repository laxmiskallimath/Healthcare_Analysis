/* =====================================================
   DATABASE: Healthcare Analytics
   ===================================================== */

/* ---------- Create Database (optional, DB-specific) ---------- */
CREATE OR REPLACE DATABASE healthcare;
USE healthcare;

/* =====================================================
   TABLE CREATION
   ===================================================== */

CREATE OR REPLACE TABLE patients (
    patient_id   INT PRIMARY KEY,
    patient_name VARCHAR(50),
    age           INT,
    gender        VARCHAR(10),
    city          VARCHAR(50)
);

CREATE OR REPLACE TABLE symptoms (
    symptom_id   INT PRIMARY KEY,
    symptom_name VARCHAR(50)
);

CREATE OR REPLACE TABLE diagnoses (
    diagnosis_id   INT PRIMARY KEY,
    diagnosis_name VARCHAR(50)
);

CREATE OR REPLACE TABLE visits (
    visit_id     INT PRIMARY KEY,
    patient_id   INT,
    symptom_id   INT,
    diagnosis_id INT,
    visit_date   DATE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (symptom_id) REFERENCES symptoms(symptom_id),
    FOREIGN KEY (diagnosis_id) REFERENCES diagnoses(diagnosis_id)
);

/* =====================================================
   DATA INSERTION
   ===================================================== */

INSERT INTO patients VALUES
(1, 'John Smith', 45, 'Male', 'Seattle'),
(2, 'Jane Doe', 32, 'Female', 'Miami'),
(3, 'Mike Johnson', 50, 'Male', 'Seattle'),
(4, 'Lisa Jones', 28, 'Female', 'Miami'),
(5, 'David Kim', 60, 'Male', 'Chicago');

INSERT INTO symptoms VALUES
(1, 'Fever'),
(2, 'Cough'),
(3, 'Difficulty Breathing'),
(4, 'Fatigue'),
(5, 'Headache');

INSERT INTO diagnoses VALUES
(1, 'Common Cold'),
(2, 'Influenza'),
(3, 'Pneumonia'),
(4, 'Bronchitis'),
(5, 'COVID-19');

INSERT INTO visits VALUES
(1, 1, 1, 2, '2022-01-01'),
(2, 2, 2, 1, '2022-01-02'),
(3, 3, 3, 3, '2022-01-02'),
(4, 4, 1, 4, '2022-01-03'),
(5, 5, 2, 5, '2022-01-03'),
(6, 1, 4, 1, '2022-05-13'),
(7, 3, 4, 1, '2022-05-20'),
(8, 3, 2, 1, '2022-05-20'),
(9, 2, 1, 4, '2022-08-19'),
(10, 1, 2, 5, '2022-12-01');

/* =====================================================
   ANALYTICAL QUERIES
   ===================================================== */

-- 1. Patients diagnosed with COVID-19
SELECT DISTINCT
    p.patient_name
FROM patients p
JOIN visits v      ON p.patient_id = v.patient_id
JOIN diagnoses d   ON v.diagnosis_id = d.diagnosis_id
WHERE d.diagnosis_name = 'COVID-19';


-- 2. Number of visits per patient (descending order)
SELECT
    p.patient_name,
    COUNT(v.visit_id) AS number_of_visits
FROM patients p
JOIN visits v ON p.patient_id = v.patient_id
GROUP BY p.patient_name
ORDER BY number_of_visits DESC;


-- 3. Average age of patients diagnosed with Pneumonia
SELECT
    ROUND(AVG(p.age), 0) AS avg_age
FROM patients p
JOIN visits v    ON p.patient_id = v.patient_id
JOIN diagnoses d ON v.diagnosis_id = d.diagnosis_id
WHERE d.diagnosis_name = 'Pneumonia';


-- 4. Top 3 most common symptoms
WITH symptom_counts AS (
    SELECT
        s.symptom_name,
        COUNT(*) AS symptom_count
    FROM symptoms s
    JOIN visits v ON s.symptom_id = v.symptom_id
    GROUP BY s.symptom_name
)
SELECT
    symptom_name
FROM (
    SELECT
        symptom_name,
        DENSE_RANK() OVER (ORDER BY symptom_count DESC) AS rankk
    FROM symptom_counts
)
WHERE rankk <= 3;


-- 5. Patient with the highest number of different symptoms
WITH patient_symptoms AS (
    SELECT
        p.patient_name,
        COUNT(DISTINCT v.symptom_id) AS symptom_count
    FROM patients p
    JOIN visits v ON p.patient_id = v.patient_id
    GROUP BY p.patient_name
)
SELECT
    patient_name
FROM (
    SELECT
        patient_name,
        DENSE_RANK() OVER (ORDER BY symptom_count DESC) AS rankk
    FROM patient_symptoms
)
WHERE rankk = 1;


-- 6. Percentage of patients diagnosed with COVID-19
WITH covid_patients AS (
    SELECT COUNT(DISTINCT v.patient_id) AS covid_count
    FROM visits v
    JOIN diagnoses d ON v.diagnosis_id = d.diagnosis_id
    WHERE d.diagnosis_name = 'COVID-19'
),
total_patients AS (
    SELECT COUNT(*) AS total_count FROM patients
)
SELECT
    (covid_count * 100.0) / total_count AS covid_patients_percentage
FROM covid_patients, total_patients;


-- 7. Top 5 cities with the highest number of visits
SELECT
    city,
    total_visits
FROM (
    SELECT
        p.city,
        COUNT(v.visit_id) AS total_visits,
        DENSE_RANK() OVER (ORDER BY COUNT(v.visit_id) DESC) AS rankk
    FROM patients p
    JOIN visits v ON p.patient_id = v.patient_id
    GROUP BY p.city
)
WHERE rankk <= 5;


-- 8. Patient with the highest number of visits in a single day
SELECT
    patient_name,
    visit_date
FROM (
    SELECT
        p.patient_name,
        v.visit_date,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rankk
    FROM patients p
    JOIN visits v ON p.patient_id = v.patient_id
    GROUP BY p.patient_name, v.visit_date
)
WHERE rankk = 1;


-- 9. Average age per diagnosis (descending order)
SELECT
    d.diagnosis_name,
    ROUND(AVG(p.age), 0) AS avg_age
FROM patients p
JOIN visits v    ON p.patient_id = v.patient_id
JOIN diagnoses d ON v.diagnosis_id = d.diagnosis_id
GROUP BY d.diagnosis_name
ORDER BY avg_age DESC;


-- 10. Cumulative count of visits over time
WITH daily_visits AS (
    SELECT
        visit_date,
        COUNT(*) AS visits
    FROM visits
    GROUP BY visit_date
)
SELECT
    visit_date,
    visits,
    SUM(visits) OVER (
        ORDER BY visit_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_visits
FROM daily_visits
ORDER BY visit_date;
