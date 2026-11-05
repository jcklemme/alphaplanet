class_name GameEventLog
extends RefCounted
signal changed
const LIMIT := 300
var entries: Array[Dictionary] = []
func append(text: String, category := "System") -> void:
	entries.append({"text": text, "category": category})
	if entries.size() > LIMIT:
		entries.pop_front()
	changed.emit()
