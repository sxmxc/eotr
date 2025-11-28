extends RefCounted
class_name CardCostSelectionRequest

var cards: Array[Card] = []
var title: String = "Select cards"
var body: String = ""
var min_select: int = 1
var max_select: int = 1
var allow_cancel: bool = true
var confirm_label: String = "Confirm"
var cancel_label: String = "Cancel"
var source


func get_clamped_min() -> int:
	return max(min_select, 0)


func get_clamped_max() -> int:
	var clamped_min := get_clamped_min()
	return max(max_select, clamped_min)
