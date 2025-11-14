@echo off
chcp 65001
echo Инициализация базы данных...
sqlite3 movies_rating.db < db_init.sql
echo.
echo 1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u1.name as name_user_1, u2.name as name_user2, movies.title FROM users as u1 INNER JOIN users AS u2 ON u1.id < u2.id INNER JOIN ratings AS r1 ON r1.user_id = u1.id INNER JOIN ratings AS r2 ON r2.user_id = u2.id INNER JOIN movies ON r1.movie_id = movies.id WHERE r2.movie_id = r1.movie_id LIMIT 100;"
echo.
echo 2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT movies.title, users.name, ratings.rating, date(ratings.timestamp, 'unixepoch')  as date FROM movies INNER JOIN ratings ON movie_id = movies.id INNER JOIN users ON user_id = users.id GROUP BY users.name, movies.title, rating ORDER BY date LIMIT 10;"
echo.
echo 3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH AvgMoviesRatings AS (SELECT movies.title as title, movies.year as year, avg(ratings.rating) as avg_rating, CASE WHEN AVG(ratings.rating) > 4.5 THEN 'Да' ELSE 'Нет' END AS Рекомендуем FROM movies INNER JOIN ratings ON movies.id = ratings.movie_id GROUP BY movies.id) SELECT title, year, avg_rating, Рекомендуем FROM AvgMoviesRatings WHERE avg_rating = (SELECT max(avg_rating) FROM  AvgMoviesRatings) OR avg_rating = (SELECT min(avg_rating) FROM  AvgMoviesRatings) ORDER BY year, title;"
echo.
echo 4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT count(ratings.rating), avg(ratings.rating) FROM ratings INNER JOIN users ON user_id = users.id WHERE users.gender = 'male' AND CAST(strftime('%%Y', ratings.timestamp, 'unixepoch') AS INTEGER) BETWEEN 2011 AND 2014;"
echo.
echo 5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT movies.title, movies.year, avg(ratings.rating) as avg_rating, count(ratings.user_id) FROM ratings INNER JOIN movies ON movie_id = movies.id GROUP BY movie_id, movies.year, movies.title ORDER BY movies.year, movies.title LIMIT 20;"
echo.
echo 6. Определить самый распространенный жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE MakeGenresTable  AS( SELECT movies.id AS movie_id, CASE WHEN INSTR(movies.genres, '|') > 0 THEN substr(movies.genres, 1, instr(movies.genres, '|') - 1) ELSE '' END AS genre, CASE WHEN instr(movies.genres, '|') >0 THEN substr(movies.genres, 1, instr(movies.genres, '|') + 1) ELSE '' END AS genres FROM movies UNION ALL SELECT movie_id, CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, 1, INSTR(genres, '|') - 1) ELSE genres END, CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, INSTR(genres, '|') + 1) ELSE '' END FROM MakeGenresTable WHERE genres != '' ) select genre, count(*) FROM MakeGenresTable GROUP BY genre ORDER BY COUNT(*) DESC LIMIT 1;"
echo.
echo 7. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя - Дата регистрации'.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT substr(users.name, instr(users.name, ' ') + 1) || ' ' || substr(users.name, 1, instr(users.name, ' ') - 1)  || ' - ' || users.register_date as users FROM users ORDER BY register_date DESC LIMIT 10;"
echo.
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE MyBirthdays(birthday_date) AS ( SELECT '2006-01-31' UNION ALL SELECT date(birthday_date, '+1 year') FROM MyBirthdays WHERE strftime('%%Y', birthday_date) < strftime('%%Y', 'now') ) SELECT birthday_date AS \"Дата\", CASE strftime('%%w', birthday_date) WHEN '0' THEN 'Воскресенье' WHEN '1' THEN 'Понедельник' WHEN '2' THEN 'Вторник' WHEN '3' THEN 'Среда' WHEN '4' THEN 'Четверг' WHEN '5' THEN 'Пятница' WHEN '6' THEN 'Суббота' END AS \"День недели\" FROM MyBirthdays;"
echo.
echo 8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году.
echo ----------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE MyBirthdays(birthday_date) AS ( SELECT '2006-01-31' UNION ALL SELECT date(birthday_date, '+1 year') FROM MyBirthdays WHERE strftime('%%Y', birthday_date) < strftime('%%Y', 'now') ) SELECT birthday_date AS \"Дата\", CASE strftime('%%w', birthday_date) WHEN '0' THEN 'Воскресенье' WHEN '1' THEN 'Понедельник' WHEN '2' THEN 'Вторник' WHEN '3' THEN 'Среда' WHEN '4' THEN 'Четверг' WHEN '5' THEN 'Пятница' WHEN '6' THEN 'Суббота' END AS \"День недели\" FROM MyBirthdays;"
echo.
echo Готово!
pause