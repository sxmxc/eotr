extends Node

# Implement deliver(batch) returning {ok, retryable, error}; only one delivery at a time.
func deliver(_batch: Array) -> Dictionary:
	return {"ok": true}

func purge() -> void:
	pass
