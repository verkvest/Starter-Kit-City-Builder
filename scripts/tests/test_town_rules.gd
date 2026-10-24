extends SceneTree

var failures := 0


func _init() -> void:
	_test_adjacency_and_income()
	_test_parks_and_workshop()
	_test_milestones_and_money()
	if failures > 0:
		print("FAILED ", failures)
		quit(1)
	else:
		print("town rules ok")
		quit(0)


func _test_adjacency_and_income() -> void:
	var road := _structure("Road", "road", 20)
	var cottage := _structure("Cottage", "home", 80, 4, 0, true)
	var structures: Array = [road, cottage]
	var alone := TownRules.evaluate([{"pos": Vector2i(1, 0), "id": 1}], structures)
	_expect(int(alone["residents"]) == 0, "cottage without a road has no residents")
	_expect(int(alone["disconnected"]) == 1, "cottage without a road is disconnected")
	_expect(int(alone["income"]) == 0, "empty homes earn nothing")

	var served := TownRules.evaluate([
		{"pos": Vector2i(0, 0), "id": 0},
		{"pos": Vector2i(1, 0), "id": 1},
	], structures)
	_expect(int(served["residents"]) == 4, "road-side cottage has 4 residents")
	_expect(int(served["income"]) == 2, "four residents earn 2 coins a tick")
	_expect(int(served["disconnected"]) == 0, "served cottage is connected")

	var diagonal := TownRules.evaluate([
		{"pos": Vector2i(0, 0), "id": 0},
		{"pos": Vector2i(1, 1), "id": 1},
	], structures)
	_expect(int(diagonal["residents"]) == 0, "a corner does not count as beside a road")

	_expect(TownRules.replacement_cost(-1, 1, structures) == 80, "placing a cottage costs its price")
	_expect(TownRules.replacement_cost(1, 0, structures) == -60, "replacing a cottage with a road refunds the difference")


func _test_parks_and_workshop() -> void:
	var road := _structure("Road", "road", 20)
	var cottage := _structure("Cottage", "home", 80, 4, 0, true)
	var trees := _structure("Trees", "park", 20, 0, 0, false, 1)
	var fountain := _structure("Fountain", "civic", 90, 0, 2, false)
	var workshop := _structure("Workshop", "civic", 200, 0, 3, true)
	var structures: Array = [road, cottage, trees, fountain, workshop]

	var lonely_fountain := TownRules.evaluate([{"pos": Vector2i(3, 3), "id": 3}], structures)
	_expect(int(lonely_fountain["income"]) == 2, "a fountain earns its bonus alone")

	var with_trees := TownRules.evaluate([
		{"pos": Vector2i(0, 0), "id": 0},
		{"pos": Vector2i(1, 0), "id": 1},
		{"pos": Vector2i(1, 1), "id": 2},
		{"pos": Vector2i(1, -1), "id": 2},
	], structures)
	_expect(int(with_trees["income"]) == 3, "two trees beside a home add one coin")

	var far_tree := TownRules.evaluate([
		{"pos": Vector2i(0, 0), "id": 0},
		{"pos": Vector2i(1, 0), "id": 1},
		{"pos": Vector2i(4, 4), "id": 2},
	], structures)
	_expect(int(far_tree["income"]) == 2, "a distant tree does not pay")

	var idle_shop := TownRules.evaluate([{"pos": Vector2i(2, 2), "id": 4}], structures)
	_expect(int(idle_shop["unserved"]) == 1, "a workshop off the road is unserved")
	_expect(int(idle_shop["income"]) == 0, "an unserved workshop earns nothing")

	var busy_shop := TownRules.evaluate([
		{"pos": Vector2i(0, 0), "id": 0},
		{"pos": Vector2i(1, 0), "id": 4},
	], structures)
	_expect(int(busy_shop["income"]) == 3, "a workshop on a road earns its bonus")
	_expect(int(busy_shop["residents"]) == 0, "a workshop houses nobody")


func _test_milestones_and_money() -> void:
	_expect(TownRules.money(750) == "$750", "small amounts stay plain")
	_expect(TownRules.money(1000) == "$1,000", "thousands get a comma")
	_expect(TownRules.money(12500) == "$12,500", "larger amounts group by three")
	_expect(TownRules.money(-20) == "-$20", "refunds keep the sign")

	var claimed := PackedInt32Array()
	var first := TownRules.collect_milestones(10, claimed, true)
	_expect(int(first["reward"]) == 150, "hamlet pays 150")
	_expect((first["claimed"] as PackedInt32Array).has(10), "hamlet is claimed")
	var again := TownRules.collect_milestones(25, first["claimed"], true)
	_expect(int(again["reward"]) == 300, "village pays once, without repeating hamlet")
	var silent := TownRules.collect_milestones(100, PackedInt32Array(), false)
	_expect(int(silent["reward"]) == 0, "loading does not pay historical milestones")
	_expect((silent["claimed"] as PackedInt32Array).has(100), "historical milestones are marked claimed")
	_expect(bool(silent["just_chartered"]) == false, "a loaded town does not re-charter")
	var charter := TownRules.collect_milestones(100, PackedInt32Array(), true)
	_expect(bool(charter["just_chartered"]), "crossing 100 charters the town")

	var cottage := _structure("Cottage", "home", 80, 4, 0, true, 0, 0)
	var house := _structure("House", "home", 100, 6, 0, true, 0, 8)
	var names := TownRules.unlocks_between([cottage, house], 0, 8)
	_expect(names.size() == 1 and names[0] == "House", "only the newly reached building is announced")
	_expect(TownRules.is_unlocked(cottage, 0), "starter buildings are open")
	_expect(not TownRules.is_unlocked(house, 0), "later buildings wait for residents")


func _structure(structure_name: String, category: String, price: int, residents: int = 0, bonus: int = 0, needs_road: bool = false, park_points: int = 0, unlock_at: int = 0) -> Structure:
	var structure := Structure.new()
	structure.display_name = structure_name
	structure.category = category
	structure.price = price
	structure.residents = residents
	structure.coin_bonus = bonus
	structure.needs_road = needs_road
	structure.park_points = park_points
	structure.unlock_at = unlock_at
	return structure


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
	print("FAIL: ", message)
