extends RefCounted
class_name TownRules

const CHARTER := 100
const STARTING_CASH := 750
const TICK_SECONDS := 5.0

const MILESTONES: Array[Dictionary] = [
	{"at": 10, "name": "Hamlet", "reward": 150},
	{"at": 25, "name": "Village", "reward": 300},
	{"at": 50, "name": "Town", "reward": 600},
	{"at": 100, "name": "Charter", "reward": 1000},
]

static func is_unlocked(structure: Structure, peak_residents: int) -> bool:
	return peak_residents >= structure.unlock_at


static func money(amount: int) -> String:
	var negative := amount < 0
	var digits := str(absi(amount))
	var parts: PackedStringArray = []
	while digits.length() > 3:
		parts.insert(0, digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	parts.insert(0, digits)
	var body := ",".join(parts)
	if negative:
		return "-$" + body
	return "$" + body


static func replacement_cost(previous_id: int, next_id: int, structures: Array) -> int:
	var refund := 0
	if previous_id >= 0 and previous_id < structures.size():
		refund = (structures[previous_id] as Structure).price
	return (structures[next_id] as Structure).price - refund


static func unlocks_between(structures: Array, before_peak: int, after_peak: int) -> PackedStringArray:
	var names := PackedStringArray()
	for entry in structures:
		var structure := entry as Structure
		if structure.unlock_at > before_peak and structure.unlock_at <= after_peak:
			names.append(structure.display_name)
	return names


static func collect_milestones(residents: int, claimed: PackedInt32Array, pay: bool) -> Dictionary:
	var next := claimed.duplicate()
	var reward := 0
	var events: Array[Dictionary] = []
	var just_chartered := false
	for milestone in MILESTONES:
		var at := int(milestone["at"])
		if residents < at or next.has(at):
			continue
		next.append(at)
		if pay:
			reward += int(milestone["reward"])
			events.append(milestone)
			if at >= CHARTER:
				just_chartered = true
	return {
		"claimed": next,
		"reward": reward,
		"events": events,
		"just_chartered": just_chartered,
	}


static func evaluate(cells: Array, structures: Array) -> Dictionary:
	var by_pos := {}
	for cell in cells:
		by_pos[cell["pos"]] = int(cell["id"])

	var residents := 0
	var disconnected := 0
	var unserved := 0
	var bonus := 0
	var served_homes: Array[Vector2i] = []

	for pos in by_pos.keys():
		var id: int = by_pos[pos]
		if id < 0 or id >= structures.size():
			continue
		var structure := structures[id] as Structure
		if structure.category == "road" or structure.category == "park":
			continue
		var served := (not structure.needs_road) or _touches_category(pos, by_pos, structures, "road")
		if not served:
			if structure.residents > 0:
				disconnected += 1
			elif structure.coin_bonus > 0:
				unserved += 1
			continue
		residents += structure.residents
		bonus += structure.coin_bonus
		if structure.residents > 0:
			served_homes.append(pos)

	var park_points := 0
	for pos in by_pos.keys():
		var id: int = by_pos[pos]
		if id < 0 or id >= structures.size():
			continue
		var structure := structures[id] as Structure
		if structure.category != "park" or structure.park_points <= 0:
			continue
		if _touches_any(pos, served_homes):
			park_points += structure.park_points

	bonus += int(park_points / 2.0)
	var income := bonus
	if residents > 0:
		income += maxi(1, int(residents / 2.0))

	return {
		"residents": residents,
		"disconnected": disconnected,
		"unserved": unserved,
		"income": income,
		"parks": park_points,
	}


static func _touches_category(pos: Vector2i, by_pos: Dictionary, structures: Array, category: String) -> bool:
	for step in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var neighbor: Vector2i = pos + step
		if not by_pos.has(neighbor):
			continue
		var id: int = by_pos[neighbor]
		if id < 0 or id >= structures.size():
			continue
		if (structures[id] as Structure).category == category:
			return true
	return false


static func _touches_any(pos: Vector2i, cells: Array[Vector2i]) -> bool:
	for step in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		if cells.has(pos + step):
			return true
	return false
