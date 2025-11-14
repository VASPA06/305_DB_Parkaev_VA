import os
import csv
import re

DATASET_DIR = '../dataset'
DB_INIT_SCRIPT = 'db_init.sql'

TABLES = {
    'movies': {
        'file': 'movies.csv',
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('title', 'TEXT'),
            ('year', 'INTEGER'),
            ('genres', 'TEXT')
        ]
    },
    'ratings': {
        'file': 'ratings.csv',
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('user_id', 'INTEGER'),
            ('movie_id', 'INTEGER'),
            ('rating', 'REAL'),
            ('timestamp', 'INTEGER'),
        ]
    },
    'tags': {
        'file': 'tags.csv',
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('user_id', 'INTEGER'),
            ('movie_id', 'INTEGER'),
            ('tag', 'TEXT'),
            ('timestamp', 'INTEGER'),
        ]
    },
    'users': {
        'file': 'users.txt',
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('name', 'TEXT'),
            ('email', 'TEXT'),
            ('gender', 'TEXT'),
            ('register_date', 'TEXT'),
            ('occupation', 'TEXT')
        ]
    }
}


def generate_sql_script():
    print(f"Начало генерации файла {DB_INIT_SCRIPT}...")
    with open(DB_INIT_SCRIPT, 'w', encoding='utf-8') as f:
        for table_name, table_info in TABLES.items():
            f.write(f"DROP TABLE IF EXISTS {table_name};\n")
            columns_def = ', '.join([f'"{col[0]}" {col[1]}' for col in table_info['columns']])
            f.write(f"CREATE TABLE {table_name} ({columns_def});\n\n")
            source_file_path = os.path.join(DATASET_DIR, table_info['file'])
            if not os.path.exists(source_file_path):
                print(f"!!! ОШИБКА: Не найден исходный файл: {source_file_path}")
                continue
            if table_name == 'users':
                _process_users_file(f, source_file_path, table_name, table_info)
            else:
                _process_csv_file(f, source_file_path, table_name, table_info)

            f.write('\n')
    print(f"Генерация {DB_INIT_SCRIPT} завершена!")


def _process_users_file(f, file_path, table_name, table_info):
    """Специальная обработка для users.txt с разделителем |"""
    column_names = [col[0] for col in table_info['columns']]
    with open(file_path, 'r', encoding='utf-8') as txt_file:
        for line_num, line in enumerate(txt_file, start=1):
            line = line.strip()
            if not line:
                continue
            parts = line.split('|')
            if len(parts) == 5:
                name, email, gender, register_date, occupation = parts
                user_id = line_num
            elif len(parts) == 6:
                user_id, name, email, gender, register_date, occupation = parts
            else:
                print(f"Пропуск строки {line_num} в users.txt: неожиданное количество полей ({len(parts)})")
                continue
            values = [
                str(user_id),
                f"'{name.replace("'", "''")}'",
                f"'{email.replace("'", "''")}'",
                f"'{gender.replace("'", "''")}'",
                f"'{register_date.replace("'", "''")}'",
                f"'{occupation.replace("'", "''")}'"
            ]
            f.write(f"INSERT INTO {table_name} ({', '.join(column_names)}) VALUES ({', '.join(values)});\n")

def _process_csv_file(f, file_path, table_name, table_info):
    """Обработка CSV файлов"""
    with open(file_path, 'r', encoding='utf-8') as csv_file:
        reader = csv.reader(csv_file)
        header = next(reader)
        column_names = [col[0] for col in table_info['columns']]
        for row_num, row in enumerate(reader, start=2):
            if not row:
                continue
            values = []
            if table_name == 'movies':
                if len(row) < 2:
                    print(f"Пропуск строки {row_num} в {table_info['file']}: недостаточно столбцов ({len(row)})")
                    continue
                movie_id = row[0]
                genres = row[-1]
                full_title = ','.join(row[1:-1])
                if full_title.startswith('"') and full_title.endswith('"'):
                    full_title = full_title[1:-1]
                clean_title = full_title.strip()
                year = 'NULL'
                match = re.search(r'\s*\((\d{4})\)$', full_title)
                if match:
                    year = match.group(1)
                    clean_title = full_title[:match.start()].strip()
                values.append(movie_id)
                values.append(f"'{clean_title.replace("'", "''")}'")
                values.append(year)
                values.append(f"'{genres.replace("'", "''")}'")
            elif table_name == 'ratings':
                rating_id = row_num - 1
                user_id, movie_id, rating, timestamp = row
                values.extend([str(rating_id), user_id, movie_id, rating, timestamp])
            elif table_name == 'tags':
                if len(row) != 4:
                    print(f"Пропуск строки {row_num} в {table_info['file']}: {len(row)} значений, ожидается 4")
                    continue
                tag_id = row_num - 1
                user_id, movie_id, tag, timestamp = row
                timestamp = timestamp.replace('%', '')
                values.extend([str(tag_id), user_id, movie_id, f"'{tag.replace("'", "''")}'", timestamp])
            if len(values) != len(column_names):
                print(
                    f"Пропуск строки {row_num} в {table_info['file']}: {len(values)} значений для {len(column_names)} колонок")
                continue
            if values:
                f.write(
                    f"INSERT INTO {table_name} ({', '.join(map(str, column_names))}) VALUES ({', '.join(map(str, values))});\n")
if __name__ == '__main__':
    generate_sql_script()