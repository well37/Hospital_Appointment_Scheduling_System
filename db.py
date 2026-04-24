import os
import logging
import psycopg
from psycopg.rows import dict_row
from psycopg import OperationalError

# Basic logging setup 
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_db_connection():
    password = os.getenv("POSTGRES_PASSWORD")

    if not password:
        print("Database connection error: POSTGRES_PASSWORD is not set.")
        return None

    try:
        conn = psycopg.connect(
            dbname="hospital_reservation",
            user="postgres",
            password=password,
            host="localhost",
            port="5432",
            row_factory=dict_row
        )
        return conn

    except OperationalError as e:
        print(f"Database connection error: {e}")
        return None
    