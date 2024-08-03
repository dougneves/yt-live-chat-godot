extends Node2D

var _players = {}

func _on_yt_live_chat_yt_live_message_read(text: String, authorId: String, authorTitle: String, timestamp: String):
	$messagesText.text = authorTitle + ": " + text + "\r\n" + $messagesText.text

func _process(delta):
	$stopButton.disabled = !$YTLiveChat.is_running()
	$startButton.disabled = $YTLiveChat.is_running()
	$liveIdEdit.editable = !$YTLiveChat.is_running()

func _on_start_button_pressed():
	$YTLiveChat.start_get_message_loop_by_file("ytconfig.json", $liveIdEdit.text)

func _on_stop_button_pressed():
	$YTLiveChat.stop()
