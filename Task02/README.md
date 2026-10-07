# Task02 — ETL для базы movies_rating.db

## Требования к окружению

Для корректной работы скрипта `db_init.bat` на компьютере должны быть установлены:

- **Python 3** (проверка: `python3 --version`)
- **SQLite 3** с утилитой командной строки `sqlite3` (проверка: `sqlite3 --version`)
- **Bash** (для Windows — Git Bash, WSL или Cygwin)

## Состав каталога

| Файл | Назначение |
|------|------------|
| `make_db_init.py` | Python-утилита, генерирующая SQL-скрипт `db_init.sql` |
| `db_init.sql` | SQL-скрипт создания таблиц и загрузки данных (генерируется) |
| `db_init.bat` | Shell-скрипт: запускает утилиту и загружает SQL в SQLite |
| `movies_rating.db` | База данных SQLite (создаётся при запуске) |
| `movies.csv`, `ratings.csv`, `tags.csv`, `users.csv` | Исходные данные |
| `genres.txt`, `occupation.txt` | Справочники жанров и профессий |

## Запуск

```bash
bash db_init.bat