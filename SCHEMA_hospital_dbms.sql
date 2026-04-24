CREATE TABLE Doctors (
       doctor_id SERIAL PRIMARY KEY,
	   first_name VARCHAR(50) NOT NULL,
	   last_name VARCHAR(50) NOT NULL,
	   phone VARCHAR(20),
	   email VARCHAR(100) UNIQUE
);

CREATE TABLE Patients (
       patient_id SERIAL PRIMARY KEY,
	   first_name VARCHAR(50) NOT NULL,
	   last_name VARCHAR(50) NOT NULL,
	   date_of_birth DATE NOT NULL,
	   gender VARCHAR(20),
	   phone VARCHAR(20),
	   email VARCHAR(100),
	   address VARCHAR(200),
	   birth_country VARCHAR(100),
	   preferred_language VARCHAR(50)
);

CREATE TABLE Patient_Accounts(
       account_id SERIAL PRIMARY KEY,
	   patient_id INT NOT NULL UNIQUE,
	   username VARCHAR(50) NOT NULL UNIQUE,
	   password_hash VARCHAR(255) NOT NULL,
	   account_status VARCHAR(20) DEFAULT 'active',
	   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	   last_login TIMESTAMP,
	   FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE
);

CREATE TABLE Specialties (
       specialty_id SERIAL PRIMARY KEY,
	   specialty_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Doctor_Specialty(
       doctor_id INT NOT NULL,
	   specialty_id INT NOT NULL,
	   PRIMARY KEY (doctor_id, specialty_id),
	   FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id) ON DELETE CASCADE,
	   FOREIGN KEY (specialty_id) REFERENCES Specialties(specialty_id) ON DELETE CASCADE
);

CREATE TABLE Languages (
       language_id SERIAL PRIMARY KEY,
	   language_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Doctor_Language (
       doctor_id INT NOT NULL,
	   language_id INT NOT NULL,
	   PRIMARY KEY (doctor_id, language_id),
	   FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id) ON DELETE CASCADE,
	   FOREIGN KEY (language_id) REFERENCES Languages(language_id) ON DELETE CASCADE
);

CREATE TABLE Time_Slots (
       slot_id SERIAL PRIMARY KEY,
	   doctor_id INT NOT NULL,
	   slot_start TIMESTAMP NOT NULL,
	   slot_end TIMESTAMP NOT NULL,
	   FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id) ON DELETE CASCADE,
	   CONSTRAINT uq_doctor_slot UNIQUE (doctor_id, slot_start),
	   CONSTRAINT chk_slot_time CHECK (slot_end > slot_start)
);

CREATE TABLE Appointments(
       appointment_id SERIAL PRIMARY KEY,
	   patient_id INT NOT NULL,
	   slot_id INT NOT NULL UNIQUE,
	   appointment_status VARCHAR(20) NOT NULL DEFAULT 'booked',
	   booked_by_self BOOLEAN NOT NULL DEFAULT TRUE,
	   booker_relationship VARCHAR(50),
	   booking_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	   notes VARCHAR(255),
	   FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE,
	   FOREIGN KEY (slot_id) REFERENCES Time_Slots(slot_id) ON DELETE CASCADE,
	   CONSTRAINT chk_appointment_status CHECK ( 
	       appointment_status IN ('booked','cancelled','completed')
		   )
);

CREATE TABLE Consultations (
       consultation_id SERIAL PRIMARY KEY,
	   appointment_id INT NOT NULL UNIQUE,
	   visit_stage VARCHAR(20) NOT NULL,
	   consultation_mode VARCHAR(20) NOT NULL,
	   purpose VARCHAR(50) NOT NULL,
	   urgency VARCHAR(20) NOT NULL,
	   reason_for_visit VARCHAR(255),
	   referral_required BOOLEAN DEFAULT FALSE,
	   referral_provided BOOLEAN DEFAULT FALSE,
	   referring_doctor_name VARCHAR(100),
	   FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id) ON DELETE CASCADE,
	   CONSTRAINT chk_visit_stage CHECK (
            visit_stage in ('first_visit', 'follow_up')
	   ),
	   CONSTRAINT chk_mode CHECK (
            consultation_mode in ('in_person', 'online')
	   ),
	    CONSTRAINT chk_purpose CHECK (
            purpose in (
                 'consultation',
				 'examination',
				 'test_review',
				 'pre_surgery_consultation',
				 'post_surgery_follow_up'
			)
	   ),
	   CONSTRAINT chk_urgency CHECK (
            urgency in ('routine', 'emergency')
	   )
);

