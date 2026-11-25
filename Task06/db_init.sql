-- Task06: база данных станции технического обслуживания автомобилей
-- SQLite 3.x
PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

CREATE TABLE employees (
    employee_id       INTEGER PRIMARY KEY,
    last_name         TEXT NOT NULL CHECK (length(trim(last_name)) > 0),
    first_name        TEXT NOT NULL CHECK (length(trim(first_name)) > 0),
    middle_name       TEXT,
    phone             TEXT NOT NULL UNIQUE CHECK (length(trim(phone)) >= 5),
    email             TEXT UNIQUE,
    position          TEXT NOT NULL DEFAULT 'Мастер'
                      CHECK (position IN ('Мастер', 'Администратор', 'Механик')),
    commission_percent REAL NOT NULL DEFAULT 30.0
                      CHECK (commission_percent >= 0 AND commission_percent <= 100),
    hired_at          TEXT NOT NULL DEFAULT (date('now')),
    dismissed_at      TEXT,
    is_active         INTEGER GENERATED ALWAYS AS
                      (CASE WHEN dismissed_at IS NULL THEN 1 ELSE 0 END) VIRTUAL,
    CHECK (dismissed_at IS NULL OR dismissed_at >= hired_at)
);

CREATE TABLE employee_schedule (
    schedule_id       INTEGER PRIMARY KEY,
    employee_id       INTEGER NOT NULL,
    weekday           INTEGER NOT NULL CHECK (weekday BETWEEN 0 AND 6),
    start_time        TEXT NOT NULL CHECK (start_time GLOB '[0-2][0-9]:[0-5][0-9]'),
    end_time          TEXT NOT NULL CHECK (end_time GLOB '[0-2][0-9]:[0-5][0-9]'),
    valid_from        TEXT NOT NULL DEFAULT (date('now')),
    valid_to          TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (start_time < end_time),
    CHECK (valid_to IS NULL OR valid_to >= valid_from),
    UNIQUE (employee_id, weekday, valid_from)
);

CREATE TABLE schedule_exceptions (
    exception_id      INTEGER PRIMARY KEY,
    employee_id       INTEGER NOT NULL,
    exception_date    TEXT NOT NULL,
    start_time        TEXT,
    end_time          TEXT,
    reason            TEXT NOT NULL DEFAULT 'Изменение графика'
                      CHECK (length(trim(reason)) > 0),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (
        (start_time IS NULL AND end_time IS NULL)
        OR
        (start_time IS NOT NULL AND end_time IS NOT NULL AND start_time < end_time)
    ),
    UNIQUE (employee_id, exception_date, start_time, end_time)
);

CREATE TABLE services (
    service_id        INTEGER PRIMARY KEY,
    service_name      TEXT NOT NULL UNIQUE CHECK (length(trim(service_name)) > 0),
    description       TEXT,
    duration_minutes  INTEGER NOT NULL CHECK (duration_minutes BETWEEN 5 AND 1440),
    price             NUMERIC NOT NULL CHECK (price >= 0),
    is_available      INTEGER NOT NULL DEFAULT 1 CHECK (is_available IN (0, 1))
);

CREATE TABLE appointments (
    appointment_id    INTEGER PRIMARY KEY,
    employee_id       INTEGER NOT NULL,
    customer_name     TEXT NOT NULL CHECK (length(trim(customer_name)) > 0),
    customer_phone    TEXT NOT NULL CHECK (length(trim(customer_phone)) >= 5),
    starts_at         TEXT NOT NULL,
    ends_at           TEXT NOT NULL,
    status            TEXT NOT NULL DEFAULT 'Запланирована'
                      CHECK (status IN ('Запланирована', 'Подтверждена',
                                        'Выполнена', 'Отменена', 'Неявка')),
    notes             TEXT,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (ends_at > starts_at)
);

