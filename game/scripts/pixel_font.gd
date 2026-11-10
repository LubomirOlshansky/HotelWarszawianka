extends RefCounted
## A tiny 5×7 pixel font with the Polish letters, for signs in the world: the
## KEBAB board on the stands, the REMONT sign at the roadworks, the joke billboards.
## Capitals, digits and a few marks (· → ← : , . ! ? - / ' „ ” ( ) + %). A glyph cell
## is 10 rows: two for accents, seven for the letter, one for an ogonek. Text can be
## drawn into an Image (billboard posters) or added to a mesh as one quad per lit
## pixel (box-built models, actor.gdshader).

const ROWS := 10
const BODY := 2          # first row of the letter itself
const LINE := 11         # rows from one line of text to the next
const SPACE := 3         # width of a space
const GAP := 1           # between letters

const GLYPHS := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"Ł": [".#...", ".#...", ".#.#.", ".##..", "##...", ".#...", ".####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
	"·": ["..", "..", "..", "##", "##", "..", ".."],
	"→": [".....", "..#..", "...#.", "#####", "...#.", "..#..", "....."],
	"←": [".....", "..#..", ".#...", "#####", ".#...", "..#..", "....."],
	":": ["..", "##", "##", "..", "##", "##", ".."],
	".": ["..", "..", "..", "..", "..", "##", "##"],
	",": ["..", "..", "..", "..", "..", ".#", "#."],
	"!": ["#", "#", "#", "#", "#", ".", "#"],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	"-": ["...", "...", "...", "###", "...", "...", "..."],
	"/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
	"'": ["#", "#", ".", ".", ".", ".", "."],
	"„": ["...", "...", "...", "...", "...", "#.#", "#.#"],
	"”": ["#.#", "#.#", "...", "...", "...", "...", "..."],
	"\"": ["#.#", "#.#", "...", "...", "...", "...", "..."],
	"(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
	")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
}
## Letters built from a base and a mark.
const MARKED := {"Ą": ["A", "ogonek"], "Ć": ["C", "acute"], "Ę": ["E", "ogonek"], "Ń": ["N", "acute"],
		"Ó": ["O", "acute"], "Ś": ["S", "acute"], "Ź": ["Z", "acute"], "Ż": ["Z", "dot"]}


## Lit pixels of one character as Vector2i (x, row), row 0 at the top of the cell.
static func pixels(ch: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var base := ch
	var mark := ""
	if MARKED.has(ch):
		base = MARKED[ch][0]
		mark = MARKED[ch][1]
	if not GLYPHS.has(base):
		return out
	var rows: Array = GLYPHS[base]
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			if line[x] == "#":
				out.append(Vector2i(x, BODY + y))
	match mark:
		"acute":
			out.append_array([Vector2i(3, 0), Vector2i(2, 1)])
		"dot":
			out.append(Vector2i(2, 0))
		"ogonek":
			out.append(Vector2i(3, BODY + 7))
	return out


static func char_width(ch: String) -> int:
	if ch == " ":
		return SPACE
	var base: String = MARKED[ch][0] if MARKED.has(ch) else ch
	if not GLYPHS.has(base):
		return 0
	return (GLYPHS[base][0] as String).length()


## Width of a line in pixels.
static func width(text: String) -> int:
	var w := 0
	var first := true
	for ch in text:
		var cw := char_width(ch)
		if cw == 0:
			continue
		if not first:
			w += GAP
		w += cw
		first = false
	return w


## Splits text into lines no wider than max_px (at spaces; a word longer than a
## line keeps its own line).
static func wrap_lines(text: String, max_px: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in text.split(" ", false):
		var trial := word if line == "" else line + " " + word
		if line != "" and width(trial) > max_px:
			out.append(line)
			line = word
		else:
			line = trial
	if line != "":
		out.append(line)
	return out


## Calls f(x, row) for every lit pixel of a line of text that starts at x0.
static func each_pixel(text: String, x0: int, f: Callable) -> void:
	var x := x0
	var first := true
	for ch in text:
		var cw := char_width(ch)
		if cw == 0:
			continue
		if not first:
			x += GAP
		first = false
		for p in pixels(ch):
			f.call(x + p.x, p.y)
		x += cw


## Draws one line of text into an image; (x, y) is the top left of the cell.
static func draw(img: Image, text: String, x: int, y: int, colour: Color) -> void:
	each_pixel(text, x, func(px: int, row: int) -> void:
		if px >= 0 and px < img.get_width() and y + row >= 0 and y + row < img.get_height():
			img.set_pixel(px, y + row, colour))


## Adds a line of text to a box-built mesh: one quad per lit pixel, `px` metres
## square, on the plane through `origin` (the top left of the cell) spanned by
## `right` and `down` (unit vectors); the quads face right × down... towards the
## viewer reading the text. `part` is the actor.gdshader part code (models.gd).
static func add_quads(st: SurfaceTool, text: String, origin: Vector3, right: Vector3, down: Vector3,
		px: float, colour: Color, part: float) -> void:
	var n := down.cross(right).normalized()
	each_pixel(text, 0, func(x: int, row: int) -> void:
		var a := origin + right * (x * px) + down * (row * px)
		var q := [a, a + right * px, a + right * px + down * px, a + down * px]
		# Godot's front faces are clockwise: (b - a) x (c - a) points away from the viewer.
		if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(n) > 0.0:
			q = [q[0], q[3], q[2], q[1]]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(colour)
			st.set_normal(n)
			st.set_uv(Vector2(part, 0.0))
			st.add_vertex(q[k] + n * 0.01))
