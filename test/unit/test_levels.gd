extends GutTest


func test_levels_by_age() -> void:
	var cases := {3: &"simple", 5: &"simple", 6: &"cuento", 8: &"cuento", 9: &"aventura", 12: &"aventura"}
	for age in cases:
		assert_eq(Levels.for_age(age), cases[age], "edad %d" % age)


func test_out_of_range_clamps() -> void:
	assert_eq(Levels.for_age(1), &"simple")
	assert_eq(Levels.for_age(40), &"aventura")


func test_all_levels() -> void:
	assert_eq(Levels.ALL, [&"simple", &"cuento", &"aventura"])
