extends RefCounted
## The one way a kept file (the save, the settings) reaches the disk (tech-debt TD-8, 2026-11-12,
## F: "what technical work makes the game more reliable").
##
## ConfigFile.save writes straight over the old file. An app closed in the middle of that (a
## crash, a flat battery, the system closing a background app) leaves half a file, and half a
## ConfigFile still loads without an error: the parser returns what is there. `write` puts the
## text in `<path>.tmp` first, reads it back byte for byte, and only then renames it over `path`, so the old
## file is replaced in one step or not at all. `copy` does the same for a copy of a file.
##
## Only wallet.gd and settings.gd call this; a new kept value goes through wallet.gd
## (docs/architecture/extending.md).


## Writes `cfg` to `path`. OK, or the error; on an error `path` is as it was before the call.
static func write(cfg: ConfigFile, path: String) -> Error:
	var tmp := path + ".tmp"
	var err := cfg.save(tmp)
	# Read back: the bytes on the disk must be the text that was meant (a full disk writes less).
	if err == OK and FileAccess.get_file_as_bytes(tmp) != cfg.encode_to_text().to_utf8_buffer():
		err = ERR_FILE_CORRUPT
	if err == OK:
		err = _swap(tmp, path)
	if err != OK:
		_drop(tmp)
	return err


## Copies the file `from` to `to` (through `<to>.tmp`, so `to` is never half a copy). OK, or the
## error; on an error `to` is as it was.
static func copy(from: String, to: String) -> Error:
	var tmp := to + ".tmp"
	var err := DirAccess.copy_absolute(ProjectSettings.globalize_path(from), ProjectSettings.globalize_path(tmp))
	if err == OK and FileAccess.get_file_as_bytes(tmp) != FileAccess.get_file_as_bytes(from):
		err = ERR_FILE_CORRUPT
	if err == OK:
		err = _swap(tmp, to)
	if err != OK:
		_drop(tmp)
	return err


## `tmp` takes `path`'s place: one rename, which replaces the old file in a single step.
static func _swap(tmp: String, path: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


static func _drop(tmp: String) -> void:
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
