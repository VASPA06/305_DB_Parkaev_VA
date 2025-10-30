#!/bin/bash
@echo off
chcp 65001
echo Инициализация базы данных...
sqlite3 movies_rating.db < db_init.sql
echo.
echo 1. Составить список фильмов, имеющих хотя бы одну оценку. Список фильмов отсортировать по году выпуска и по названиям. В списке оставить первые 10 фильмов.
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT movies.title, movies.year, count(rating) FROM movies INNER JOIN ratings ON movies.id = ratings.movie_id GROUP BY movies.title, movies.year HAVING count(rating) ^>= 1 ORDER BY movies.year DESC, title LIMIT 10;"
echo.
echo 2. Вывести список всех пользователей, фамилии (не имена!) которых начинаются на букву 'A'. Полученный список отсортировать по дате регистрации. В списке оставить первых 5 пользователей.
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT * from users WHERE name LIKE '%% A%%' ORDER BY register_date LIMIT 5;"
echo.
echo 3. Написать запрос, возвращающий информацию о рейтингах в более читаемом формате: имя и фамилия эксперта, название фильма, год выпуска, оценка и дата оценки в формате ГГГГ-ММ-ДД. Отсортировать данные по имени эксперта, затем названию фильма и оценке. В списке оставить первые 50 записей.
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT users.name, movies.title, movies.year, ratings.rating, movie_id, date(ratings.timestamp, 'unixepoch') FROM users INNER JOIN ratings ON user_id = users.id INNER JOIN movies ON movies.id = movie_id ORDER BY users.name, movies.title, ratings.rating LIMIT 50;"
echo.
echo 4. Вывести список фильмов с указанием тегов, которые были им присвоены пользователями. Сортировать по году выпуска, затем по названию фильма, затем по тегу. В списке оставить первые 40 записей.
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT movies.*, tags.tag FROM movies INNER JOIN tags ON tags.movie_id = movies.id ORDER BY year, title, tag LIMIT 40;"
echo.
echo 5. Вывести список самых свежих фильмов. В список должны войти все фильмы последнего года выпуска, имеющиеся в базе данных. Запрос должен быть универсальным, не зависящим от исходных данных (нужный год выпуска должен определяться в запросе, а не жестко задаваться).
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT movies.* FROM movies WHERE year = (SELECT MAX(year) FROM movies);"
echo.
echo 6. Найти все драмы, выпущенные после 2005 года, которые понравились женщинам (оценка не ниже 4.5). Для каждого фильма в этом списке вывести название, год выпуска и количество таких оценок. Результат отсортировать по году выпуска и названию фильма.
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT movies.title, movies.year, count(ratings.rating) FROM movies INNER JOIN ratings ON ratings.movie_id = movies.id INNER JOIN users ON ratings.user_id = users.id WHERE year ^>= 2005 AND rating ^>= 4.5 AND gender = 'female' AND movies.genres LIKE '%%Drama%%' GROUP BY movies.id, movies.title, movies.year ORDER BY movies.year, movies.title;"
echo.
echo 7. Провести анализ востребованности ресурса - вывести количество пользователей, регистрировавшихся на сайте в каждом году. Найти, в каких годах регистрировалось больше всего и меньше всего пользователей.
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH YearlyCounts AS (SELECT count(users.id) AS quantity_registers, strftime('%%Y', register_date) AS register_year FROM users GROUP BY strftime('%%Y', register_date)) SELECT quantity_registers, register_year FROM YearlyCounts WHERE quantity_registers = (SELECT MIN(quantity_registers) FROM YearlyCounts) OR quantity_registers = (SELECT MAX(quantity_registers) FROM YearlyCounts);"
echo.
echo Готово!
pause