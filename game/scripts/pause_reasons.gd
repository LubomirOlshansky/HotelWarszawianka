extends RefCounted
## The game's pause, owned in one place (TD-20).
## Several things stop the world under them: the loading bar, the settings card, the full-screen
## map, the garage card. Each used to write `get_tree().paused` itself, so whichever closed first
## set the game going under the one still up. Found on 2026-11-13: with the garage card open a
## tap on the minimap opens the map over it, and closing the map let the city run on (and the
## car drive off) under the garage card.
## Here each holds its own reason and lets go of only that one; the tree is paused while any
## reason is held. main.gd owns the one instance (`_pause`). A system that needs the world to
## stop asks main.gd through a signal or a callable and never writes the tree's pause itself
## (docs/architecture/extending.md "A pause"; check_pause.gd reads the scripts for it).

## The reasons main.gd holds. A new reason to pause gets its name here.
const LOAD := &"load"          ## the loading bar: nothing half-built moves between the build's steps
const SETTINGS := &"settings"  ## the settings card
const MAP := &"map"            ## the full-screen map
const GARAGE := &"garage"      ## the garage card

var _tree: SceneTree
## The reasons held now, in the order they came (the log names them in it).
var _held: Array[StringName] = []


func _init(tree: SceneTree) -> void:
	_tree = tree


## `reason` wants the game stopped. Holding a reason twice is one hold: one release ends it.
func hold(reason: StringName) -> void:
	if not _held.has(reason):
		_held.append(reason)
	_apply()


## `reason` is over. The game runs again only when nothing else holds it. Letting go of a
## reason that is not held changes nothing.
func release(reason: StringName) -> void:
	_held.erase(reason)
	_apply()


## Every reason goes: a new game reloads the scene, and nothing of the old one may keep the
## next paused.
func release_all() -> void:
	_held.clear()
	_apply()


## Whether `reason` is held now.
func held(reason: StringName) -> bool:
	return _held.has(reason)


## For the log line of a card that closed: "" when the game runs again, or what still holds it.
func still() -> String:
	if _held.is_empty():
		return ""
	return ", the game stays paused (%s)" % ", ".join(PackedStringArray(_held))


func _apply() -> void:
	_tree.paused = not _held.is_empty()
