from functools import wraps
from collections import OrderedDict

from flask import (
    Flask, render_template, request, redirect,
    url_for, session, flash
)
from werkzeug.security import generate_password_hash, check_password_hash
import psycopg

from db import get_db_connection

app = Flask(__name__)
app.secret_key = "change_this_secret_key"


# Helpers

def login_required(view_func):
    @wraps(view_func)
    def wrapped_view(*args, **kwargs):
        if "patient_id" not in session:
            flash("Please log in first.", "warning")
            return redirect(url_for("login"))
        return view_func(*args, **kwargs)
    return wrapped_view


def password_matches(raw_password, stored_value):
    # Seeded demo accounts use placeholder strings like "hashed_pw_anya"
    # so allow both:
    # 1) direct comparison for demo seed accounts
    # 2) hashed password check for newly registered users
    if raw_password == stored_value:
        return True
    try:
        return check_password_hash(stored_value, raw_password)
    except Exception:
        return False


def fetch_one(query, params=None):
    conn = get_db_connection()
    if conn is None:
        return None

    cur = conn.cursor()
    cur.execute(query, params or ())
    row = cur.fetchone()
    cur.close()
    conn.close()
    return row


def fetch_all(query, params=None):
    conn = get_db_connection()
    if conn is None:
        return []

    cur = conn.cursor()
    cur.execute(query, params or ())
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows


def execute_commit(query, params=None):
    conn = get_db_connection()
    if conn is None:
        return 0

    cur = conn.cursor()
    cur.execute(query, params or ())
    conn.commit()
    affected = cur.rowcount
    cur.close()
    conn.close()
    return affected


def aggregate_doctors(rows):
    doctors = OrderedDict()

    for row in rows:
        doctor_id = row["doctor_id"]

        if doctor_id not in doctors:
            doctors[doctor_id] = {
                "doctor_id": row["doctor_id"],
                "first_name": row["first_name"],
                "last_name": row["last_name"],
                "phone": row["phone"],
                "email": row["email"],
                "specialties": [],
                "languages": []
            }

        specialty_name = row.get("specialty_name")
        language_name = row.get("language_name")

        if specialty_name and specialty_name not in doctors[doctor_id]["specialties"]:
            doctors[doctor_id]["specialties"].append(specialty_name)

        if language_name and language_name not in doctors[doctor_id]["languages"]:
            doctors[doctor_id]["languages"].append(language_name)

    return list(doctors.values())


def aggregate_doctor_detail(rows):
    if not rows:
        return None

    doctor = {
        "doctor_id": rows[0]["doctor_id"],
        "first_name": rows[0]["first_name"],
        "last_name": rows[0]["last_name"],
        "phone": rows[0]["phone"],
        "email": rows[0]["email"],
        "specialties": [],
        "languages": []
    }

    for row in rows:
        specialty_name = row.get("specialty_name")
        language_name = row.get("language_name")

        if specialty_name and specialty_name not in doctor["specialties"]:
            doctor["specialties"].append(specialty_name)

        if language_name and language_name not in doctor["languages"]:
            doctor["languages"].append(language_name)

    return doctor


def get_doctor_rows(base_where="", params=()):
    query = f"""
        SELECT
            d.doctor_id,
            d.first_name,
            d.last_name,
            d.phone,
            d.email,
            s.specialty_name,
            l.language_name
        FROM Doctors d
        LEFT JOIN Doctor_Specialty ds ON d.doctor_id = ds.doctor_id
        LEFT JOIN Specialties s ON ds.specialty_id = s.specialty_id
        LEFT JOIN Doctor_Language dl ON d.doctor_id = dl.doctor_id
        LEFT JOIN Languages l ON dl.language_id = l.language_id
        {base_where}
        ORDER BY d.last_name, d.first_name, s.specialty_name, l.language_name
    """
    return fetch_all(query, params)

 
# Home

@app.route("/")
def home():
    specialties = fetch_all("""
        SELECT specialty_id, specialty_name
        FROM Specialties
        ORDER BY specialty_name
    """)
    print("HOME SPECIALTIES:", specialties)
    return render_template("index.html", specialties=specialties)


