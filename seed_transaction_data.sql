-- SEED: TRANSACTION DATA
-- Patients, Patient_Accounts, Appointments, Consultations

-- PATIENTS
-- Fictional character-inspired sample data

INSERT INTO Patients (
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    phone,
    email,
    address,
    birth_country,
    preferred_language
) VALUES
    (1, 'Anya', 'Forger', '2004-05-12', 'Female', '0700000001', 'anya.forger@example.com', '12 Rue de Paris, Paris', 'France', 'French'),
    (2, 'Loid', 'Forger', '1998-09-25', 'Male', '0700000002', 'loid.forger@example.com', '34 Avenue Victor Hugo, Lyon', 'Germany', 'English'),
    (3, 'Yor', 'Briar', '1995-02-18', 'Female', '0700000003', 'yor.briar@example.com', '56 Boulevard Saint-Germain, Marseille', 'Belgium', 'French'),
    (4, 'Marin', 'Kitagawa', '1999-11-03', 'Female', '0700000004', 'marin.kitagawa@example.com', '78 Rue Lafayette, Paris', 'Japan', 'Japanese'),
    (5, 'Jinx', 'Powder', '2000-07-14', 'Female', '0700000005', 'jinx.powder@example.com', '90 Rue Oberkampf, Paris', 'United Kingdom', 'English');


-- PATIENT ACCOUNTS

INSERT INTO Patient_Accounts (
    account_id,
    patient_id,
    username,
    password_hash,
    account_status,
    created_at,
    last_login
) VALUES
    (1, 1, 'anya_f', 'hashed_pw_anya', 'active', '2026-04-18 09:30:00', '2026-04-20 08:10:00'),
    (2, 2, 'loid_f', 'hashed_pw_loid', 'active', '2026-04-18 10:00:00', '2026-04-20 08:25:00'),
    (3, 3, 'yor_b', 'hashed_pw_yor', 'active', '2026-04-18 10:30:00', '2026-04-19 21:15:00'),
    (4, 4, 'marin_k', 'hashed_pw_marin', 'active', '2026-04-19 11:00:00', '2026-04-20 07:50:00'),
    (5, 5, 'jinx_p', 'hashed_pw_jinx', 'active', '2026-04-19 11:30:00', NULL);


-- APPOINTMENTS
-- IMPORTANT:
-- slot_id values below assume schema.sql was run first and then
-- seed_master_data.sql was inserted into an empty database.
--
-- Slot reference used here:
-- Doctor 1 Sophie Martin:
--   slot_id 1 = 2026-05-04 08:00
--   slot_id 4 = 2026-05-05 10:00
-- Doctor 2 Julien Moreau:
--   slot_id 12 = 2026-05-07 14:00
-- Doctor 9 Fatima El Amri:
--   slot_id 43 = 2026-05-06 11:00

INSERT INTO Appointments (
    appointment_id,
    patient_id,
    slot_id,
    appointment_status,
    booked_by_self,
    booker_relationship,
    booking_created_at,
    notes
) VALUES
    -- Patient 1: upcoming booked appointment with Cardiology
    (1, 1, 4, 'booked', TRUE, NULL, '2026-04-20 08:30:00', 'Requested morning consultation'),

    -- Patient 2: previous completed appointment with same doctor
    -- used for first_visit / follow_up suggestion logic
    (2, 2, 1, 'completed', TRUE, NULL, '2026-04-18 14:00:00', 'Initial cardiology consultation completed'),

    -- Patient 2: new booked appointment with the same doctor
    -- should naturally be suggested as follow_up
    (3, 2, 5, 'booked', TRUE, NULL, '2026-04-20 09:00:00', 'Follow-up appointment requested'),

    -- Patient 3: cancelled dermatology appointment
    (4, 3, 12, 'cancelled', TRUE, NULL, '2026-04-19 16:10:00', 'Cancelled by patient'),

    -- Patient 4: booked psychiatry appointment
    (5, 4, 43, 'booked', FALSE, 'spouse', '2026-04-20 10:15:00', 'Booked by spouse for consultation');


-- CONSULTATIONS
-- One consultation per appointment

INSERT INTO Consultations (
    consultation_id,
    appointment_id,
    visit_stage,
    consultation_mode,
    purpose,
    urgency,
    reason_for_visit,
    referral_required,
    referral_provided,
    referring_doctor_name
) VALUES
    -- Appointment 1: Doctor 1 Sophie Martin - Cardiology
    (1, 1, 'first_visit', 'in_person', 'consultation', 'routine',
     'Chest pain during exercise', FALSE, FALSE, NULL),

    -- Appointment 2: Doctor 1 Sophie Martin - Cardiology
    (2, 2, 'first_visit', 'in_person', 'consultation', 'routine',
     'Palpitations and irregular heartbeat', FALSE, FALSE, NULL),

    -- Appointment 3: Doctor 1 Sophie Martin - Cardiology
    (3, 3, 'follow_up', 'in_person', 'test_review', 'routine',
     'Follow-up after initial cardiac examination', TRUE, TRUE, 'Sophie Martin'),

    -- Appointment 4: Doctor 2 Julien Moreau - Dermatology
    (4, 4, 'first_visit', 'online', 'consultation', 'routine',
     'Persistent skin rash on arms', FALSE, FALSE, NULL),

    -- Appointment 5: Doctor 9 Fatima El Amri - Psychiatry
    (5, 5, 'first_visit', 'in_person', 'consultation', 'routine',
     'Anxiety and sleep difficulties', FALSE, FALSE, NULL);