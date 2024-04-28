extends Node

@export var begins_with = "!"
@export var logs = true

var _api_key = ""
var _live_id = ""
var _live_chat_id = ""
var _next_page_token = null
var _is_stopped = true

signal yt_live_message_read(text: String, authorId: String, timestamp: String)

func _ready():
	$Timer.timeout.connect(get_next_chat_messages)
	$HTTPRequestGetLiveChatId.request_completed.connect(on_get_live_chat_id)
	$HTTPRequestGetLiveChatMessages.request_completed.connect(on_get_next_chat_messages)

func start_get_message_loop(apiKey: String, liveId: String):
	_api_key = apiKey
	_live_id = liveId
	_is_stopped = false
	get_live_chat_id()
	
func start_get_message_loop_by_file(fileUrl: String, liveId: String):
	_is_stopped = true
	
	if not FileAccess.file_exists(fileUrl):
		return _log("File does not exists: " + fileUrl)

	var ytConfigFile = FileAccess.open(fileUrl, FileAccess.READ)
	if not ytConfigFile.is_open():
		return _log("Could not read file: " + fileUrl)

	var ytConfigText = ytConfigFile.get_as_text(true)
	if not ytConfigText:
		return _log("Could not read file: " + fileUrl)

	var ytConfigJson = JSON.parse_string(ytConfigText)
	if not ytConfigJson:
		return _log("Could not read file: " + fileUrl)

	var apiKey = ytConfigJson.get("apiKey")
	if not apiKey:
		return _log("Could not found apiKey on the config file:  " + fileUrl)
	
	_api_key = apiKey
	_live_id = liveId
	_is_stopped = false
	get_live_chat_id()

func get_live_chat_id():
	if _is_stopped: return
	$HTTPRequestGetLiveChatId.request("https://www.googleapis.com/youtube/v3/videos?part=liveStreamingDetails&key="+_api_key+"&id="+_live_id)
	
func get_next_chat_messages():	
	if _is_stopped: return
	if _next_page_token:
		$HTTPRequestGetLiveChatMessages.request("https://www.googleapis.com/youtube/v3/liveChat/messages?part=id%2C%20snippet&key="+_api_key+"&liveChatId="+_live_chat_id+"&pageToken="+_next_page_token)
	else:
		$HTTPRequestGetLiveChatMessages.request("https://www.googleapis.com/youtube/v3/liveChat/messages?part=id%2C%20snippet&key="+_api_key+"&liveChatId="+_live_chat_id)

func on_get_next_chat_messages(_result, _response_code, _header, body):
	$Timer.stop()
	if _is_stopped: return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json is Dictionary:
		var interval = json.get("pollingIntervalMillis")
		_next_page_token = json.get("nextPageToken")
		var messages = json.get("items")
		
		if messages is Array:
			for message in messages:
				if message is Dictionary:
					var snippet = message.get("snippet")
					if snippet is Dictionary:
						var messageType = snippet.get("type")
						if messageType is String && messageType == "textMessageEvent":
							var text = snippet.get("displayMessage")
							var authorId = snippet.get("authorChannelId")
							var timestamp = snippet.get("publishedAt")
							
							if (text is String && 
								authorId is String && 
								timestamp is String &&
								(begins_with == null || 
								 begins_with.is_empty() ||
								 text.begins_with(begins_with))):
								emit_signal(
									"yt_live_message_read",
									text,
									authorId,
									timestamp)
							else:
								_log("(ignoring) " + text)
		if interval is float:
			$Timer.wait_time = interval/1000
		else:
			$Timer.wait_time = 2
		_log("----- get next messages in " + str($Timer.wait_time) + " seconds -----")
		$Timer.start()
	else:
		_next_page_token = null
		get_live_chat_id()

func on_get_live_chat_id(_result, _response_code, _header, body):
	if _is_stopped: return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json is Dictionary:
		if logs:
			_log("Live info:")
			_log(str(json))
		var items = json.get("items")
		if items is Array:
			if items.size() > 0:
				var item = items[0]
				if item is Dictionary:
					var liveStreamingDetails = item.get("liveStreamingDetails")
					if liveStreamingDetails	is Dictionary:
						var activeLiveChatId = liveStreamingDetails.get("activeLiveChatId")
						if activeLiveChatId is String:
							_live_chat_id = activeLiveChatId
							get_next_chat_messages()
							return
	_log("error getting live chat id")
	_is_stopped = true

func is_running():
	return !_is_stopped

func stop():
	_next_page_token = null
	_is_stopped = true
	
func _log(text: String):
	if logs: print(text)
