import curses
import sys
import os

COLS = 48
ROWS = 32
RAM_SIZE = COLS * ROWS
DEFAULT_CHAR = 0x20

# Mapa de caracteres gráficos para ASCII 1–31
SPECIAL_GLYPHS = {
    0x00: '␀', 0x01: '☺', 0x02: '☻', 0x03: '♥', 0x04: '♦', 0x05: '♣',
    0x06: '♠', 0x07: '•', 0x08: '◘', 0x09: '→', 0x0A: '↵', 0x0B: '♂',
    0x0C: '♀', 0x0D: '♪', 0x0E: '♫', 0x0F: '☼', 0x10: '►', 0x11: '◄',
    0x12: '↕', 0x13: '‼', 0x14: '¶', 0x15: '§', 0x16: '▬', 0x17: '↨',
    0x18: '↑', 0x19: '↓', 0x1A: '→', 0x1B: '←', 0x1C: '∟', 0x1D: '↔',
    0x1E: '▲', 0x1F: '■'
}

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
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_CYAN, -1)  # Para caracteres especiales

    stdscr.clear()
    archivo = sys.argv[1] if len(sys.argv) > 1 else "char_ram.mem"
    ram = cargar_ram(archivo)

    y, x = 0, 0
    modo_ascii = False
    buffer_num = ""

    while True:
        stdscr.clear()
        stdscr.addstr(0, 0, f"Editando {archivo} - F2: Guardar | ESC: Salir | Ctrl+G: ASCII especial")

        for row in range(ROWS):
            for col in range(COLS):
                ch_val = ram[row * COLS + col]
                try:
                    if ch_val < 32:
                        ch = SPECIAL_GLYPHS.get(ch_val, '·')
                        attr = curses.color_pair(1) | curses.A_BOLD
                    elif 32 <= ch_val <= 126:
                        ch = chr(ch_val)
                        attr = curses.A_NORMAL
                    else:
                        ch = '?'
                        attr = curses.A_DIM
                except:
                    ch = '?'
                    attr = curses.A_DIM

                if row == y and col == x:
                    stdscr.addstr(row + 1, col, ch, curses.A_REVERSE | attr)
                else:
                    stdscr.addstr(row + 1, col, ch, attr)

        current_char = ram[y * COLS + x]
        stdscr.addstr(ROWS + 2, 0, f"Cursor: fila={y:02} col={x:02} ASCII=0x{current_char:02X}   ")

        if modo_ascii:
            try:
                val = int(buffer_num)
                preview = SPECIAL_GLYPHS.get(val, chr(val)) if 1 <= val <= 31 else '?'
            except:
                preview = '?'
            stdscr.addstr(ROWS + 3, 0, f"[ASCII directo] Código: {buffer_num} → Carácter: {preview}")

        stdscr.move(y + 1, x)
        stdscr.refresh()
        key = stdscr.getch()

        if modo_ascii:
            if ord('0') <= key <= ord('9'):
                buffer_num += chr(key)
            elif key == 10:  # Enter para confirmar
                try:
                    val = int(buffer_num)
                    if 1 <= val <= 31:
                        ram[y * COLS + x] = val
                        x = min(x + 1, COLS - 1)
                except ValueError:
                    pass
                modo_ascii = False
                buffer_num = ""
            elif key == 27:  # ESC para cancelar
                modo_ascii = False
                buffer_num = ""
            else:
                modo_ascii = False
                buffer_num = ""
            continue

        if key == 27:  # ESC para salir del editor
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
        elif key == 7:  # Ctrl+G → modo ASCII
            modo_ascii = True
            buffer_num = ""
        elif 32 <= key <= 126:
            ram[y * COLS + x] = key
            x = min(x + 1, COLS - 1)

if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except Exception as e:
        print("Ocurrió un error:", e)
        input("Pulsa ENTER para cerrar...")
