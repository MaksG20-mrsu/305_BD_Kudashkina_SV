#!/usr/bin/env python3
"""Генератор SQL-скрипта db_init.sql для базы movies_rating.db."""

import csv
import os
import re

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def esc(s):
    """Экранирование одинарных кавычек для SQL."""
    if s is None:
        return ''
    return str(s).replace("'", "''")


def parse_movies(path):
    """movies.csv: movieId,title,genres -> id, title, year, genres"""
    rows = []
    with open(path, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            title = r['title']
            year = None
            m = re.search(r'\((\d{4})\)\s*$', title)
            if m:
                year = int(m.group(1))
                title = title[:m.start()].strip()
            rows.append((int(r['movieId']), title, year, r['genres']))
    return rows


def parse_ratings(path):
    """ratings.csv: userId,movieId,rating,timestamp"""
    rows = []
    with open(path, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append((int(r['userId']), int(r['movieId']),
                         float(r['rating']), int(r['timestamp'])))
    return rows


def parse_tags(path):
    """tags.csv: userId,movieId,tag,timestamp"""
    rows = []
    with open(path, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append((int(r['userId']), int(r['movieId']),
                         r['tag'], int(r['timestamp'])))
    return rows


def parse_users(path):
    """users.txt: userId|name|email|gender|birthdate|occupation"""
    rows = []
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split('|')
            if len(parts) < 6:
                continue
            uid, name, email, gender, birthdate, occupation = parts[:6]
            rows.append((int(uid), name, email, gender, birthdate, occupation))
    return rows


def main():
    sql = []
    sql.append('PRAGMA foreign_keys = OFF;')
    sql.append('BEGIN TRANSACTION;')

    # --- movies ---
    sql.append('DROP TABLE IF EXISTS movies;')
    sql.append('''CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT
);''')
    for mid, title, year, genres in parse_movies(os.path.join(BASE_DIR, 'movies.csv')):
        year_sql = 'NULL' if year is None else str(year)
        sql.append(
            f"INSERT INTO movies (id, title, year, genres) "
            f"VALUES ({mid}, '{esc(title)}', {year_sql}, '{esc(genres)}');"
        )

    # --- ratings ---
    sql.append('DROP TABLE IF EXISTS ratings;')
    sql.append('''CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);''')
    for uid, mid, rating, ts in parse_ratings(os.path.join(BASE_DIR, 'ratings.csv')):
        sql.append(
            f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) "
            f"VALUES ({uid}, {mid}, {rating}, {ts});"
        )

    # --- tags ---
    sql.append('DROP TABLE IF EXISTS tags;')
    sql.append('''CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT,
    timestamp INTEGER NOT NULL
);''')
    for uid, mid, tag, ts in parse_tags(os.path.join(BASE_DIR, 'tags.csv')):
        sql.append(
            f"INSERT INTO tags (user_id, movie_id, tag, timestamp) "
            f"VALUES ({uid}, {mid}, '{esc(tag)}', {ts});"
        )

    # --- users ---
    sql.append('DROP TABLE IF EXISTS users;')
    sql.append('''CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);''')
    for uid, name, email, gender, birthdate, occupation in parse_users(
            os.path.join(BASE_DIR, 'users.txt')):
        sql.append(
            f"INSERT INTO users (id, name, email, gender, register_date, occupation) "
            f"VALUES ({uid}, '{esc(name)}', '{esc(email)}', '{esc(gender)}', "
            f"'{esc(birthdate)}', '{esc(occupation)}');"
        )

    sql.append('COMMIT;')

    out = os.path.join(BASE_DIR, 'db_init.sql')
    with open(out, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql))
    print(f'Generated {out}: {len(sql)} statements')


if __name__ == '__main__':
    main()