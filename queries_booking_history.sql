-- QUERIES: BOOKING / HISTORY / APPOINTMENT MANAGEMENT

-- Upcoming appointments for a specific patient
-- Example: patient_id = 2

SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.first_name || ' ' || d.last_name AS doctor_name,
    ts.slot_start,
    ts.slot_end,
    a.appointment_status,
    c.visit_stage,
    c.consultation_mode,
    c.purpose,
    c.urgency,
    c.reason_for_visit
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Time_Slots ts ON a.slot_id = ts.slot_id
JOIN Doctors d ON ts.doctor_id = d.doctor_id
JOIN Consultations c ON a.appointment_id = c.appointment_id
WHERE a.patient_id = 2
  AND a.appointment_status = 'booked'
ORDER BY ts.slot_start;

-- Past/completed appointments for a specific patient
-- Example: patient_id = 2

SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.first_name || ' ' || d.last_name AS doctor_name,
    ts.slot_start,
    ts.slot_end,
    a.appointment_status,
    c.visit_stage,
    c.consultation_mode,
    c.purpose,
    c.reason_for_visit
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Time_Slots ts ON a.slot_id = ts.slot_id
JOIN Doctors d ON ts.doctor_id = d.doctor_id
JOIN Consultations c ON a.appointment_id = c.appointment_id
WHERE a.patient_id = 2
  AND a.appointment_status = 'completed'
ORDER BY ts.slot_start;

-- Cancelled appointments for a specific patient
-- Example: patient_id = 3

SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.first_name || ' ' || d.last_name AS doctor_name,
    ts.slot_start,
    ts.slot_end,
    a.appointment_status,
    c.consultation_mode,
    c.purpose,
    c.reason_for_visit
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Time_Slots ts ON a.slot_id = ts.slot_id
JOIN Doctors d ON ts.doctor_id = d.doctor_id
JOIN Consultations c ON a.appointment_id = c.appointment_id
WHERE a.patient_id = 3
  AND a.appointment_status = 'cancelled'
ORDER BY ts.slot_start;

-- Appointment detail query
-- Example: appointment_id = 3

SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.first_name || ' ' || d.last_name AS doctor_name,
    ts.slot_start,
    ts.slot_end,
    a.appointment_status,
    a.booked_by_self,
    a.booker_relationship,
    a.booking_created_at,
    a.notes,
    c.visit_stage,
    c.consultation_mode,
    c.purpose,
    c.urgency,
    c.reason_for_visit,
    c.referral_required,
    c.referral_provided,
    c.referring_doctor_name
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Time_Slots ts ON a.slot_id = ts.slot_id
JOIN Doctors d ON ts.doctor_id = d.doctor_id
JOIN Consultations c ON a.appointment_id = c.appointment_id
WHERE a.appointment_id = 3;

-- Available slots for a specific doctor
-- Only slots with no current BOOKED appointment are shown
-- Example: doctor_id = 1

SELECT
    ts.slot_id,
    ts.slot_start,
    ts.slot_end
FROM Time_Slots ts
LEFT JOIN Appointments a 
      ON ts.slot_id = a.slot_id
     AND a.appointment_status = 'booked'
WHERE ts.doctor_id = 1
  AND a.appointment_id IS NULL
ORDER BY ts.slot_start;


-- Cancel an appointment
-- Example : cancel appointment_id = 1

UPDATE Appointments
SET appointment_status = 'cancelled'
WHERE appointment_id = 1
  AND appointment_status = 'booked';

-- Reschedule an appointment
-- Example : move appointment_id = 1 to slot_id = 6

UPDATE Appointments
SET slot_id = 6
WHERE appointment_id = 1
  AND appointment_status = 'booked';

-- First visit / follow_up suggestion
-- Logic:
-- If the patient already had any booked/completed appointment
-- with the same doctor before, suggest 'follow_up'
-- Otherwise suggest 'first_visit'
--
-- Example:
-- patient_id = 2, doctor_id = 1

SELECT 
    CASE 
        WHEN COUNT (*) > 0 THEN 'follow_up'
        ELSE 'first_visit'
    END AS suggested_visit_stage
FROM Appointments a 
JOIN Time_Slots ts ON a.slot_id = ts.slot_id
WHERE a.patient_id = 2
  AND ts.doctor_id = 1
  AND a.appointment_status IN ('booked', 'completed');

-- Patient visit frequency
-- Number of appointments per patient

SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    COUNT(a.appointment_id) AS total_appointments
FROM Patients p
LEFT JOIN Appointments a ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_appointments DESC, p.patient_id;

-- Appointment count by status

SELECT
     appointment_status,
     COUNT(*) AS total_count
FROM Appointments
GROUP BY appointment_status
ORDER BY appointment_status;

-- Patients who booked through someone else

SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    a.booked_by_self,
    a.booker_relationship,
    d.first_name || ' ' || d.last_name AS doctor_name,
    ts.slot_start
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Time_Slots ts ON a.slot_id = ts.slot_id
JOIN Doctors d ON ts.doctor_id = d.doctor_id
WHERE a.booked_by_self = FALSE
ORDER BY ts.slot_start;

-- Upcoming appointments for all patients

SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.first_name || ' ' || d.last_name AS doctor_name,
    ts.slot_start,
    ts.slot_end,
    a.appointment_status
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Time_Slots ts ON a.slot_id = ts.slot_id
JOIN Doctors d ON ts.doctor_id = d.doctor_id
WHERE a.appointment_status = 'booked'
ORDER BY ts.slot_start;

-- Consultation summary by purpose

SELECT
    c.purpose,
    COUNT(*) AS total_consultations
FROM Consultations c
GROUP BY c.purpose
ORDER BY total_consultations DESC, c.purpose;

-- Patients with no appointments
-- Useful for testing first-time booking flow

SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name
FROM Patients p
LEFT JOIN Appointments a ON p.patient_id = a.patient_id
WHERE a.appointment_id IS NULL
ORDER BY p.patient_id;