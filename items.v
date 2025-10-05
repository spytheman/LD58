module main

const all_item_paths = [
	'images/items/glass/cup1.png',
	'images/items/glass/cup2.png',
	'images/items/glass/cup3.png',
	'images/items/metal/coin1.png',
	'images/items/metal/coin2.png',
	'images/items/metal/coin3.png',
	'images/items/metal/coin4.png',
	'images/items/organic/apple_bite.png',
	'images/items/organic/leaf1.png',
	'images/items/organic/remains1.png',
	'images/items/paper/paperball.png',
	'images/items/paper/sheets1.png',
	'images/items/paper/toiletroll.png',
	'images/items/plastic/bottle.png',
	'images/items/plastic/bottle2.png',
	'images/items/plastic/bottle3.png',
	'images/items/plastic/crap1.png',
	'images/items/plastic/crap2.png',
]

const paths_by_kind = group_paths_by_kind()

fn group_paths_by_kind() map[Kind][]string {
	mut res := map[Kind][]string{}
	for kind in [Kind.glass, .metal, .organic, .paper, .plastic] {
		skind := kind.str()
		paths := all_item_paths.filter(it.contains(skind))
		res[kind] = paths
	}
	return res
}
