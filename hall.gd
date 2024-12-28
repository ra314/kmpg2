extends Node2D

const NUM_PEOPLE := 20
var people: Array[Person]
var huddles: Array[Huddle]
var huddle_counter = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(NUM_PEOPLE):
		var person := Person.neww()
		people.append(person)
		add_child(person)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Find Huddles
	var groups := Huddle.find_groups(people)
	groups = Huddle.filter_ungroupable(groups)
	print(Huddle.huddles_to_str(groups))
	huddles.clear()
	for group in groups:
		if len(group) == 1 or len(group) == 0: continue
		var typed_group: Array[Person]
		typed_group.assign(group)
		var huddle := Huddle.find_biggest_huddle(typed_group)
		if huddle == null:
			huddle = Huddle.neww(typed_group, huddle_counter)
			add_child(huddle)
			huddle_counter += 1
		else:
			huddle.expand_huddle(typed_group)
		huddles.append(huddle)
	# Apply gravity
	var wandering_people = people.filter(func(x: Person): return x.can_huddle and x.target_location==null)
	for person: Person in wandering_people:
		for huddle: Huddle in huddles:
			person.apply_gravity_towards_huddle(huddle)
