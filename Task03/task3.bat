#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Список фильмов, имеющих хотя бы одну оценку. Отсортировать по году и названию. Первые 10."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT m.title, m.year FROM movies m JOIN ratings r ON r.movie_id = m.id ORDER BY m.year, m.title LIMIT 10;"
echo " "

echo "2. Пользователи, фамилии которых начинаются на 'A'. Отсортировать по дате регистрации. Первые 5."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT name, register_date FROM users WHERE substr(name, instr(name, ' ') + 1) LIKE 'A%' ORDER BY register_date LIMIT 5;"
echo " "

echo "3. Информация о рейтингах: имя эксперта, фильм, год, оценка, дата (ГГГГ-ММ-ДД). Первые 50."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u.name AS expert, m.title, m.year, r.rating, strftime('%Y-%m-%d', r.timestamp, 'unixepoch') AS rating_date FROM ratings r JOIN users u ON u.id = r.user_id JOIN movies m ON m.id = r.movie_id ORDER BY u.name, m.title, r.rating LIMIT 50;"
echo " "

echo "4. Фильмы с указанием тегов. Сортировать по году, названию, тегу. Первые 40."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, t.tag FROM movies m JOIN tags t ON m.id = t.movie_id ORDER BY m.year, m.title, t.tag LIMIT 40;"
echo " "

echo "5. Список самых свежих фильмов (универсальный запрос)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT title, year FROM movies WHERE year = (SELECT MAX(year) FROM movies) ORDER BY title;"
echo " "

echo "6. Комедии после 2000 года, оцененные мужчинами >= 4.5. Название, год, количество оценок."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, COUNT(*) AS cnt FROM ratings r JOIN movies m ON m.id = r.movie_id JOIN users u ON u.id = r.user_id WHERE m.genres LIKE '%Comedy%' AND m.year > 2000 AND u.gender = 'male' AND r.rating >= 4.5 GROUP BY m.id ORDER BY m.year, m.title;"
echo " "

echo "7. Анализ профессий: количество пользователей для каждого рода занятий."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT occupation, COUNT(*) AS cnt FROM users GROUP BY occupation ORDER BY cnt DESC;"
echo " "
echo "Самая распространенная профессия:"
sqlite3 movies_rating.db -box -echo "SELECT occupation, COUNT(*) AS cnt FROM users GROUP BY occupation ORDER BY cnt DESC LIMIT 1;"
echo " "
echo "Самая редкая профессия:"
sqlite3 movies_rating.db -box -echo "SELECT occupation, COUNT(*) AS cnt FROM users GROUP BY occupation ORDER BY cnt ASC LIMIT 1;"

