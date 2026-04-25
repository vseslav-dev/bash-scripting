#!/usr/bin/env python3
import sys

def convert_to_bin():
    if len(sys.argv) < 3:
        print("Использование: ./bins.py <кол-во_байт> <число>")
        print("Пример: ./bins.py 1 255")
        return

    try:
        size_bytes = int(sys.argv[1])
        number = int(sys.argv[2])
    except ValueError:
        print("Ошибка: Аргументы должны быть целыми числами.")
        return

    if size_bytes not in [1, 2, 4, 8]:
        print("Ошибка: Поддерживается только 1, 2, 4 или 8 байт.")
        return

    # Вычисляем лимиты
    bits = size_bytes * 8
    max_val = (1 << bits) - 1

    if number > max_val or number < 0:
        print(f"Ошибка: Число {number} не умещается в {size_bytes} байт(а).")
        print(f"Максимальное значение для {bits} бит: {max_val}")
        return

    # Формируем двоичную строку с ведущими нулями
    b_str = f"{number:0{bits}b}"
    
    # Разбиваем по 4 бита (нибблы)
    nibbles = [b_str[i:i+4] for i in range(0, len(b_str), 4)]
    
    # Выводим результат: каждые 2 байта (4 ниббла) на новой строке
    for i in range(0, len(nibbles), 4):
        print(" ".join(nibbles[i:i+4]))

if __name__ == "__main__":
    convert_to_bin()
