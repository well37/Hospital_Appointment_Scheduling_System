
-- SEED: MASTER DATA (Person A)
-- Specialties, Languages, Doctors, Junction tables, Time_Slots


--SPECIALTIES (10 realistic hospital specialties)
INSERT INTO Specialties (specialty_name) VALUES
  ('Cardiology'),
  ('Dermatology'),
  ('Gynecology'),
  ('Orthopedics'),
  ('Neurology'),
  ('Pediatrics'),
  ('Psychiatry'),
  ('Ophthalmology'),
  ('Gastroenterology'),
  ('General Medicine');
-- IDs will be 1-10 in this order

--LANGUAGES
INSERT INTO Languages (language_name) VALUES
  ('English'),
  ('French'),
  ('Arabic'),
  ('Japanese'),
  ('Mandarin');
--IDs: 1=English, 2=French, 3=Arabic, 4= Japanese, 5=Mandarin

--DOCTORS (12 Doctors)
INSERT INTO Doctors (first_name, last_name, phone, email) VALUES
  ('Sophie', 'Martin', '0601010101', 'sophie.martin@hospital.com'),  -- 1
  ('Julien', 'Moreau', '0602020202', 'julien.moreau@hospital.com'),  -- 2
  ('Claire', 'Dupont', '0603030303', 'claire.dupont@hospital.com'),  -- 3
  ('Ahmed', 'Bensaid', '0604040404', 'ahmed.bensaid@hospital.com'), -- 4
  ('Marie', 'Lefebvre', '0605050505', 'marie.lefebvre@hospital.com'), -- 5
  ('Pierre', 'Renault', '0606060606', 'pierre.renault@hospital.com'), -- 6
  ('Laura', 'Schmidt', '0607070707', 'laura.schmidt@hospital.com'), -- 7
  ('David', 'Chen', '0608080808', 'david.chen@hospital.com'), -- 8
  ('Fatima', 'El Amri', '0609090909', 'fatima.elamri@hospital.com'), -- 9
  ('Thomas', 'Bernard', '0610101010', 'thomas.bernard@hospital.com'), -- 10
  ('Eren', 'Yager', '0611111111', 'eren.yager@hospital.com'), -- 11
  ('Gojo', 'Satoru', '0612121212', 'gojosatoru@hospital.com'); -- 12

-- DOCTOR_SPECIALTY
-- Each doctor has 1-2 specialties
INSERT INTO Doctor_Specialty (doctor_id, specialty_id) VALUES
  (1,1), -- Sophie Martin -> Cardiology
  (2,2), -- Julien Moreau -> Dermatology
  (3,3), -- Claire Dupont -> Gynecology
  (4,4), -- Ahmed Bensaid -> Orthopedics
  (5,5), -- Marie Lefebvre -> Neurology
  (6,1), -- Pierre Renault -> Cardiology
  (6,10), -- Pierre Renault -> General Medicine (2 specialties)
  (7,6), -- Laura Schmidt -> Pediatrics
  (8,5), -- David Chen -> Neurology
  (8,9), -- David Chen -> Gastroenterology (2 specialties)
  (9,7), -- Fatima El Amri -> Psychiatry
  (10,8), -- Thomas Bernard -> Ophthalmology
  (11,4), -- Eren Yager -> Orthopedics
  (12,6), -- Gojo Satoru -> Pediatrics
  (12,10); -- Gojo Satoru -> General Medicine

-- DOCTOR_LANGUAGE
INSERT INTO Doctor_Language (doctor_id, language_id) VALUES
  (1,1), (1,2),              -- Sophie: English, French
  (2,1), (2,2),              -- Julien: English, French
  (3,1), (3,2),              -- Claire: English, French
  (4,1), (4,2), (4,3),       -- Ahmed: English, French, Arabic
  (5,1), (5,2),              -- Marie: English, French
  (6,1), (6,2),              -- Pierre: English, French
  (7,1), (7,4),              -- Laura: English, Japanese
  (8,1), (8,5),              -- David: English, Mandarin
  (9,1), (9,2), (9,3),       -- Fatima: English, French, Arabic
  (10,1), (10,2),            -- Thomas: English, French
  (11,1), (11,4),            -- Eren: English, Japanese
  (12,1), (12,4);            -- Gojo: English, Japanese

-- Time_SLOTS
-- Generate realistic slots for the next 2 weeks (manual for clarity)
-- Format: doctor_id, slot_start, slot_end
-- Each slot = 30 minutes

INSERT INTO Time_Slots (doctor_id, slot_start, slot_end) VALUES
-- Dr. Sophie Martin (1) - Cardiology
   (1, '2026-05-04 08:00', '2026-05-04 08:30'),
   (1, '2026-05-04 08:30', '2026-05-04 09:00'),
   (1, '2026-05-04 09:00', '2026-05-04 09:30'),
   (1, '2026-05-05 10:00', '2026-05-05 10:30'),
   (1, '2026-05-05 10:30', '2026-05-05 11:00'),
   (1, '2026-05-06 14:00', '2026-05-06 14:30'),
   (1, '2026-05-06 14:30', '2026-05-06 15:00'),

