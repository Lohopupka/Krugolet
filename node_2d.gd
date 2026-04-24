extends Node

var db
var db_path = "user://tasks_database.db"
var server_url = "http://192.168.1.166:5000"
var sync_timer = 0.0
var sync_interval = 5.0
var http_request: HTTPRequest

func _ready():
	create_db()
	db = SQLite.new()
	db.path = db_path
	
	if db.open_db():
		print("База успешно открыта")
		create_table()
		
		http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(_handle_server_response)
		
		sync_with_server()
	else:
		print("Не удалось открыть базу данных")

func _process(delta):
	sync_timer += delta
	if sync_timer >= sync_interval:
		sync_with_server()
		sync_timer = 0.0

func create_table():
	var table_dictionary = {
		"id": {"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"title": {"data_type": "text", "not_null": true},
		"description": {"data_type": "text"},
		"due_date": {"data_type": "text"},
		"status": {"data_type": "text"},
		"grup": {"data_type": "int"}
	}
	db.create_table("tasks", table_dictionary)

func create_db():
	print("Путь к базе данных: ", OS.get_user_data_dir())
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	
	var table_dictionary = {
		"id": {"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"title": {"data_type": "text", "not_null": true},
		"description": {"data_type": "text"},
		"due_date": {"data_type": "text"},
		"status": {"data_type": "text"},
		"grup": {"data_type": "text"}
	}
	db.create_table("tasks", table_dictionary)

func sync_with_server():
#задачи
	print("Синхронизация с сервером")
	http_request.request(server_url + "/tasks", [], HTTPClient.METHOD_GET)

func _handle_server_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json_string = body.get_string_from_utf8()
		var json = JSON.new()
		var tasks = json.parse_string(json_string)
		
		if tasks is Array:
			update_local_db(tasks)
			delete_removed_tasks(tasks)  # Добавляем удаление
			print("Синхронизация завершена. Получено задач: ", tasks.size())
	else:
		print("Ошибка код: ", response_code)

func update_local_db(tasks: Array):
	for task in tasks:
		var title = task["title"] if "title" in task else ""
		var description = task["description"] if "description" in task else ""
		var due_date = task["due_date"] if "due_date" in task else ""
		var status = task["status"] if "status" in task else "pending"
		var grup = str(task["grup"]) if "grup" in task else "1"
		var task_id = task["id"] if "id" in task else 0
		
		db.query_with_bindings(
			"INSERT OR IGNORE INTO tasks (id, title, description, due_date, status, grup) VALUES (?, ?, ?, ?, ?, ?)",
			[task_id, title, description, due_date, status, grup]
		)
		print("Обработана задача: ", title)

func delete_removed_tasks(server_tasks: Array):
	var server_ids = []
	for task in server_tasks:
		if "id" in task:
			server_ids.append(task["id"])
	
	var placeholders = ",".join(server_ids.map(func(id): return str(id)))
	
	if placeholders.length() > 0:
		db.query("DELETE FROM tasks WHERE id NOT IN(" + placeholders + ")")
		print("удаленные задачи, которых нет на сервере")

func add_task(title: String, desc: String, due: String, status: String, grup: String):
	var data = {
		"title": title,
		"description": desc,
		"due_date": due,
		"status": status,
		"grup": int(grup) if grup.is_valid_int() else 1
	}
	
	var json_string = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	print("Отправляю задачу: ", json_string)
	http_request.request(server_url + "/tasks", headers, HTTPClient.METHOD_POST, json_string)
	await get_tree().create_timer(1.0).timeout
	sync_with_server()
