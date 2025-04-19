extends Node

func generate_random_ident() -> void:
	var ident : String = Talo.players.generate_identifier()
	Talo.players.identify("random_username", ident)
	
func generate_host_unique_ident() -> void:
	if OS.get_name() == "Web":
		generate_random_ident()
		return
	var ident: String = OS.get_unique_id()
	Talo.players.identify("host", ident)
	
	
