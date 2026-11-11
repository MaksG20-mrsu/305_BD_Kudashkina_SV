PRAGMA foreign_keys = ON;

-- ============================================================
-- 5 новых пользователей (я + 4 соседа по группе)
-- ============================================================
INSERT INTO users(first_name, last_name, email, gender, register_date, occupation_id)
VALUES
    ('Софья', 'Кудашкина', 'kudashkina_sv@example.com', 'F', date('now'), (SELECT id FROM occupations WHERE name='student')),
    ('Иван',  'Иванов',    'ivanov_ii@example.com',     'M', date('now'), (SELECT id FROM occupations WHERE name='student')),
    ('Пётр',  'Петров',    'petrov_pp@example.com',     'M', date('now'), (SELECT id FROM occupations WHERE name='student')),
    ('Анна',  'Сидорова',  'sidorova_aa@example.com',   'F', date('now'), (SELECT id FROM occupations WHERE name='student')),
    ('Мария', 'Смирнова',  'smirnova_mm@example.com',   'F', date('now'), (SELECT id FROM occupations WHERE name='student'));

-- ============================================================
-- 3 новых фильма разных жанров
-- ============================================================
INSERT INTO movies(title, year) VALUES
    ('Мой фильм ужасов',  2025),
    ('Моя комедия',       2025),
    ('Мой боевик',        2025);

INSERT INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g
WHERE m.title='Мой фильм ужасов' AND g.name='Horror';

INSERT INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g
WHERE m.title='Моя комедия' AND g.name='Comedy';

INSERT INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g
WHERE m.title='Мой боевик' AND g.name='Action';

-- ============================================================
-- 3 отзыва о новых фильмах от себя
-- ============================================================
INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5.0, strftime('%s','now')
FROM users u, movies m
WHERE u.email='kudashkina_sv@example.com' AND m.title='Мой фильм ужасов';

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4.5, strftime('%s','now')
FROM users u, movies m
WHERE u.email='kudashkina_sv@example.com' AND m.title='Моя комедия';

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4.0, strftime('%s','now')
FROM users u, movies m
WHERE u.email='kudashkina_sv@example.com' AND m.title='Мой боевик';
