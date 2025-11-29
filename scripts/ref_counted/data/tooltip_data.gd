extends RefCounted
class_name TooltipData

var description: String
var keyword_tooltips: Array[Dictionary] = []

func _init(descr: String = "", keywords: Array[Dictionary] = []):
	self.description = descr
	self.keyword_tooltips = keywords
