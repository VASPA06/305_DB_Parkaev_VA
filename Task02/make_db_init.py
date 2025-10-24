import os
import csv

DATASET_DIR = 'dataset'
DB_INIT_SCRIPT = 'db.sql'
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
            ('user_id', 'INTEGER '),
            ('movie_id', 'INTEGER '),
            ('rating', 'REAL'),
            ('timestamp', 'INTEGER'),
        ]
    },
    'tags': {
        'file': 'tags.csv',
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('user_id', 'INTEGER '),
            ('movie_id', 'INTEGER '),
            ('timestamp', 'REAL'),
        ]
    },
    'users': {
        'file': 'users.csv',
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
            with open(source_file_path, 'r', encoding='utf-8') as csv_file:
                reader = csv.reader(csv_file)
                header = next(reader)
                column_names = [col[0] for col in table_info['columns']]
                column_types = {col[0]: col[1] for col in table_info['columns']}
                for row in reader:
                    values = []
                    for i, value in enumerate(row):
                        col_name = column_names[i]
                        col_type = column_types[col_name]
                        if 'TEXT' in col_type or 'DATE' in col_type:
                            processed_value = f"'{value.replace("'", "''")}'"
                        elif value == '':
                            processed_value = 'NULL'
                        else:
                            processed_value = value
                        values.append(processed_value)
                        f.write(f"INSERT INTO {table_name} ({', '.join(column_names)}) VALUES ({', '.join(values)});\n")
                f.write('\n')
if __name__ == '__main__':
    generate_sql_script()