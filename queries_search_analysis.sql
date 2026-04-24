-- QUERIES: SEARCH & ANALYSIS


-- Q1: List all specialties alphabetically
SELECT specialty_name
FROM Specialties
ORDER BY specialty_name;

-- Q2: List all doctors with their specialty/specialties
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name as doctor_name,
       STRING_AGG(s.specialty_name, ', ' ORDER BY s.specialty_name) AS specialties
FROM Doctors d
JOIN Doctor_Specialty ds ON d.doctor_id = ds.doctor_id
JOIN Specialties s ON ds.specialty_id = s.specialty_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY doctor_name;

-- Q3: Find Doctors by specialty (for instance 'Cardiolody')
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
	   d.email, 
	   d.phone
FROM Doctors d
JOIN Doctor_Specialty ds ON d.doctor_id=ds.doctor_id
JOIN Specialties s ON ds.specialty_id=s.specialty_id
WHERE s.specialty_name='Cardiology'
ORDER BY doctor_name;

-- Q4: Find doctors by spoken language (for instance, doctors speaking japanese)
SELECT d.doctor_id,
       d.first_name || ' '|| d.last_name AS doctor_name,
	   STRING_AGG(s.specialty_name, ', ' ORDER BY s.specialty_name) AS specialties,
	   l.language_name	  
FROM Doctors d
JOIN Doctor_language dl ON d.doctor_id=dl.doctor_id
JOIN Languages l ON dl.language_id=l.language_id
JOIN Doctor_Specialty ds ON d.doctor_id=ds.doctor_id
JOIN Specialties s ON ds.specialty_id=s.specialty_id
WHERE l.language_name='Japanese'
GROUP BY d.doctor_id, d.first_name, d.last_name,l.language_name
ORDER BY doctor_name;

-- Q5: Find all the English-speaking general practitioners
SELECT d.doctor_id,
       d.first_name || ' '|| d.last_name AS doctor_name,
	   s.specialty_name,
	   l.language_name	  
FROM Doctors d
JOIN Doctor_language dl ON d.doctor_id=dl.doctor_id
JOIN Languages l ON dl.language_id=l.language_id
JOIN Doctor_Specialty ds ON d.doctor_id=ds.doctor_id
JOIN Specialties s ON ds.specialty_id=s.specialty_id
WHERE l.language_name='English' AND s.specialty_name='General Medicine' 
ORDER BY doctor_name;

-- Q6: Available time slots for a specific doctor
-- A slot is unvailable if it has an appointment with status 'booked'
-- 'cancelled' -> free slot
-- 'completed' -> past appointment, slot in the past anyway
SELECT t.slot_id,
       t.slot_start,
	   t.slot_end,
	   t.doctor_id,
	   d.first_name || ' ' || d.last_name AS doctor_name
FROM Time_Slots t 
JOIN Doctors d ON t.doctor_id=d.doctor_id
WHERE NOT EXISTS ( 
      SELECT 1
      FROM Appointments a
	  WHERE a.slot_id=t.slot_id AND a.appointment_status='booked')
	  AND d.doctor_id=12
	  AND t.slot_start > NOW()
ORDER BY t.slot_start asc;

-- Temporary test data, just to verify the queries

INSERT INTO Patients (first_name, last_name, date_of_birth, gender, phone, email)
VALUES ('Test', 'Patient', '1990-01-01', 'Male', '0600000000', 'test@test.com');
-- patient_id = 1
-- Book slot_id = 1 (Dr. Sophie Martin, 2026-05-04 08:00)
INSERT INTO Appointments (patient_id, slot_id, appointment_status, booked_by_self)
VALUES (1, 1, 'booked', TRUE);

SELECT t.slot_id,
       t.slot_start,
	   t.slot_end,
	   t.doctor_id,
	   d.first_name || ' ' || d.last_name AS doctor_name
