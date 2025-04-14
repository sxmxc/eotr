class_name MapLegend
extends Control


@onready var legend_content: CollapsibleContainer = %LegendContent
@onready var collapse_toggle: CheckButton = %CollapseToggle


func _on_collapse_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		legend_content.open_tween()
	else:
		legend_content.close_tween()
	pass # Replace with function body.
