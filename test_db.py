import pymysql

connection = pymysql.connect(
    host='localhost',
    user='fanni',
    password='salasana123',
    database='fannilahtinen_db'
)

try:
    with connection.cursor() as cursor:
        cursor.execute("SELECT VERSION();")
        version = cursor.fetchone()
        print(f"Yhteys onnistui! MariaDB versio: {version[0]}")
finally:
    connection.close()
