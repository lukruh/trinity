extends HBoxContainer

onready var item_list = get_node('ListPage/MarginContainer/VBoxContainer/ScrollContainer/ItemList')
onready var weight_box = get_node('ListPage/MarginContainer/VBoxContainer/WeightBox')
onready var weight_bar = get_node('ListPage/MarginContainer/VBoxContainer/WeightBar')
onready var item_details = get_node('ItemInspect/Details')
onready var player = Global.player


var list_item_res = preload("res://assets/ui/inventory/ListItem.tscn")
var item_details_res = preload("res://assets/ui/inventory/ItemDetails.tscn")
var weight = 0
var max_weight = 20
var items = {}  # dict: {id: amount, id2: amount2, ..}
var icons = {}  # dict: {id: iconpath, id2: iconpath2}
var item_db


func find_item(item_id):
	for item in item_list.get_children():
		if item.get_node('Layout/Slot/Id').get_text() == String(item_id):
			#print('item found')
			return item
	return false


func has_items(dict):
	print(dict)
	# returns true or false for dict with item ids and amounts
	for iid in dict:
		var item_in_inv = false
		for item in item_list.get_children():
			var cur_id = item.get_node('Layout/Slot/Id').get_text()
			print('id compare: ', cur_id, ' ', iid)
			if String(cur_id) == String(iid):
				item_in_inv = true
				var cur_am = int(item.get_node('Layout/Slot/Amount').get_text())
				print('am compare: ', cur_am, ' ', dict[iid])
				if cur_am < int(dict[iid]):
					print('item amount to low: ', iid, ' ', cur_am)
					return false
		if !item_in_inv:
			print('item not in inv: ', iid)
			return false
	return true


func get_items_with_key(key):
	var matches = {}
	for id in items:
		if key in item_db[id]:
			matches[id] = matches.get(id, 0) +1
	return matches



func remove_items_old(dict):
	for iid in dict:
		for item in item_list.get_children():
			if String(iid) == item.get_node('Layout/Slot/Id').get_text():
				var cur_am = int(item.get_node('Layout/Slot/Amount').get_text())
				var new_am = cur_am - int(dict[iid])
				if new_am < 0:
					print('Bug: item removed that not exists')
					new_am = 0
				if new_am == 0:
					item.queue_free()
				else:
					item.get_node('Layout/Slot/Amount').set_text(String(new_am))


func remove_items(dict):
	for id in dict:
		var c = dict[id]
		items[id] -= c
		if items[id] == 0:
			items.erase(id)
	update_list()


func add_item(item_id, count=1):
	#var item = object.get_node('Item')
	items[item_id] = items.get(item_id,0) + count
	print('item added to inventory: ', item_id, '->', items[item_id])
	if not item_id in icons:
		print('loading icon')
		icons[item_id] = load("res://assets/items/" + item_db[item_id]["type"] + "/" + item_db[item_id]["fname"] + "/icon.png")
	update_list()
	
	# pass details to button callback
	#item_list.add_child(list_item)

func add_items(items):
	for id in items:
		self.add_item(id, items[id])
		

func update_details(id):
	print('update details')
	var data = item_db[id]
	var view = get_node("ItemInspect/Details/ItemDetails")
	view.set_visible(true)
	# add item details
	var this_details = get_node('ItemInspect/Details/ItemDetails')
	this_details.get_node('IconLarge').set('texture', icons[id])
	this_details.get_node('IconLarge').set('rect_size', Vector2(100,100))
	this_details.get_node('ItemName').set_text(String(data['name']))
	this_details.get_node('ItemDesc').set_text(String(data.get('text', "")))
	var equip_button = this_details.get_node('ItemButtons/Equip')
	if data['type'] == 'weapon':
		equip_button.set_visible(true)
		equip_button.disconnect("pressed", self, "_on_equip_pressed")
		equip_button.connect("pressed", self, "_on_equip_pressed", [id, data])
	else:
		equip_button.set_visible(false)
	
	
func update_list():
	print('updating list')
	self.weight = 0
	# clean up old nodes
	for c in item_list.get_children():
		print('removing item..')
		c.queue_free()
	# create new nodes
	for id in items:
		print('creating item')
		var data = item_db[id]
		var li = list_item_res.instance()
		
		# set icon, name and desc
		if not id in icons:
			icons[id] = load('res://assets/items/' + data.get('type', 'stuff') + data['fname'] + 'icon.png')
		li.get_node('Layout/Slot/Icon').set('texture', icons[id])
		li.get_node('Layout/Slot/Id').set_text(String(id))
		li.get_node('Layout/Slot/Amount').set_text(String(items[id]))
		li.get_node('Layout/ListInfo/ItemName').set_text(data['name'])
		var tags = li.get_node('Layout/ListInfo/InfoTags')
		tags.get_node('Price').set_text(String(data.get('price', 0)))
		tags.get_node('Weight').set_text(String(data.get('weight', 0)))
		self.weight += float(data.get('weight', 0))
		li.connect("pressed", get_node('.'), "update_details", [id])
		item_list.add_child(li)
		print(item_list.get_children())
	# update weight bar
	weight_box.set_visible(true)
	weight_box.get_node('WeightLabel').set_text(String(weight) + '/' + String(max_weight))
	weight_bar.set_visible(true)
	weight_bar.set_value(self.weight/self.max_weight*100)



func _ready():
	item_db = get_node("/root/Global").item_db
	self.add_item("6")


func _on_equip_pressed(id, data):
	print('pressed: ', data['fname'], id)
	self.remove_items({id: 1})
	var it_res = load('res://assets/items/weapon/' + data['fname'] + '/' + data['fname'] + '.tscn')
	var it = it_res.instance()
	if player.gear["mainhand"].get('item', false):
		add_item(player.gear['mainhand']['item'].item_id)
	player.equip_item(it)
	get_node('ItemInspect/Details/ItemDetails').set_visible(false)
	#print(it.get_node('Body'))
	#it.create_body()
