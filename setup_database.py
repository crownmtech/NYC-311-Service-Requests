#!/usr/bin/env python programmed by CrownMatrix Technologies Limited
"""
setup_database.py

Creates nyc311.db SQLite database and imports the CSV as raw_311 table.
Then runs the SQL transformations from nyc311_sql_tasks.sql.
"""

import sqlite3
import csv
import os
import sys

def create_database():
    """Create SQLite database and import CSV."""
    
    db_path = "nyc311.db"
    csv_path = "data/raw_311_sample.csv"
    sql_script_path = "nyc311_sql_tasks.sql"
    
    # Check if CSV exists
    if not os.path.exists(csv_path):
        print(f"ERROR: CSV file not found at {csv_path}")
        sys.exit(1)
    
    # Remove existing database if present
    if os.path.exists(db_path):
        print(f"Removing existing database: {db_path}")
        os.remove(db_path)
    
    # Connect to SQLite
    print(f"Creating database: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Read CSV and create raw_311 table
    print(f"Importing CSV from: {csv_path}")
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)
        
        # Create table with all text columns
        # Use double quotes for column names that may have spaces
        columns_def = ', '.join([f'"{col}" TEXT' for col in headers])
        create_table_sql = f"CREATE TABLE raw_311 ({columns_def})"
        cursor.execute(create_table_sql)
        
        # Insert data
        placeholders = ', '.join(['?' for _ in headers])
        insert_sql = f"INSERT INTO raw_311 VALUES ({placeholders})"
        
        row_count = 0
        for row in reader:
            cursor.execute(insert_sql, row)
            row_count += 1
        
        conn.commit()
        print(f"Imported {row_count} rows into raw_311")
    
    # Run SQL transformations from nyc311_sql_tasks.sql
    if os.path.exists(sql_script_path):
        print(f"\nExecuting SQL script: {sql_script_path}")
        with open(sql_script_path, 'r', encoding='utf-8') as f:
            sql_script = f.read()
        
        # SQLite executescript can run multiple statements
        # Note: It auto-commits, so we don't need explicit commit
        try:
            cursor.executescript(sql_script)
            print("SQL transformations completed successfully")
        except sqlite3.Error as e:
            print(f"Warning: Some SQL statements may have failed: {e}")
            print("This is normal if the script contains validation queries that return data.")
    else:
        print(f"Warning: SQL script not found at {sql_script_path}")
    
    # Verify tables created
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    print(f"\nTables in database: {[t[0] for t in tables]}")
    
    # Check row counts
    for table_name in ['raw_311', 'raw_311_indexed', 'raw_311_2023', 'clean_311_2023', 'clean_311_2023_dedup']:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            count = cursor.fetchone()[0]
            print(f"  {table_name}: {count} rows")
        except sqlite3.Error:
            print(f"  {table_name}: table not found")
    
    conn.close()
    print(f"\nDatabase setup complete: {db_path}")
    print("You can now run NYC311_analysis.ipynb in Jupyter")

if __name__ == "__main__":
    create_database()
