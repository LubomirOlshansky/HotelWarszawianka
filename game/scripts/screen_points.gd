extends RefCounted
## Loop 2e: the screen in points, Apple's unit for touch targets and text (44 pt is the
## smallest comfortable tap; 3 px a point on the iPhones the game targets), and the safe area
## (the Dynamic Island or notch, the rounded corners, the home indicator) in landscape.
##
## On a phone both come from the device. On a computer the window stands in for a phone: a
## window the size of a known iPhone's screen in landscape gets that iPhone's scale and safe
## area (2868x1320 is the 6.9" Pro Max, 956 x 440 pt with 62 pt each side and 21 pt at the
## bottom), any other window is taken as a phone 390 pt tall with no insets (the 6.1" class),
## so screenshots and the HUD check show what the phone would (a narrower window, 4:3 say,
## is taken as 667 pt wide instead; the iPads in the table are known too). In landscape iOS
## insets both sides the same, whichever side the island is on, so the layout holds turned
## either way.
##
##   var s := ScreenPoints.measure(get_viewport().get_visible_rect().size)
##   s["pt"]    pixels per point
##   s["safe"]  the safe area in pixels (Rect2)

const MacMode := preload("res://scripts/mac_mode.gd")

## Width x height in pixels (landscape) -> [pixels per point, left, right, top, bottom
## insets in points]. iPhones from the X on; the SE has no insets.
const PHONES := {
	Vector2i(2868, 1320): [3.0, 62.0, 62.0, 0.0, 21.0],   # 16 / 17 Pro Max
	Vector2i(2796, 1290): [3.0, 59.0, 59.0, 0.0, 21.0],   # 14 / 15 Pro Max, 15 / 16 Plus
	Vector2i(2778, 1284): [3.0, 47.0, 47.0, 0.0, 21.0],   # 12 / 13 Pro Max, 14 Plus
	Vector2i(2688, 1242): [3.0, 44.0, 44.0, 0.0, 21.0],   # XS Max, 11 Pro Max
	Vector2i(2622, 1206): [3.0, 62.0, 62.0, 0.0, 21.0],   # 16 / 17 Pro
	Vector2i(2556, 1179): [3.0, 59.0, 59.0, 0.0, 21.0],   # 14 Pro, 15, 15 Pro, 16
	Vector2i(2532, 1170): [3.0, 47.0, 47.0, 0.0, 21.0],   # 12, 13, 14, 12 / 13 Pro
	Vector2i(2436, 1125): [3.0, 44.0, 44.0, 0.0, 21.0],   # X, XS, 11 Pro
	Vector2i(2340, 1080): [3.0, 50.0, 50.0, 0.0, 21.0],   # 12 / 13 mini
	Vector2i(1792, 828): [2.0, 48.0, 48.0, 0.0, 21.0],    # XR, 11
	Vector2i(1334, 750): [2.0, 0.0, 0.0, 0.0, 0.0],       # SE (2nd, 3rd)
	# iPads (store listings, 2026-10-30): the App Store's iPad screenshots are rendered at these
	# sizes. Landscape, the status bar hidden: only the home indicator's 20 pt at the bottom.
	Vector2i(2752, 2064): [2.0, 0.0, 0.0, 0.0, 20.0],     # iPad Pro 13" (M4)
	Vector2i(2732, 2048): [2.0, 0.0, 0.0, 0.0, 20.0],     # iPad Pro 12.9", iPad Air 13"
	Vector2i(2420, 1668): [2.0, 0.0, 0.0, 0.0, 20.0],     # iPad Pro 11" (M4)
	Vector2i(2360, 1640): [2.0, 0.0, 0.0, 0.0, 20.0],     # iPad Air 11", iPad (10th)
}
## A window that is no known phone is taken as one this many points tall,
const DESKTOP_POINTS_TALL := 390.0
## and at least this many wide: the SE's width, the narrowest screen the HUD is laid out for.
## Without it a 4:3 window came out 520 pt wide and the pull-over card (about 610 pt) never
## found room, so it stayed hidden (store screenshots, 2026-10-30).
const DESKTOP_POINTS_WIDE := 667.0


## {"pt": pixels per point, "safe": Rect2 in pixels, "insets": Vector4 (left, right, top,
## bottom) in pixels, "phone": a known iPhone size (or the device)}.
static func measure(size: Vector2) -> Dictionary:
	var pt := maxf(minf(size.y / DESKTOP_POINTS_TALL, size.x / DESKTOP_POINTS_WIDE), 0.5)
	var insets := Vector4.ZERO
	var phone := false
	if OS.has_feature("mobile"):
		pt = maxf(DisplayServer.screen_get_scale(), 1.0)
		var screen := DisplayServer.screen_get_size()
		var area := DisplayServer.get_display_safe_area()
		# The safe area is in the screen's pixels; the viewport may differ (k = 1 when it doesn't).
		var k := size.x / float(maxi(screen.x, 1))
		insets = Vector4(area.position.x * k, (screen.x - area.end.x) * k, area.position.y * k, (screen.y - area.end.y) * k)
		phone = true
	else:
		var known: Variant = PHONES.get(Vector2i(roundi(size.x), roundi(size.y)))
		if known != null:
			var p: Array = known
			pt = p[0]
			insets = Vector4(p[1], p[2], p[3], p[4]) * pt
			phone = true
	if MacMode.active():
		# Mac step 1 (mac_mode.gd): a laptop is seen from twice a phone's distance; its window is
		# taken as at most MAC_POINTS_TALL points tall (982 pt on a 14" MacBook drew the HUD half
		# the size it is on the phone), never under the window's own scale.
		pt = maxf(pt, size.y / MacMode.MAC_POINTS_TALL)
	var safe := Rect2(Vector2(insets.x, insets.z), size - Vector2(insets.x + insets.y, insets.z + insets.w))
	return {"pt": pt, "safe": safe, "insets": insets, "phone": phone}