-- Dr. Julien Moreau (2) - Dermatology
   (2, '2026-05-04 09:00', '2026-05-04 09:30'),
   (2, '2026-05-04 09:30', '2026-05-04 10:00'),
   (2, '2026-05-05 08:30', '2026-05-05 09:00'),
   (2, '2026-05-05 11:00', '2026-05-05 11:30'),
   (2, '2026-05-07 14:00', '2026-05-07 14:30'),
   (2, '2026-05-07 15:00', '2026-05-07 15:30'),

-- Dr. Claire Dupont (3) - Gynecology
   (3, '2026-05-04 11:00', '2026-05-04 11:30'),
   (3, '2026-05-04 11:30', '2026-05-04 12:00'),
   (3, '2026-05-06 09:00', '2026-05-06 09:30'),
   (3, '2026-05-06 09:30', '2026-05-06 10:00'),
   (3, '2026-05-08 13:00', '2026-05-08 13:30'),
   
-- Dr. Ahmed Bensaid (4) - Orthopedics
   (4, '2026-05-04 08:00', '2026-05-04 08:30'),
   (4, '2026-05-04 13:30', '2026-05-04 14:00'),
   (4, '2026-05-05 08:00', '2026-05-05 08:30'),
   (4, '2026-05-07 10:00', '2026-05-07 10:30'),
   (4, '2026-05-08 09:00', '2026-05-08 09:30'),

-- Dr. Marie Lefebvre (5) - Neurology
   (5, '2026-05-04 10:00', '2026-05-04 10:30'),
   (5, '2026-05-05 14:00', '2026-05-05 14:30'),
   (5, '2026-05-06 10:00', '2026-05-06 10:30'),
   (5, '2026-05-08 11:00', '2026-05-08 11:30'),
   
-- Dr. Pierre Renault (6) - Cardiology + General
   (6, '2026-05-04 09:00', '2026-05-04 09:30'),
   (6, '2026-05-04 15:00', '2026-05-04 15:30'),
   (6, '2026-05-05 09:00', '2026-05-05 09:30'),
   (6, '2026-05-07 08:30', '2026-05-07 09:00'),
   (6, '2026-05-07 13:00', '2026-05-07 13:30'),

-- Dr. Laura Schmidt (7) - Pediatrics
   (7, '2026-05-04 08:30', '2026-05-04 09:00'),
   (7, '2026-05-05 10:30', '2026-05-05 11:00'),
   (7, '2026-05-06 08:00', '2026-05-06 08:30'),
   (7, '2026-05-08 14:00', '2026-05-08 14:30'),		

-- Dr. David Chen (8) - Neurology + Gastroenterology
   (8, '2026-05-04 11:30', '2026-05-04 12:00'),
   (8, '2026-05-05 08:30', '2026-05-05 09:00'),
   (8, '2026-05-06 15:00', '2026-05-06 15:30'),
   (8, '2026-05-07 09:00', '2026-05-07 09:30'),

-- Dr. Fatima El Amri (9) - Psychiatry
   (9, '2026-05-04 10:00', '2026-05-04 10:30'),
   (9, '2026-05-05 10:00', '2026-05-05 10:30'),
   (9, '2026-05-06 11:00', '2026-05-06 11:30'),
   (9, '2026-05-07 14:30', '2026-05-07 15:00'),
   (9, '2026-05-08 10:00', '2026-05-08 10:30'),

-- Dr. Thomas Bernard (10) - Ophthalmology
  (10, '2026-05-04 08:00', '2026-05-04 08:30'),
  (10, '2026-05-05 09:30', '2026-05-05 10:00'),
  (10, '2026-05-06 13:00', '2026-05-06 13:30'),
  (10, '2026-05-08 08:30', '2026-05-08 09:00'),   

-- Dr. Eren Yager (11) - Orthopedics
  (11, '2026-05-04 09:30', '2026-05-04 10:00'),
  (11, '2026-05-05 11:30', '2026-05-05 12:00'),
  (11, '2026-05-07 10:30', '2026-05-07 11:00'),
  (11, '2026-05-08 15:00', '2026-05-08 15:30'),

-- Dr. Gojo Satoru (12) - Pediatrics + General
  (12, '2026-05-04 14:00', '2026-05-04 14:30'),
  (12, '2026-05-05 08:00', '2026-05-05 08:30'),
  (12, '2026-05-06 10:30', '2026-05-06 11:00'),
  (12, '2026-05-07 11:30', '2026-05-07 12:00'),
  (12, '2026-05-08 13:30', '2026-05-08 14:00');

   