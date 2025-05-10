# // Project: OSD Overlay
# // File: char_ram_editor_curses.py
# // Description: Overlay module for displaying OSD (On-Screen Display) characters
# //              on a VGA screen. It uses a character RAM and a font ROM to
# //              generate the pixel data for the OSD characters.
# // Author: @RndMnkIII
# // Date: 2025-05-09
# // License: MIT
# //
import curses
import sys
import os

COLS = 48
ROWS = 32
RAM_SIZE = COLS * ROWS
DEFAULT_CHAR = 0x20

def cargar_ram(nombre_archivo):
    ram = [DEFAULT_CHAR] * RAM_SIZE
    if os.path.exists(nombre_archivo):
        with open(nombre_archivo, 'r') as f:
            lines = f.readlines()
            for i, line in enumerate(lines):
                if i < RAM_SIZE:
                    try:
                        ram[i] = int(line.strip(), 16)
                    except ValueError:
                        pass
    return ram

def guardar_ram(nombre_archivo, ram):
    with open(nombre_archivo, 'w') as f:
        for val in ram:
            f.write(f"{val:02X}\n")

def main(stdscr):
    curses.curs_set(1)
    stdscr.clear()
    archivo = sys.argv[1] if len(sys.argv) > 1 else "char_ram.mem"
    ram = cargar_ram(archivo)

    y, x = 0, 0
    while True:
        stdscr.clear()
        stdscr.addstr(0, 0, f"Editando {archivo} - F2: Guardar | ESC: Salir")
        for row in range(ROWS):
            linea = ''.join(chr(ram[row * COLS + col]) for col in range(COLS))
            for col in range(COLS):
                ch = chr(ram[row * COLS + col])
                if row == y and col == x:
                    stdscr.addstr(row + 1, col, ch, curses.A_REVERSE)
                else:
                    stdscr.addstr(row + 1, col, ch)

        stdscr.move(y + 1, x)
        stdscr.addstr(ROWS + 2, 0, f"Cursor: fila={y:02} col={x:02}      ")
        stdscr.refresh()
        key = stdscr.getch()

        if key == 27:  # ESC
            break
        elif key == curses.KEY_UP and y > 0:
            y -= 1
        elif key == curses.KEY_DOWN and y < ROWS - 1:
            y += 1
        elif key == curses.KEY_LEFT and x > 0:
            x -= 1
        elif key == curses.KEY_RIGHT and x < COLS - 1:
            x += 1
        elif key == curses.KEY_F2:
            guardar_ram(archivo, ram)
            stdscr.addstr(ROWS + 2, 0, f"Guardado en {archivo}")
            stdscr.refresh()
            stdscr.getch()
        elif 32 <= key <= 126:  # Caracteres imprimibles
            ram[y * COLS + x] = key
            x = min(x + 1, COLS - 1)

if __name__ == "__main__":
    curses.wrapper(main)
