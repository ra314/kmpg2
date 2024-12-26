extends Node
class_name Huddle

const HUDDLE := preload("res://huddle.tscn")
const MIN_HUDDLE_DIST := 50
const RADIAL_SEPARATION := 100
var person_to_location = {}
var center: Vector2
var id := 0
const HALF_LIFE := 10
var RNG := RandomNumberGenerator.new()

func expand_huddle(people: Array[Person]) -> void:
	for person: Person in people:
		person.huddle = self
	var num_people := len(people)
	# Create a list of locations for the huddle.
	var circumference := RADIAL_SEPARATION * num_people
	var angles := range(0, 360, 360.0/num_people)
	var radius := circumference/(2*PI)
	var locations: Array[Vector2]
	locations.assign(angles.map(func(x): return calc_location(center, x, radius)))
	# Find the closest location for each person.
	person_to_location = assign_people_to_locations(people, locations)
	for person: Person in person_to_location:
		var location = person_to_location[person]
		person.move_to_location(location)

func initialize(people: Array[Person], _id: int) -> Huddle:
	id = _id
	center = people.map(func(x): return x.position).reduce(func(acc, new): return acc+new)/len(people)
	expand_huddle(people)
	return self

static func calc_location(center: Vector2, angle: float, radius: float) -> Vector2:
	var rad := deg_to_rad(angle)
	var y := sin(rad)*radius
	var x := cos(rad)*radius
	return Vector2(x, y) + center

static func assign_people_to_locations(people: Array[Person], locations: Array[Vector2]) -> Dictionary:
	# Compute pairwise distances
	var pairwise := {}
	for person: Person in people:
		var distances = {}
		for location: Vector2 in locations:
			distances[location] = location.distance_to(person.position)
		pairwise[person] = distances
	# Find person with the smallest pairwise distance
	var retval := {}
	while len(pairwise) > 0:
		var pair = find_closest_pair(pairwise)
		var person = pair[0]
		var location = pair[1]
		retval[person] = location
		pairwise.erase(person)
		for p in pairwise:
			pairwise[p].erase(location)
	return retval

# Returns person, location tuple.
static func find_closest_pair(pairwise: Dictionary) -> Array:
	var min_dist = INF
	var closest_person = null
	var closest_location = null
	for person in pairwise:
		var locations = pairwise[person]
		for location in locations:
			var dist = locations[location]
			if dist < min_dist:
				closest_person = person
				closest_location = location
	return [closest_person, closest_location]

func release():
	queue_free()

func disband() -> void:
	for person: Person in person_to_location:
		person.disband()
	release()

static func neww(_people: Array[Person], _id: int) -> Huddle:
	return HUDDLE.instantiate().initialize(_people, _id)

static func filter_ungroupable(groups: Array) -> Array:
	for group: Array in groups:
		for person: Person in group:
			if not person.can_huddle:
				group.erase(person)
	return groups

# Returns an array of groups of people.
# This is a poor man's union merge.
static func find_groups(people: Array[Person]) -> Array:
	# -1 represents someone not being in a group
	var person_to_group = {}
	var huddle_ids = {}
	for person: Person in people:
		if person.huddle == null:
			person_to_group[person] = -1
		else:
			person_to_group[person] = person.huddle.id
	var ungrouped_people = people.filter(func(x: Person): return x.huddle==null)
	for p1: Person in ungrouped_people:
		for p2: Person in people:
			if p1.position.distance_to(p2.position) < MIN_HUDDLE_DIST:
				merge(p1, p2, person_to_group)
	var grouped_people = {}
	for person in person_to_group:
		var group = person_to_group[person]
		if group not in grouped_people:
			grouped_people[group] = []
		grouped_people[group].append(person)
	return grouped_people.values()

static func merge(p1: Person, p2: Person, person_to_group: Dictionary) -> void:
	var g1 = person_to_group[p1]
	var g2 = person_to_group[p2]
	var ng = person_to_group.values().max()+1
	if g1 == -1 and g2 == -1:
		person_to_group[p1] = ng
		person_to_group[p2] = ng
		return
	if g1 == -1 and g2 != -1:
		person_to_group[p1] = g2
		return
	if g1 != -1 and g2 == -1:
		person_to_group[p2] = g1
		return
	if g1 != -1 and g2 != -1:
		for person: Person in person_to_group:
			if person_to_group[person] == g2:
				person_to_group[person] = g1
		return
	assert(false)
	return

static func huddles_to_str(huddles: Array) -> String:
	var retval = []
	for huddle in huddles:
		retval.append(len(huddle))
	return str(retval)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().create_timer(HALF_LIFE).timeout.connect(invoke_halflife)

func invoke_halflife() -> void:
	if RNG.randf() > 0.5:
		disband()
		return
	get_tree().create_timer(HALF_LIFE).timeout.connect(invoke_halflife)

static func find_biggest_huddle(people: Array[Person]) -> Huddle:
	var huddle_set = {}
	for person: Person in people:
		huddle_set[person.huddle] = true
	var huddles = huddle_set.keys()
	if len(huddles) == 1:
		return huddles[0]
	huddles = huddles.filter(func(x): return x != null)
	huddles.sort_custom(sort_ascending)
	return huddles[len(huddles)-1]

static func sort_ascending(h1: Huddle, h2: Huddle) -> bool:
	if len(h1.person_to_location) == len(h2.person_to_location):
		return h1.id < h2.id
	return len(h1.person_to_location) < len(h2.person_to_location)
