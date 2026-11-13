extends SceneTree
## Pastes equal-size PNGs into one grid sheet (tools/turntable.sh): a 4 px dark gap between tiles.
##   godot --headless --path game --script res://tools/shot_sheet.gd -- --out=FILE.png --cols=8 A.png B.png ...
## A file that is missing or unreadable leaves a dark tile and is named in the output; exit 1 only
## when none loads (or the arguments are wrong). Tiles take the size of the first one that loads.
## compose() is static so tools/check_turntable.gd calls the same code.

const GAP := 4
const DARK := Color(0.08, 0.08, 0.1)


## The sheet of `files` in `cols` columns, or null when none loads. `missing` gets the names that failed.
static func compose(files: PackedStringArray, cols: int, missing: PackedStringArray) -> Image:
	var imgs: Array[Image] = []
	var tile := Vector2i.ZERO
	for f in files:
		var im := Image.load_from_file(f) if FileAccess.file_exists(f) else null
		if im == null or im.is_empty():
			missing.append(f)
			imgs.append(null)
			continue
		im.convert(Image.FORMAT_RGBA8)
		if tile == Vector2i.ZERO:
			tile = im.get_size()
		imgs.append(im)
	if tile == Vector2i.ZERO:
		return null
	var rows := ceili(float(files.size()) / float(cols))
	var sheet := Image.create(cols * tile.x + (cols + 1) * GAP, rows * tile.y + (rows + 1) * GAP, false, Image.FORMAT_RGBA8)
	sheet.fill(DARK)
	for i in imgs.size():
		var im := imgs[i]
		if im == null:
			continue
		if im.get_size() != tile:
			im.resize(tile.x, tile.y)
		sheet.blit_rect(im, Rect2i(Vector2i.ZERO, tile), Vector2i(GAP + (i % cols) * (tile.x + GAP), GAP + (i / cols) * (tile.y + GAP)))
	return sheet


func _initialize() -> void:
	var out := ""
	var cols := 0
	var files := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--cols="):
			cols = int(a.trim_prefix("--cols="))
		else:
			files.append(a)
	if out == "" or cols < 1 or files.is_empty():
		print("shot_sheet: usage --out=FILE.png --cols=N FILE1.png FILE2.png ...")
		quit(1)
		return
	var missing := PackedStringArray()
	var sheet := compose(files, cols, missing)
	if sheet == null:
		print("shot_sheet: none of the %d files loads" % files.size())
		quit(1)
		return
	for m in missing:
		print("shot_sheet: missing tile %s" % m)
	sheet.save_png(out)
	print("shot_sheet: %s %dx%d, %d tiles, %d missing" % [out, sheet.get_width(), sheet.get_height(), files.size(), missing.size()])
	quit(0)
