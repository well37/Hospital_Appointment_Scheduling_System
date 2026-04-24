-- INDEX 1: Speed up slot lookups by doctor and date
CREATE INDEX idx_timeslots_doctor_start ON Time_Slots(doctor_id, slot_start);

-- INDEX 2: Speed up doctor-specialty joins
CREATE INDEX idx_doctor_specialty_doctor ON Doctor_Specialty(doctor_id);
CREATE INDEX idx_doctor_specialty_spec   ON Doctor_Specialty(specialty_id);

-- INDEX 3: Speed up doctor-language joins
CREATE INDEX idx_doctor_language_doctor  ON Doctor_Language(doctor_id);

-- Show the query plan BEFORE and AFTER indexing (put in report)
EXPLAIN ANALYZE
SELECT t.slot_id, t.slot_start
FROM Time_Slots t
WHERE t.doctor_id = 1 AND t.slot_start > NOW();