extends Node2D

const NUM_PEOPLE := 20
var people: Array[Person]
var huddle_counter = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(NUM_PEOPLE):
		var person := Person.neww()
		people.append(person)
		add_child(person)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var groups := Huddle.find_groups(people)
	groups = Huddle.filter_ungroupable(groups)
	print(Huddle.huddles_to_str(groups))
	for group in groups:
		if len(group) == 1 or len(group) == 0: continue
		var typed_group: Array[Person]
		typed_group.assign(group)
		var huddle := Huddle.find_biggest_huddle(typed_group)
		if huddle == null:
			add_child(Huddle.neww(typed_group, huddle_counter))
			huddle_counter += 1
		else:
			huddle.expand_huddle(typed_group)
