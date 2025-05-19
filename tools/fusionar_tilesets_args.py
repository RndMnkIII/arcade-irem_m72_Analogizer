from PIL import Image
import os
import sys

def fusionar_tilesets(png_paths, output_path, tile_size=(8, 8), tiles_por_fila=16):
    tiles = []
    for path in png_paths:
        img = Image.open(path).convert("1")  # 1-bit
        w, h = img.size
        for y in range(0, h, tile_size[1]):
            for x in range(0, w, tile_size[0]):
                tile = img.crop((x, y, x + tile_size[0], y + tile_size[1]))
                tiles.append(tile)

    total_tiles = len(tiles)
    filas = (total_tiles + tiles_por_fila - 1) // tiles_por_fila
    new_img = Image.new("1", (tiles_por_fila * tile_size[0], filas * tile_size[1]), color=1)

    for idx, tile in enumerate(tiles):
        tx = (idx % tiles_por_fila) * tile_size[0]
        ty = (idx // tiles_por_fila) * tile_size[1]
        new_img.paste(tile, (tx, ty))

    new_img.save(output_path)
    return output_path

def generar_tsx(output_image_path, tile_width=8, tile_height=8, spacing=0, margin=0, columns=16):
    img = Image.open(output_image_path)
    img_w, img_h = img.size
    tilecount = (img_w // tile_width) * (img_h // tile_height)
    name = os.path.splitext(os.path.basename(output_image_path))[0]

    tsx_content = '<?xml version="1.0" encoding="UTF-8"?>\n'
    tsx_content += f'<tileset version="1.10" tiledversion="1.10.2" name="{name}" '
    tsx_content += f'tilewidth="{tile_width}" tileheight="{tile_height}" spacing="{spacing}" margin="{margin}" '
    tsx_content += f'tilecount="{tilecount}" columns="{columns}">\n'
    tsx_content += f' <image source="{os.path.basename(output_image_path)}" width="{img_w}" height="{img_h}"/>\n'
    tsx_content += '</tileset>\n'

    tsx_path = output_image_path.replace(".png", ".tsx")
    with open(tsx_path, "w", encoding="utf-8") as f:
        f.write(tsx_content)
    return tsx_path

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python fusionar_tilesets.py salida.png tileset1.png tileset2.png ...")
        sys.exit(1)

    output_png = sys.argv[1]
    tileset_paths = sys.argv[2:]

    fusionar_tilesets(tileset_paths, output_png)
    generar_tsx(output_png)
    print(f"✅ Tileset combinado guardado en: {output_png}")
    print(f"✅ Archivo .tsx generado: {output_png.replace('.png', '.tsx')}")
