extends Node2D

var _players = {}

func _on_yt_live_chat_yt_live_message_read(text: String, authorId: String, timestamp: String):
	print(_players)
	var playerName = _get_player_name(authorId)
	
	$messagesText.text = playerName + ": " + text + "\r\n" + $messagesText.text
	
	text = text.to_upper()
	if text.begins_with("!NAME "):
		return _set_player_name(text, authorId)
		
func _get_player(authorId: String):
	var player = _players.get(authorId)
	if player:
		return player
	else:
		_players[authorId] = {}
		return _players[authorId]

func _get_player_name(authorId: String):
	var player = _get_player(authorId)
	var playerName = player.get("name")
	if playerName:
		return playerName
	return authorId

func _set_player_name(text: String, authorId: String):
	var name = text.erase(0,6)
	var allowed_chars = "ABCÇDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-ÁÉÍÓÚÃÕÂÔ"
	var filtered_string = ""
	
	for char in name:
		if char in allowed_chars:
			filtered_string += char
	
	name = filtered_string.substr(0,16)
	
	if _players.get(authorId):
		_players[authorId]["name"] = name
	else:
		_players[authorId] = {"name" = name}

func _process(delta):
	$stopButton.disabled = !$YTLiveChat.is_running()
	$startButton.disabled = $YTLiveChat.is_running()
	$liveIdEdit.editable = !$YTLiveChat.is_running()

func _on_start_button_pressed():
	$YTLiveChat.start_get_message_loop_by_file("ytconfig.json", $liveIdEdit.text)

func _on_stop_button_pressed():
	$YTLiveChat.stop()
