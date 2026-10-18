extends Resource
class_name Stats

signal stats_changed
signal damage_taken

@export var max_health := 1

var health: int : set = set_health
var block: int : set = set_block
var total_health_damage := 0
var total_healing := 0

func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()

func set_block(value: int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()

func take_damage(damage: int) -> void:
	if damage <= 0:
		return
	var initial_damage = damage
	damage = clampi(damage - block, 0, damage)
	self.block = clampi(block - initial_damage, 0, block)
	total_health_damage += mini(health, damage)
	self.health -= damage
	print("[Stats] take_damage initial=%s applied=%s block_after=%s health_after=%s" % [initial_damage, damage, block, health])
	if damage > 0:
		damage_taken.emit(damage)
	
func take_direct_damage(damage: int) -> void:
	if damage <= 0:
		return
	total_health_damage += mini(health, damage)
	self.health -= damage
	if damage > 0:
		damage_taken.emit(damage)

func heal(amount: int) -> void: 
	total_healing += clampi(amount, 0, max_health - health)
	self.health += amount

func create_instance() -> Resource:
	var instance: Stats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.total_health_damage = 0
	instance.total_healing = 0
	return instance
