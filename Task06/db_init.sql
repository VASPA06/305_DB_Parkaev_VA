PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS completed_works;
DROP TABLE IF EXISTS appointment_services;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS service_history;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS masters;
PRAGMA foreign_keys = ON;
CREATE TABLE masters (
    master_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL CHECK (first_name != ''),
    last_name TEXT NOT NULL CHECK (last_name != ''),
    hire_date DATE NOT NULL,
    fire_date DATE,
    salary_percent REAL NOT NULL CHECK (salary_percent BETWEEN 0 AND 100),
    is_active BOOLEAN GENERATED ALWAYS AS (fire_date IS NULL) STORED,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_masters_last_name ON masters(last_name);
CREATE INDEX idx_masters_active ON masters(is_active);

-- 2. Справочник услуг
CREATE TABLE services (
    service_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    price REAL NOT NULL CHECK (price >= 0),
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. Записи клиентов
CREATE TABLE appointments (
    appointment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_name TEXT NOT NULL,
    client_phone TEXT,
    master_id INTEGER NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('planned', 'completed', 'cancelled', 'no_show')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (master_id) REFERENCES masters(master_id) ON DELETE RESTRICT
);

CREATE INDEX idx_appointments_master_time ON appointments(master_id, start_time);
CREATE INDEX idx_appointments_status ON appointments(status);

-- 4. Связь записей и услуг (много-ко-многим)
CREATE TABLE appointment_services (
    appointment_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    PRIMARY KEY (appointment_id, service_id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE RESTRICT
);

-- 5. Фактически выполненные работы
CREATE TABLE completed_works (
    work_id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER,
    master_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    completed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    duration_minutes INTEGER,
    price REAL NOT NULL,
    notes TEXT,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    FOREIGN KEY (master_id) REFERENCES masters(master_id) ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE RESTRICT
);

CREATE INDEX idx_completed_works_master_date ON completed_works(master_id, completed_at);
CREATE INDEX idx_completed_works_date ON completed_works(completed_at);

-- 6. История изменений услуг
CREATE TABLE service_history (
    history_id INTEGER PRIMARY KEY AUTOINCREMENT,
    service_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    price REAL NOT NULL,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT,
    reason TEXT,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
);

-- Триггеры для логирования изменений
CREATE TRIGGER tr_service_update_history
AFTER UPDATE OF name, duration_minutes, price ON services
FOR EACH ROW
WHEN OLD.name != NEW.name OR OLD.duration_minutes != NEW.duration_minutes OR OLD.price != NEW.price
BEGIN
    INSERT INTO service_history (service_id, name, duration_minutes, price, changed_by, reason)
    VALUES (OLD.service_id, OLD.name, OLD.duration_minutes, OLD.price, 'system', 'updated');
END;

CREATE TRIGGER tr_service_insert_history
AFTER INSERT ON services
FOR EACH ROW
BEGIN
    INSERT INTO service_history (service_id, name, duration_minutes, price, changed_by, reason)
    VALUES (NEW.service_id, NEW.name, NEW.duration_minutes, NEW.price, 'system', 'created');
END;

-- Мастера: 3 работающих, 2 уволенных
INSERT INTO masters (first_name, last_name, hire_date, fire_date, salary_percent) VALUES
('Алексей', 'Иванов', '2023-03-01', NULL, 40.0),
('Мария', 'Смирнова', '2023-05-15', NULL, 35.0),
('Дмитрий', 'Петров', '2022-11-10', NULL, 45.0),
('Елена', 'Кузнецова', '2020-08-20', '2024-12-15', 50.0),   -- уволена
('Сергей', 'Волков', '2021-01-10', '2025-02-28', 48.0);     -- уволен

-- Услуги (8 шт.)
INSERT INTO services (name, duration_minutes, price) VALUES
('Замена масла', 30, 800.0),
('Диагностика подвески', 45, 1200.0),
('Замена тормозных колодок', 60, 2500.0),
('Регулировка сцепления', 90, 3000.0),
('Замена воздушного фильтра', 15, 300.0),
('Чип-тюнинг', 120, 8000.0),
('Замена свечей зажигания', 40, 1500.0),
('Компьютерная диагностика', 30, 1000.0);

-- Записи клиентов (10 записей → appointment_id от 1 до 10)
INSERT INTO appointments (client_name, client_phone, master_id, start_time, end_time, status) VALUES
-- К Иванову (master_id=1)
('Иван Петров', '+79001112233', 1, '2025-11-29 09:00:00', '2025-11-29 09:30:00', 'completed'),
('Анна Соколова', '+79004445566', 1, '2025-11-29 10:00:00', '2025-11-29 11:30:00', 'completed'),
('Олег Морозов', '+79007778899', 1, '2025-11-30 14:00:00', '2025-11-30 14:30:00', 'planned'),

-- К Смирновой (master_id=2)
('Татьяна Лебедева', '+79112223344', 2, '2025-11-29 12:00:00', '2025-11-29 12:45:00', 'completed'),
('Виктор Новиков', '+79115556677', 2, '2025-11-30 10:00:00', '2025-11-30 12:00:00', 'cancelled'),

-- К Петрову (master_id=3)
('Павел Зайцев', '+79223334455', 3, '2025-11-29 15:00:00', '2025-11-29 16:30:00', 'completed'),
('Екатерина Орлова', '+79226667788', 3, '2025-12-01 09:00:00', '2025-12-01 11:00:00', 'planned'),

-- К Кузнецовой (master_id=4, до увольнения)
('Роман Семёнов', '+79331112233', 4, '2024-12-10 11:00:00', '2024-12-10 12:30:00', 'completed'),
('Дарья Фролова', '+79334445566', 4, '2024-12-12 16:00:00', '2024-12-12 16:30:00', 'completed'),

-- К Волкову (master_id=5, до увольнения)
('Артём Гусев', '+79445556677', 5, '2025-02-20 13:00:00', '2025-02-20 15:00:00', 'completed');

-- Связи записей и услуг
INSERT INTO appointment_services (appointment_id, service_id) VALUES
-- Запись 1: замена масла
(1, 1),
-- Запись 2: диагностика + фильтр
(2, 2), (2, 5),
-- Запись 4: диагностика
(4, 8),
-- Запись 6: колодки + свечи
(6, 3), (6, 7),
-- Запись 8: сцепление
(8, 4),
-- Запись 9: замена масла
(9, 1),
-- Запись 10: чип-тюнинг
(10, 6);

-- Фактически выполненные работы (13 шт., все FK корректны)
INSERT INTO completed_works (appointment_id, master_id, service_id, completed_at, duration_minutes, price, notes) VALUES
-- По записи 1 (Иван Петров)
(1, 1, 1, '2025-11-29 09:25:00', 25, 800.0, 'Быстро, масло Castrol'),
(1, 1, 5, '2025-11-29 09:30:00', 8, 300.0, 'Добавили фильтр по просьбе'),

-- По записи 2 (Анна Соколова)
(2, 1, 2, '2025-11-29 10:40:00', 40, 1200.0, NULL),
(2, 1, 5, '2025-11-29 11:15:00', 10, 300.0, 'Фильтр Mann'),

-- По записи 4 (Татьяна Лебедева)
(4, 2, 8, '2025-11-29 12:25:00', 25, 1000.0, NULL),

-- По записи 6 (Павел Зайцев)
(6, 3, 3, '2025-11-29 15:50:00', 55, 2500.0, 'Колодки ATE'),
(6, 3, 7, '2025-11-29 16:20:00', 35, 1500.0, NULL),
(6, 3, 2, '2025-11-29 16:25:00', 30, 1200.0, 'Диагностика заодно'),

-- По записи 8 (Роман Семёнов, master_id=4)
(8, 4, 4, '2024-12-10 12:20:00', 85, 3000.0, 'Сцепление отрегулировано точно'),

-- По записи 9 (Дарья Фролова, master_id=4)
(9, 4, 1, '2024-12-12 16:20:00', 20, 800.0, 'Масло Shell'),

-- По записи 10 (Артём Гусев, master_id=5)
(10, 5, 6, '2025-02-20 14:50:00', 110, 8000.0, 'Программа прошивки v2.1'),

-- Без записи («с улицы»)
(NULL, 3, 1, '2025-11-30 17:10:00', 30, 800.0, 'Срочно, клиент ждал'),
(NULL, 1, 8, '2025-12-01 12:05:00', 20, 1000.0, 'Быстрая диагностика ошибки');

-- Обновление цены → сработает триггер и добавит запись в service_history
UPDATE services SET price = 900.0 WHERE name = 'Замена масла';

-- Добавление новой услуги → также попадёт в service_history
INSERT INTO services (name, duration_minutes, price) VALUES
('Мойка инжектора', 60, 3500.0);