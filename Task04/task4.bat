#!/bin/bash
chcp 65001 2>/dev/null

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u1.name AS user1, u2.name AS user2, m.title AS movie FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON u1.id = r1.user_id JOIN users u2 ON u2.id = r2.user_id JOIN movies m ON m.id = r1.movie_id ORDER BY m.title, u1.name, u2.name LIMIT 100;"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH latest_per_user AS (SELECT r.user_id, r.movie_id, r.rating, r.timestamp, ROW_NUMBER() OVER (PARTITION BY r.user_id ORDER BY r.timestamp DESC) AS rn FROM ratings r) SELECT m.title, u.name, l.rating, date(l.timestamp, 'unixepoch') AS rating_date FROM latest_per_user l JOIN users u ON u.id = l.user_id JOIN movies m ON m.id = l.movie_id WHERE l.rn = 1 ORDER BY l.timestamp DESC LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS (SELECT movie_id, AVG(rating) AS avg_rating FROM ratings GROUP BY movie_id), extremes AS (SELECT * FROM avg_ratings WHERE avg_rating = (SELECT MAX(avg_rating) FROM avg_ratings) OR avg_rating = (SELECT MIN(avg_rating) FROM avg_ratings)) SELECT m.title, m.year, e.avg_rating, CASE WHEN e.avg_rating = (SELECT MAX(avg_rating) FROM avg_ratings) THEN 'Да' ELSE 'Нет' END AS \"Рекомендуем\" FROM extremes e JOIN movies m ON m.id = e.movie_id ORDER BY m.year, m.title;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo --------------------------------------------------
echo "--- Общий итог ---"
sqlite3 movies_rating.db -box -echo "SELECT COUNT(*) AS ratings_count, AVG(r.rating) AS avg_rating FROM ratings r JOIN users u ON u.id = r.user_id WHERE u.gender = 'female' AND CAST(strftime('%Y', r.timestamp, 'unixepoch') AS INTEGER) BETWEEN 2010 AND 2012;"
echo "--- По фильмам ---"
sqlite3 movies_rating.db -box -echo "SELECT m.title, COUNT(*) AS cnt, AVG(r.rating) AS avg_rating FROM ratings r JOIN users u ON u.id = r.user_id JOIN movies m ON m.id = r.movie_id WHERE u.gender = 'female' AND CAST(strftime('%Y', r.timestamp, 'unixepoch') AS INTEGER) BETWEEN 2010 AND 2012 GROUP BY m.id, m.title ORDER BY m.title;"
echo " "

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_movies AS (SELECT movie_id, AVG(rating) AS avg_rating FROM ratings GROUP BY movie_id) SELECT m.title, m.year, a.avg_rating, RANK() OVER (ORDER BY a.avg_rating DESC) AS rank_by_rating FROM avg_movies a JOIN movies m ON m.id = a.movie_id ORDER BY m.year, m.title LIMIT 20;"
echo " "

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS \"Фамилия Имя|Дата регистрации\" FROM users ORDER BY register_date DESC LIMIT 10;"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE nums(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM nums WHERE n < 10) SELECT a.n || 'x' || b.n || '=' || (a.n * b.n) AS multiplication FROM nums a CROSS JOIN nums b ORDER BY a.n, b.n;"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies WHERE genres IS NOT NULL UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|') - 1), substr(rest, instr(rest, '|') + 1) FROM split WHERE rest <> '') SELECT DISTINCT genre FROM split WHERE genre <> '' ORDER BY genre;"
echo " "