FROM Time_Slots t 
JOIN Doctors d ON t.doctor_id=d.doctor_id
WHERE NOT EXISTS ( 
      SELECT 1
      FROM Appointments a
	  WHERE a.slot_id=t.slot_id AND a.appointment_status='booked')
	  AND d.doctor_id=1
	  AND t.slot_start > NOW()
ORDER BY t.slot_start asc;
-- Slot 1 is gone

UPDATE Appointments SET appointment_status = 'cancelled' WHERE slot_id = 1;
-- We run the availability query again -> slot 1 comes back !

-- We delete the temporary test rows
DELETE FROM Appointments WHERE patient_id = 1;
DELETE FROM Patients WHERE email = 'test@test.com';

-- Q7: Doctor workload - total booked/completed appointments per doctor
SELECT d.first_name || ' ' || d.last_name AS doctor_name,
       STRING_AGG( DISTINCT s.specialty_name, ', ' ORDER BY s.specialty_name) AS specialties,
       COUNT(a.appointment_id) AS total_appointments,
       SUM(CASE WHEN a.appointment_status='completed' THEN 1 ELSE 0 END) AS completed,
	   SUM(CASE WHEN a.appointment_status='booked' THEN 1 ELSE 0 END) AS upcoming,
	   SUM(CASE WHEN a.appointment_status='cancelled' THEN 1 ELSE 0 END) AS cancelled
FROM Doctors d 
LEFT JOIN Doctor_Specialty ds ON d.doctor_id=ds.doctor_id
LEFT JOIN Specialties s ON ds.specialty_id=s.specialty_id
LEFT JOIN Time_Slots t ON  d.doctor_id=t.doctor_id
LEFT JOIN Appointments a ON t.slot_id=a.slot_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY total_appointments DESC;

-- Q8: Specialty demand - which specialties are booked the most
SELECT s.specialty_name,
       COUNT(a.appointment_id) AS total_bookings
FROM Specialties s
JOIN Doctor_Specialty ds ON ds.specialty_id=s.specialty_id
JOIN Time_Slots t ON t.doctor_id=ds.doctor_id
JOIN Appointments a ON a.slot_id=t.slot_id
WHERE a.appointment_status !='cancelled'
GROUP BY s.specialty_name
ORDER BY total_bookings DESC;

-- Q9: Slot occupancy rate per doctor (optimizer demo - uses index on doctor_id)
SELECT d.first_name || ' ' || d.last_name AS doctor_name,
       COUNT(t.slot_id) AS total_slots,
       COUNT(a.appointment_id) AS booked_slots,
       ROUND(100.0 * COUNT(a.appointment_id) / NULLIF(COUNT(t.slot_id), 0),
       1) AS occupancy_pct
FROM Doctors d
JOIN Time_Slots t  ON t.doctor_id = d.doctor_id
LEFT JOIN Appointments a ON a.slot_id = t.slot_id
                        AND a.appointment_status != 'cancelled'
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY occupancy_pct DESC NULLS LAST;

-- Q10: Doctors who have NO appointments yet (LEFT JOIN anti-pattern)
SELECT
    d.first_name || ' ' || d.last_name AS doctor_name
FROM Doctors d
LEFT JOIN Time_Slots t  ON t.doctor_id = d.doctor_id
LEFT JOIN Appointments a ON a.slot_id = t.slot_id
WHERE a.appointment_id IS NULL;

-- Q11: QUERY REWRITER DEMO
-- Original correlated subquery (slow):
--SELECT d.doctor_id, d.last_name
--FROM Doctors d
--WHERE (SELECT COUNT(*) FROM Time_Slots ts WHERE ts.doctor_id = d.doctor_id) > 3;

-- Rewritten as JOIN (faster, same result):
SELECT d.doctor_id, d.last_name
FROM Doctors d
JOIN Time_Slots t ON t.doctor_id = d.doctor_id
GROUP BY d.doctor_id, d.last_name
HAVING COUNT(t.slot_id) > 3;

