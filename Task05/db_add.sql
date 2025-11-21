INSERT INTO user (name, family, gender, email, occupation) VALUES 
('Vasily', 'Parkaev', 'M', 'parkaev.v@example.com', 'Student'), -- ЭТО ТЫ
('Dmitry', 'Mukaseev', 'M', 'mukaseev.d@example.com', 'Student'),
('Vladislav', 'Naumkin', 'M', 'naumkin.v@example.com', 'Student'),
('Dmitry', 'Polkovnikov', 'M', 'polkovnikov.d@example.com', 'Student'),
('Dmitry', 'Puzakov', 'M', 'puzakov.d@example.com', 'Student');

INSERT INTO movies (title, year) VALUES 
('Interstellar', 2014),
('Joker', 2019),
('The Hangover', 2009);

-- Интерстеллар -> Sci-Fi
INSERT INTO movies_genres (movie_id, genre_id) VALUES (
    (SELECT id FROM movies WHERE title = 'Interstellar'),
    (SELECT id FROM genres WHERE name = 'Sci-Fi')
);

-- Джокер -> Drama
INSERT INTO movies_genres (movie_id, genre_id) VALUES (
    (SELECT id FROM movies WHERE title = 'Joker'),
    (SELECT id FROM genres WHERE name = 'Drama')
);

-- Мальчишник в Вегасе -> Comedy
INSERT INTO movies_genres (movie_id, genre_id) VALUES (
    (SELECT id FROM movies WHERE title = 'The Hangover'),
    (SELECT id FROM genres WHERE name = 'Comedy')
);

- Оценка 5 для Интерстеллара
INSERT INTO ratings (user_id, movie_id, rating) VALUES (
    (SELECT id FROM user WHERE family = 'Parkaev' AND name = 'Vasily'),
    (SELECT id FROM movies WHERE title = 'Interstellar'),
    5
);

-- Оценка 5 для Джокера
INSERT INTO ratings (user_id, movie_id, rating) VALUES (
    (SELECT id FROM user WHERE family = 'Parkaev' AND name = 'Vasily'),
    (SELECT id FROM movies WHERE title = 'Joker'),
    5
);

-- Оценка 4 для Мальчишника
INSERT INTO ratings (user_id, movie_id, rating) VALUES (
    (SELECT id FROM user WHERE family = 'Parkaev' AND name = 'Vasily'),
    (SELECT id FROM movies WHERE title = 'The Hangover'),
    4
);