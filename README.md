# Hospital Appointment Scheduling System

Author: Jiwon CHAE, Sènami GANDONOU
(M1 Applied Mathematics & Statistics of Institut Polytechnique de Paris)

A patient-oriented hospital appointment scheduling system built with **PostgreSQL**, **Flask**, **HTML/CSS**, and **SQL**.

The system allows patients to:
- register and log in
- search doctors by specialty and language
- view available time slots
- book appointments
- cancel or reschedule appointments
- manage their profile and appointment history

---

## Project Overview

This project was developed for a database systems course.

The application is designed for a **single hospital** environment and combines:
- a relational database
- structured scheduling logic
- integrity constraints
- a working web interface for patients

Our goal was to build a realistic and usable hospital booking system while applying core database concepts in both the schema and the application workflow.

---

## Main Features

- Patient registration and login
- Doctor search and filtering
- Real-time slot availability
- Appointment booking
- Appointment cancellation
- Appointment rescheduling
- Automatic **First Visit / Follow-up** suggestion
- Secure appointment ownership checks
- Profile update and statistics dashboard

---

## Tech Stack

**Backend**
- Python
- Flask

**Database**
- PostgreSQL
- SQL

**Frontend**
- HTML
- CSS
- Bootstrap

**Tools**
- pgAdmin 4
- VS Code
- PowerShell / Terminal

---

## Project Structure

```text
hospital_scheduler/
├── app.py
├── db.py
├── requirements.txt
├── sequence_fix.sql
├── SCHEMA_hospital_dbms.sql
├── seed_master_data.sql
├── seed_transaction_data.sql
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── register.html
│   ├── login.html
│   ├── profile.html
│   ├── doctors.html
│   ├── doctor_detail.html
│   ├── book_appointment.html
│   ├── my_appointments.html
│   ├── appointment_detail.html
│   └── reschedule_appointment.html
└── static/
    └── style.css
```

## How to set up the database

1. Open **pgAdmin 4** and create a new PostgreSQL database.

Recommended database name:

```text
hospital_reservation
```

2. Open the Query Tool for that database and run the schema file, the master seed file, the transaction seed file:

```text
SCHEMA_hospital_dbms.sql
seed_master_data.sql
seed_transaction_data.sql
```

3. Synchronize the PostgreSQL sequences:
``` text
sequence_fix.sql
```

## How to run the application

0. Install all the files of the project according to the structure of the files

1. Install the required packages:

For Windows PowerShell:
```text
py -m pip install -r requirements.txt
```

For macOS / Linux:
```text
python3 -m pip install -r requirements.txt
```

2. Set the PostgreSQL password as an environment variable

For Windows PowerShell:
```text
$env:POSTGRES_PASSWORD='your_postgres_password'
```

For macOS / Linux:
```text
export POSTGRES_PASSWORD='your_postgres_password'
```

3. Start the Flask application

For Windows PowerShell:
```text
py .\app.py
```

For macOS / Linux:
```text
python3 app.py
```

4. Open the browser

```text
http://127.0.0.1:5000
```




