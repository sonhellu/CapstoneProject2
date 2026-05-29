"""
Run once on Railway to add image_url column to posts table.
Usage: python migrate_add_image_url.py
"""
import os
from sqlalchemy import create_engine, text

DATABASE_URL = os.environ["DATABASE_URL"]
engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    conn.execute(text(
        "ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_url VARCHAR(1024);"
    ))
    conn.commit()
    print("Migration done: added image_url to posts.")
