-- sequence_fix.sql
-- Run this after schema + seed_master_data + seed_transaction_data
-- to synchronize PostgreSQL sequences with current max IDs


SELECT setval('patients_patient_id_seq', COALESCE((SELECT MAX(patient_id) FROM Patients), 1));
SELECT setval('patient_accounts_account_id_seq', COALESCE((SELECT MAX(account_id) FROM Patient_Accounts), 1));
SELECT setval('specialties_specialty_id_seq', COALESCE((SELECT MAX(specialty_id) FROM Specialties), 1));
SELECT setval('languages_language_id_seq', COALESCE((SELECT MAX(language_id) FROM Languages), 1));
SELECT setval('doctors_doctor_id_seq', COALESCE((SELECT MAX(doctor_id) FROM Doctors), 1));
SELECT setval('time_slots_slot_id_seq', COALESCE((SELECT MAX(slot_id) FROM Time_Slots), 1));
SELECT setval('appointments_appointment_id_seq', COALESCE((SELECT MAX(appointment_id) FROM Appointments), 1));
SELECT setval('consultations_consultation_id_seq', COALESCE((SELECT MAX(consultation_id) FROM Consultations), 1));