extends Resource
class_name RunBootstrap

enum Type {NEW_RUN, CONTINUED_RUN}

@export var type: Type
@export var selected_player_class: PlayerStats