CREATE TABLE appointment_services (
    appointment_service_id INTEGER PRIMARY KEY,
    appointment_id    INTEGER NOT NULL,
    service_id        INTEGER NOT NULL,
    price_at_booking  NUMERIC NOT NULL CHECK (price_at_booking >= 0),
    duration_at_booking INTEGER NOT NULL CHECK (duration_at_booking > 0),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(service_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE performed_services (
    performed_service_id INTEGER PRIMARY KEY,
    appointment_service_id INTEGER NOT NULL UNIQUE,
    completed_at      TEXT NOT NULL DEFAULT (datetime('now')),
    actual_price      NUMERIC NOT NULL CHECK (actual_price >= 0),
    actual_duration_minutes INTEGER NOT NULL CHECK (actual_duration_minutes > 0),
    commission_percent_snapshot REAL NOT NULL
                      CHECK (commission_percent_snapshot BETWEEN 0 AND 100),
    notes             TEXT,
    FOREIGN KEY (appointment_service_id)
        REFERENCES appointment_services(appointment_service_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Не разрешаем записывать клиента к уволенному сотруднику.
CREATE TRIGGER appointments_active_employee_insert
BEFORE INSERT ON appointments
FOR EACH ROW
WHEN (SELECT dismissed_at FROM employees WHERE employee_id = NEW.employee_id) IS NOT NULL
 AND date(NEW.starts_at) > (SELECT dismissed_at FROM employees WHERE employee_id = NEW.employee_id)
BEGIN
    SELECT RAISE(ABORT, 'Нельзя создать запись к уволенному мастеру на дату после увольнения');
END;

CREATE TRIGGER appointments_active_employee_update
BEFORE UPDATE OF employee_id ON appointments
FOR EACH ROW
WHEN (SELECT dismissed_at FROM employees WHERE employee_id = NEW.employee_id) IS NOT NULL
 AND date(NEW.starts_at) > (SELECT dismissed_at FROM employees WHERE employee_id = NEW.employee_id)
BEGIN
    SELECT RAISE(ABORT, 'Нельзя назначить запись уволенному мастеру на дату после увольнения');
END;

-- Запрещаем пересекающиеся записи одного мастера (отменённые записи не учитываются).
CREATE TRIGGER appointments_no_overlap_insert
BEFORE INSERT ON appointments
FOR EACH ROW
WHEN NEW.status <> 'Отменена'
 AND EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.employee_id = NEW.employee_id
      AND a.status <> 'Отменена'
      AND NEW.starts_at < a.ends_at
      AND NEW.ends_at > a.starts_at
 )
BEGIN
    SELECT RAISE(ABORT, 'У мастера уже есть запись на это время');
END;

CREATE TRIGGER appointments_no_overlap_update
BEFORE UPDATE OF employee_id, starts_at, ends_at, status ON appointments
FOR EACH ROW
WHEN NEW.status <> 'Отменена'
 AND EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.employee_id = NEW.employee_id
      AND a.appointment_id <> NEW.appointment_id
      AND a.status <> 'Отменена'
      AND NEW.starts_at < a.ends_at
      AND NEW.ends_at > a.starts_at
 )
BEGIN
    SELECT RAISE(ABORT, 'У мастера уже есть запись на это время');
END;

-- Тестовые сотрудники: один сотрудник уволен, его история сохранена.
INSERT INTO employees
(employee_id, last_name, first_name, middle_name, phone, email, position,
 commission_percent, hired_at, dismissed_at)
VALUES
(1, 'Иванов', 'Алексей', 'Сергеевич', '+79990000001', 'ivanov@example.com',
 'Мастер', 35.0, '2022-03-01', NULL),
(2, 'Петров', 'Дмитрий', 'Олегович', '+79990000002', 'petrov@example.com',
 'Мастер', 30.0, '2023-06-15', NULL),
(3, 'Сидоров', 'Игорь', NULL, '+79990000003', 'sidorov@example.com',
 'Мастер', 25.0, '2020-02-10', '2025-08-31'),
(4, 'Смирнова', 'Анна', 'Павловна', '+79990000004', 'smirnova@example.com',
 'Администратор', 0.0, '2024-01-10', NULL);

INSERT INTO employee_schedule
(schedule_id, employee_id, weekday, start_time, end_time, valid_from, valid_to)
VALUES
(1, 1, 1, '09:00', '18:00', '2025-01-01', NULL),
(2, 1, 2, '09:00', '18:00', '2025-01-01', NULL),
(3, 1, 3, '09:00', '18:00', '2025-01-01', NULL),
(4, 1, 4, '09:00', '18:00', '2025-01-01', NULL),
(5, 1, 5, '09:00', '17:00', '2025-01-01', NULL),
(6, 2, 1, '10:00', '19:00', '2025-01-01', NULL),
(7, 2, 2, '10:00', '19:00', '2025-01-01', NULL),
(8, 2, 3, '10:00', '19:00', '2025-01-01', NULL),
(9, 2, 4, '10:00', '19:00', '2025-01-01', NULL),
(10, 2, 5, '10:00', '19:00', '2025-01-01', NULL),
(11, 3, 1, '09:00', '17:00', '2024-01-01', '2025-08-31'),
(12, 3, 3, '09:00', '17:00', '2024-01-01', '2025-08-31');

INSERT INTO schedule_exceptions
(exception_id, employee_id, exception_date, start_time, end_time, reason)
VALUES
(1, 1, '2025-09-12', NULL, NULL, 'Отпуск'),
(2, 2, '2025-09-15', '10:00', '14:00', 'Сокращённый рабочий день');

INSERT INTO services
(service_id, service_name, description, duration_minutes, price, is_available)
VALUES
(1, 'Замена масла', 'Замена моторного масла и фильтра', 45, 2500.00, 1),
(2, 'Диагностика двигателя', 'Компьютерная диагностика', 60, 1800.00, 1),
(3, 'Замена тормозных колодок', 'Замена колодок на одной оси', 90, 4500.00, 1),
(4, 'Шиномонтаж', 'Сезонный шиномонтаж комплекта', 60, 3200.00, 1),
(5, 'Регулировка развала-схождения', 'Проверка и регулировка углов колёс', 50, 2800.00, 1);

-- Тестовые записи не пересекаются по времени у одного мастера.
INSERT INTO appointments
(appointment_id, employee_id, customer_name, customer_phone, starts_at, ends_at,
 status, notes, created_at)
VALUES
(1, 1, 'Сергей Кузнецов', '+79991110001', '2025-09-10 09:00:00',
 '2025-09-10 10:45:00', 'Выполнена', 'Плановое обслуживание', '2025-09-01 12:00:00'),
(2, 2, 'Мария Орлова', '+79991110002', '2025-09-10 10:00:00',
 '2025-09-10 11:00:00', 'Выполнена', NULL, '2025-09-02 10:00:00'),
(3, 3, 'Павел Волков', '+79991110003', '2025-07-15 09:00:00',
 '2025-07-15 10:00:00', 'Выполнена', 'Историческая запись уволенного мастера', '2025-07-01 09:00:00'),
(4, 1, 'Олег Миронов', '+79991110004', '2025-09-11 11:00:00',
 '2025-09-11 12:00:00', 'Запланирована', NULL, '2025-09-05 15:00:00'),
(5, 2, 'Елена Белова', '+79991110005', '2025-09-12 12:00:00',
 '2025-09-12 13:30:00', 'Отменена', 'Клиент отменил запись', '2025-09-06 11:00:00');

INSERT INTO appointment_services
(appointment_service_id, appointment_id, service_id, price_at_booking, duration_at_booking)
VALUES
(1, 1, 1, 2500.00, 45),
(2, 1, 2, 1800.00, 60),
(3, 2, 2, 1800.00, 60),
(4, 3, 4, 3200.00, 60),
(5, 4, 3, 4500.00, 90),
(6, 5, 1, 2500.00, 45);

INSERT INTO performed_services
(performed_service_id, appointment_service_id, completed_at, actual_price,
 actual_duration_minutes, commission_percent_snapshot, notes)
VALUES
(1, 1, '2025-09-10 09:50:00', 2500.00, 45, 35.0, NULL),
(2, 2, '2025-09-10 10:40:00', 1800.00, 50, 35.0, 'Диагностика выполнена'),
(3, 3, '2025-09-10 11:00:00', 1800.00, 60, 30.0, NULL),
(4, 4, '2025-07-15 10:00:00', 3200.00, 60, 25.0,
 'Работа уволенного сотрудника сохранена');

COMMIT;

-- Пример отчёта по зарплате мастеров за произвольный период.
-- Измените границы периода в условиях WHERE.
-- SELECT e.employee_id, e.last_name, e.first_name,
--        SUM(p.actual_price) AS revenue,
--        SUM(p.actual_price * p.commission_percent_snapshot / 100.0) AS salary
-- FROM employees e
-- JOIN appointments a ON a.employee_id = e.employee_id
-- JOIN appointment_services aps ON aps.appointment_id = a.appointment_id
-- JOIN performed_services p ON p.appointment_service_id = aps.appointment_service_id
-- WHERE p.completed_at >= '2025-09-01 00:00:00'
--   AND p.completed_at <  '2025-10-01 00:00:00'
-- GROUP BY e.employee_id, e.last_name, e.first_name
-- ORDER BY e.last_name;