# Register / Login / Logout / Profile


@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        first_name = request.form["first_name"].strip()
        last_name = request.form["last_name"].strip()
        date_of_birth = request.form["date_of_birth"]
        gender = request.form.get("gender")
        phone = request.form.get("phone")
        email = request.form.get("email")
        address = request.form.get("address")
        birth_country = request.form.get("birth_country")
        preferred_language = request.form.get("preferred_language")
        username = request.form["username"].strip()
        password = request.form["password"]

        password_hash = generate_password_hash(password)

        conn = get_db_connection()
        if conn is None:
            flash("Database connection failed.", "danger")
            return redirect(url_for("register"))

        cur = conn.cursor()

        try:
            # 1. Check if username already exists
            cur.execute("""
                SELECT account_id
                FROM Patient_Accounts
                WHERE username = %s
            """, (username,))
            existing_user = cur.fetchone()

            if existing_user:
                flash("This username already exists. Please choose another one.", "danger")
                cur.close()
                conn.close()
                return redirect(url_for("register"))

            # 2. Insert into Patients
            cur.execute("""
                INSERT INTO Patients (
                    first_name, last_name, date_of_birth, gender,
                    phone, email, address, birth_country, preferred_language
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                first_name, last_name, date_of_birth, gender,
                phone, email, address, birth_country, preferred_language
            ))

            # 3. Get the latest inserted patient_id
            cur.execute("""
                SELECT patient_id
                FROM Patients
                ORDER BY patient_id DESC
                LIMIT 1
            """)
            patient = cur.fetchone()

            if not patient:
                conn.rollback()
                flash("Registration failed while creating patient profile.", "danger")
                cur.close()
                conn.close()
                return redirect(url_for("register"))

            patient_id = patient["patient_id"]

            # 4. Insert into Patient_Accounts
            cur.execute("""
                INSERT INTO Patient_Accounts (
                    patient_id, username, password_hash, account_status
                ) VALUES (%s, %s, %s, 'active')
            """, (
                patient_id, username, password_hash
            ))

            conn.commit()
            flash("Registration successful. Please log in.", "success")
            return redirect(url_for("login"))

        except psycopg.Error as e:
            conn.rollback()
            print("REGISTER ERROR:", e)
            flash("Registration failed due to a database error.", "danger")
            return redirect(url_for("register"))

        finally:
            cur.close()
            conn.close()

    return render_template("register.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"].strip()
        password = request.form["password"]

        account = fetch_one("""
            SELECT
                pa.account_id,
                pa.patient_id,
                pa.username,
                pa.password_hash,
                pa.account_status,
                p.first_name,
                p.last_name
            FROM Patient_Accounts pa
            JOIN Patients p ON pa.patient_id = p.patient_id
            WHERE pa.username = %s
              AND pa.account_status = 'active'
        """, (username,))

        if not account:
            flash("Invalid username or password.", "danger")
            return redirect(url_for("login"))

        if not password_matches(password, account["password_hash"]):
            flash("Invalid username or password.", "danger")
            return redirect(url_for("login"))

        session["patient_id"] = account["patient_id"]
        session["username"] = account["username"]
        session["patient_name"] = f"{account['first_name']} {account['last_name']}"

        flash("Login successful.", "success")
        return redirect(url_for("my_appointments"))

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for("login"))


@app.route("/profile", methods=["GET", "POST"])
@login_required
def profile():
    patient_id = session["patient_id"]

    if request.method == "POST":
        phone = request.form.get("phone")
        email = request.form.get("email")
        address = request.form.get("address")
        preferred_language = request.form.get("preferred_language")

        execute_commit("""
            UPDATE Patients
            SET
                phone = %s,
                email = %s,
                address = %s,
                preferred_language = %s
            WHERE patient_id = %s
        """, (phone, email, address, preferred_language, patient_id))

        flash("Profile updated successfully.", "success")
        return redirect(url_for("profile"))

    patient = fetch_one("""
        SELECT
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
        FROM Patients
        WHERE patient_id = %s
    """, (patient_id,))

    stats = fetch_one("""
        SELECT
            COUNT(*) AS total_appointments,
            SUM(CASE WHEN appointment_status = 'booked' THEN 1 ELSE 0 END) AS upcoming_appointments,
            SUM(CASE WHEN appointment_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_appointments
        FROM Appointments
        WHERE patient_id = %s
    """, (patient_id,))

    top_specialty_row = fetch_one("""
        SELECT s.specialty_name, COUNT(*) AS visit_count
        FROM Appointments a
        JOIN Time_Slots ts ON a.slot_id = ts.slot_id
        JOIN Doctors d ON ts.doctor_id = d.doctor_id
        JOIN Doctor_Specialty ds ON d.doctor_id = ds.doctor_id
        JOIN Specialties s ON ds.specialty_id = s.specialty_id
        WHERE a.patient_id = %s
        GROUP BY s.specialty_name
        ORDER BY visit_count DESC, s.specialty_name
        LIMIT 1
    """, (patient_id,))

    most_visited_specialty = top_specialty_row["specialty_name"] if top_specialty_row else "N/A"

    return render_template(
        "profile.html",
        patient=patient,
        stats=stats,
        most_visited_specialty=most_visited_specialty
    )

@app.route("/delete-account", methods=["POST"])
@login_required
def delete_account():
    patient_id = session["patient_id"]

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            DELETE FROM Patients
            WHERE patient_id = %s
        """, (patient_id,))

        conn.commit()
        session.clear()
        flash("Your account has been permanently deleted.", "info")
        return redirect(url_for("home"))

    except psycopg.Error:
        conn.rollback()
        flash("Account deletion failed. Please try again.", "danger")
        return redirect(url_for("profile"))

    finally:
        cur.close()
        conn.close()
        

# Doctors / Browse

@app.route("/doctors")
def doctors():
    specialty_id = request.args.get("specialty_id")
    language_id = request.args.get("language_id")
    keyword = request.args.get("keyword", "").strip()

    specialties = fetch_all("""
        SELECT specialty_id, specialty_name
        FROM Specialties
        ORDER BY specialty_name
    """)

    languages = fetch_all("""
        SELECT language_id, language_name
        FROM Languages
        ORDER BY language_name
    """)

    query = """
        SELECT
            d.doctor_id,
            d.first_name,
            d.last_name,
            d.phone,
            d.email,
            s.specialty_name,
            l.language_name
        FROM Doctors d
        LEFT JOIN Doctor_Specialty ds ON d.doctor_id = ds.doctor_id
        LEFT JOIN Specialties s ON ds.specialty_id = s.specialty_id
        LEFT JOIN Doctor_Language dl ON d.doctor_id = dl.doctor_id
        LEFT JOIN Languages l ON dl.language_id = l.language_id
        WHERE 1=1
    """

    params = []

    if specialty_id:
        query += """
            AND d.doctor_id IN (
                SELECT doctor_id
                FROM Doctor_Specialty
                WHERE specialty_id = %s
            )
        """
        params.append(specialty_id)

    if language_id:
        query += """
            AND d.doctor_id IN (
                SELECT doctor_id
                FROM Doctor_Language
                WHERE language_id = %s
            )
        """
        params.append(language_id)

    if keyword:
        query += """
            AND (d.first_name || ' ' || d.last_name) LIKE %s
        """
        params.append(f"%{keyword}%")

    query += """
        ORDER BY d.last_name, d.first_name, s.specialty_name, l.language_name
    """

    rows = fetch_all(query, tuple(params))
    doctors_list = aggregate_doctors(rows)

    return render_template(
        "doctors.html",
        doctors=doctors_list,
        specialties=specialties,
        languages=languages,
        selected_specialty=specialty_id,
        selected_language=language_id,
        keyword=keyword
    )

@app.route("/doctor/<int:doctor_id>")
def doctor_detail(doctor_id):
    rows = get_doctor_rows("WHERE d.doctor_id = %s", (doctor_id,))
    doctor = aggregate_doctor_detail(rows)

    if not doctor:
        flash("Doctor not found.", "danger")
        return redirect(url_for("doctors"))

    slots = fetch_all("""
    SELECT
        t.slot_id,
        t.slot_start,
        t.slot_end
    FROM Time_Slots t
    WHERE t.doctor_id = %s
      AND t.slot_start > NOW()
      AND NOT EXISTS (
          SELECT 1
          FROM Appointments a
          WHERE a.slot_id = t.slot_id
            AND a.appointment_status = 'booked'
      )
    ORDER BY t.slot_start
    """, (doctor_id,))

    suggested_visit_stage = None
    if session.get("patient_id"):
        suggestion = fetch_one("""
            SELECT
                CASE
                    WHEN COUNT(*) > 0 THEN 'follow_up'
                    ELSE 'first_visit'
                END AS suggested_visit_stage
            FROM Appointments a
            JOIN Time_Slots ts ON a.slot_id = ts.slot_id
            WHERE a.patient_id = %s
              AND ts.doctor_id = %s
              AND a.appointment_status IN ('booked', 'completed')
        """, (session["patient_id"], doctor_id))

        if suggestion:
            suggested_visit_stage = suggestion["suggested_visit_stage"]

    return render_template(
        "doctor_detail.html",
        doctor=doctor,
        slots=slots,
        suggested_visit_stage=suggested_visit_stage
    )



# Book appointment

@app.route("/appointments/book/<int:slot_id>", methods=["GET", "POST"])
@login_required
def book_appointment(slot_id):
    patient_id = session["patient_id"]

    slot = fetch_one("""
        SELECT
            ts.slot_id,
            ts.slot_start,
            ts.slot_end,
            d.doctor_id,
            d.first_name,
            d.last_name
        FROM Time_Slots ts
        JOIN Doctors d ON ts.doctor_id = d.doctor_id
        WHERE ts.slot_id = %s
    """, (slot_id,))

    if not slot:
        flash("Selected slot was not found.", "danger")
        return redirect(url_for("doctors"))

    occupied = fetch_one("""
        SELECT appointment_id
        FROM Appointments
        WHERE slot_id = %s
          AND appointment_status = 'booked'
    """, (slot_id,))

    if occupied:
        flash("This slot is already booked.", "danger")
        return redirect(url_for("doctor_detail", doctor_id=slot["doctor_id"]))

    suggestion = fetch_one("""
        SELECT
            CASE
                WHEN COUNT(*) > 0 THEN 'follow_up'
                ELSE 'first_visit'
            END AS suggested_visit_stage
        FROM Appointments a
        JOIN Time_Slots ts ON a.slot_id = ts.slot_id
        WHERE a.patient_id = %s
          AND ts.doctor_id = %s
          AND a.appointment_status IN ('booked', 'completed')
    """, (patient_id, slot["doctor_id"]))

    suggested_visit_stage = suggestion["suggested_visit_stage"] if suggestion else "first_visit"

    if request.method == "POST":
        visit_stage = request.form["visit_stage"]
        consultation_mode = request.form["consultation_mode"]
        purpose = request.form["purpose"]
        urgency = request.form["urgency"]
        reason_for_visit = request.form.get("reason_for_visit")
        referral_required = True if request.form.get("referral_required") == "yes" else False
        referral_provided = True if request.form.get("referral_provided") == "yes" else False
        referring_doctor_name = request.form.get("referring_doctor_name") or None
        notes = request.form.get("notes")
        booked_by_self = True if request.form.get("booked_by_self", "yes") == "yes" else False
        booker_relationship = request.form.get("booker_relationship") or None

        conn = get_db_connection()
        cur = conn.cursor()

        try:
            # check one more time
            cur.execute("""
                SELECT appointment_id
                FROM Appointments
                WHERE slot_id = %s
                  AND appointment_status = 'booked'
            """, (slot_id,))
            again = cur.fetchone()
            if again:
                conn.rollback()
                flash("This slot is no longer available.", "danger")
                return redirect(url_for("doctor_detail", doctor_id=slot["doctor_id"]))

            cur.execute("""
                INSERT INTO Appointments (
                    patient_id,
                    slot_id,
                    appointment_status,
                    booked_by_self,
                    booker_relationship,
                    booking_created_at,
                    notes
                ) VALUES (%s, %s, 'booked', %s, %s, CURRENT_TIMESTAMP, %s)
            """, (
                patient_id,
                slot_id,
                booked_by_self,
                booker_relationship,
                notes
            ))

            # Simpler than RETURNING: fetch latest appointment of this patient/slot
            cur.execute("""
                SELECT appointment_id
                FROM Appointments
                WHERE patient_id = %s
                  AND slot_id = %s
                ORDER BY appointment_id DESC
                LIMIT 1
            """, (patient_id, slot_id))
            appt = cur.fetchone()

            if not appt:
                conn.rollback()
                flash("Booking failed while creating the appointment.", "danger")
                return redirect(url_for("doctor_detail", doctor_id=slot["doctor_id"]))

            appointment_id = appt["appointment_id"]

            cur.execute("""
                INSERT INTO Consultations (
                    appointment_id,
                    visit_stage,
                    consultation_mode,
                    purpose,
                    urgency,
                    reason_for_visit,
                    referral_required,
                    referral_provided,
                    referring_doctor_name
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                appointment_id,
                visit_stage,
                consultation_mode,
                purpose,
                urgency,
                reason_for_visit,
                referral_required,
                referral_provided,
                referring_doctor_name
            ))

            conn.commit()
            flash("Appointment booked successfully.", "success")
            return redirect(url_for("appointment_detail", appointment_id=appointment_id))

        except psycopg.Error:
            conn.rollback()
            flash("Booking failed. Please try another slot.", "danger")
            return redirect(url_for("doctor_detail", doctor_id=slot["doctor_id"]))

        finally:
            cur.close()
            conn.close()

    return render_template(
        "book_appointment.html",
        slot=slot,
        suggested_visit_stage=suggested_visit_stage
    )


# My appointments

def get_appointments_by_status(patient_id, status):
    return fetch_all("""
        SELECT
            a.appointment_id,
            a.appointment_status,
            ts.slot_start,
            ts.slot_end,
            d.doctor_id,
            d.first_name,
            d.last_name,
            c.visit_stage,
            c.consultation_mode,
            c.purpose,
            c.urgency
        FROM Appointments a
        JOIN Time_Slots ts ON a.slot_id = ts.slot_id
        JOIN Doctors d ON ts.doctor_id = d.doctor_id
        LEFT JOIN Consultations c ON a.appointment_id = c.appointment_id
        WHERE a.patient_id = %s
          AND a.appointment_status = %s
        ORDER BY ts.slot_start
    """, (patient_id, status))


@app.route("/appointments")
@login_required
def my_appointments():
    patient_id = session["patient_id"]

    upcoming = get_appointments_by_status(patient_id, "booked")
    completed = get_appointments_by_status(patient_id, "completed")
    cancelled = get_appointments_by_status(patient_id, "cancelled")

    return render_template(
        "my_appointments.html",
        upcoming=upcoming,
        completed=completed,
        cancelled=cancelled
    )


@app.route("/appointments/<int:appointment_id>")
@login_required
def appointment_detail(appointment_id):
    patient_id = session["patient_id"]

    appointment = fetch_one("""
        SELECT
            a.appointment_id,
            a.patient_id,
            a.appointment_status,
            a.booked_by_self,
            a.booker_relationship,
            a.booking_created_at,
            a.notes,
            ts.slot_id,
            ts.slot_start,
            ts.slot_end,
            d.doctor_id,
            d.first_name,
            d.last_name,
            c.visit_stage,
            c.consultation_mode,
            c.purpose,
            c.urgency,
            c.reason_for_visit,
            c.referral_required,
            c.referral_provided,
            c.referring_doctor_name
        FROM Appointments a
        JOIN Time_Slots ts ON a.slot_id = ts.slot_id
        JOIN Doctors d ON ts.doctor_id = d.doctor_id
        JOIN Consultations c ON a.appointment_id = c.appointment_id
        WHERE a.appointment_id = %s
          AND a.patient_id = %s
    """, (appointment_id, patient_id))

    if not appointment:
        flash("Appointment not found.", "danger")
        return redirect(url_for("my_appointments"))

    specialties_rows = fetch_all("""
        SELECT s.specialty_name
        FROM Doctors d
        JOIN Doctor_Specialty ds ON d.doctor_id = ds.doctor_id
        JOIN Specialties s ON ds.specialty_id = s.specialty_id
        WHERE d.doctor_id = %s
        ORDER BY s.specialty_name
    """, (appointment["doctor_id"],))

    languages_rows = fetch_all("""
        SELECT l.language_name
        FROM Doctors d
        JOIN Doctor_Language dl ON d.doctor_id = dl.doctor_id
        JOIN Languages l ON dl.language_id = l.language_id
        WHERE d.doctor_id = %s
        ORDER BY l.language_name
    """, (appointment["doctor_id"],))

    appointment["specialties"] = [row["specialty_name"] for row in specialties_rows]
    appointment["doctor_languages"] = [row["language_name"] for row in languages_rows]

    return render_template("appointment_detail.html", appointment=appointment)


@app.route("/appointments/<int:appointment_id>/cancel", methods=["POST"])
@login_required
def cancel_appointment(appointment_id):
    patient_id = session["patient_id"]

    affected = execute_commit("""
        UPDATE Appointments
        SET appointment_status = 'cancelled'
        WHERE appointment_id = %s
          AND patient_id = %s
          AND appointment_status = 'booked'
    """, (appointment_id, patient_id))

    if affected:
        flash("Appointment cancelled successfully.", "success")
    else:
        flash("Unable to cancel this appointment.", "danger")

    return redirect(url_for("my_appointments"))


@app.route("/appointments/<int:appointment_id>/edit", methods=["GET", "POST"])
@login_required
def reschedule_appointment(appointment_id):
    patient_id = session["patient_id"]

    appointment = fetch_one("""
        SELECT
            a.appointment_id,
            a.patient_id,
            a.appointment_status,
            ts.slot_id,
            ts.doctor_id,
            ts.slot_start,
            ts.slot_end
        FROM Appointments a
        JOIN Time_Slots ts ON a.slot_id = ts.slot_id
        WHERE a.appointment_id = %s
          AND a.patient_id = %s
          AND a.appointment_status = 'booked'
    """, (appointment_id, patient_id))

    if not appointment:
        flash("Only booked appointments can be rescheduled.", "danger")
        return redirect(url_for("my_appointments"))

    available_slots = fetch_all("""
    SELECT
        ts.slot_id,
        ts.slot_start,
        ts.slot_end
    FROM Time_Slots ts
    WHERE ts.doctor_id = %s
      AND ts.slot_start > NOW()
      AND ts.slot_id <> %s
      AND NOT EXISTS (
          SELECT 1
          FROM Appointments a
          WHERE a.slot_id = ts.slot_id
            AND a.appointment_status = 'booked'
      )
    ORDER BY ts.slot_start
    """, (appointment["doctor_id"], appointment["slot_id"]))

    if request.method == "POST":
        new_slot_id = request.form["new_slot_id"]

        conn = get_db_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                SELECT appointment_id
                FROM Appointments
                WHERE slot_id = %s
                  AND appointment_status = 'booked'
            """, (new_slot_id,))
            occupied = cur.fetchone()

            if occupied:
                conn.rollback()
                flash("Selected new slot is already booked.", "danger")
                return redirect(url_for("reschedule_appointment", appointment_id=appointment_id))

            cur.execute("""
                UPDATE Appointments
                SET slot_id = %s
                WHERE appointment_id = %s
                  AND patient_id = %s
                  AND appointment_status = 'booked'
            """, (new_slot_id, appointment_id, patient_id))

            conn.commit()
            flash("Appointment rescheduled successfully.", "success")
            return redirect(url_for("appointment_detail", appointment_id=appointment_id))

        except psycopg.Error:
            conn.rollback()
            flash("Rescheduling failed. Please try another slot.", "danger")
            return redirect(url_for("reschedule_appointment", appointment_id=appointment_id))

        finally:
            cur.close()
            conn.close()

    return render_template(
        "reschedule_appointment.html",
        appointment=appointment,
        available_slots=available_slots
    )


if __name__ == "__main__":
    app.run(debug=True)