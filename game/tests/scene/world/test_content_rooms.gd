extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-salas.md (MUN-036): as salas do jogo são consistentes.

const ROOMS_DIR := "res://content/rooms/"


func _room_ids() -> Array[String]:
	var ids: Array[String] = []
	for file_name in DirAccess.get_files_at(ROOMS_DIR):
		if file_name.get_extension() == "tscn":
			ids.append(file_name.get_basename())
	return ids


func _load(room_id: String) -> Room:
	return auto_free(load(ROOMS_DIR + room_id + ".tscn").instantiate())


func test_existem_salas() -> void:
	assert_array(_room_ids()).is_not_empty()


func test_MUN_036_salas_sao_consistentes() -> void:
	var ids := _room_ids()
	for room_id in ids:
		var room := _load(room_id)
		var layout := RoomLayout.parse(room.layout)
		assert_str(room.room_id).override_failure_message("%s: room_id diferente do arquivo" % room_id).is_equal(room_id)
		assert_array(layout.errors).override_failure_message("%s: %s" % [room_id, layout.errors]).is_empty()
		assert_dict(layout.entries).override_failure_message("%s: sem entradas" % room_id).is_not_empty()
		for letter: String in layout.exits:
			assert_bool(room.exits.has(letter)).override_failure_message("%s: saída '%s' sem destino" % [room_id, letter]).is_true()
		for letter: String in room.exits:
			var target: PackedStringArray = str(room.exits[letter]).split(":")
			assert_int(target.size()).override_failure_message("%s: destino mal escrito '%s'" % [room_id, room.exits[letter]]).is_equal(2)
			assert_bool(target[0] in ids).override_failure_message("%s: sala '%s' não existe" % [room_id, target[0]]).is_true()
			if target[0] in ids:
				var target_layout := RoomLayout.parse(_load(target[0]).layout)
				assert_bool(target_layout.entries.has(target[1])) \
						.override_failure_message("%s: entrada '%s' não existe em %s" % [room_id, target[1], target[0]]) \
						.is_true()
