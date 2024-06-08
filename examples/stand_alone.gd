extends VBoxContainer

var inside :bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _on_button_compile_pressed():
	var m:int = $HBoxToolbar/HBoxContainer/OptionButton.selected
	if m<0:
		m=1
	
	$CellularAutomata2D._reinit_matrix(m)

	var init_code = $VSplitContainer/StandAlone/TabContainer/INIT.text
	var exec_code = $VSplitContainer/StandAlone/TabContainer/EXEC.text
	var functions_code = $VSplitContainer/StandAlone/TabContainer/FUNC.text
	
	$CellularAutomata2D.pause = true
	$CellularAutomata2D.cleanup_gpu()
	$CellularAutomata2D.clean_up_cpu()
	$CellularAutomata2D.compile(init_code, exec_code, functions_code)
	
	$CellularAutomata2D.compute() # current_pass = 0
	$CellularAutomata2D.compute() # current_pass = 1
	$CellularAutomata2D.display_all_values()
	
	#$LabelErrors.text = $CellularAutomata2D.err_msg
	$VSplitContainer/TextEdit.text = $CellularAutomata2D.err_msg


func _on_h_slider_value_changed(value):
	$HBoxToolbar/Sprite2D.rotation = 2*PI - $HBoxToolbar/VBoxContainer/HBoxContainer/WindAngle.value # Replace with function body.
	$CellularAutomata2D.wind_angle = $HBoxToolbar/VBoxContainer/HBoxContainer/WindAngle.value
	$HBoxToolbar/VBoxContainer/HBoxContainer/AngleValue.text = str(int(180 * $HBoxToolbar/VBoxContainer/HBoxContainer/WindAngle.value / PI))+" deg"


func _on_wind_speed_value_changed(value):
	$CellularAutomata2D.wind_speed = $HBoxToolbar/VBoxContainer/HBoxContainer2/WindSpeed.value
	$HBoxToolbar/VBoxContainer/HBoxContainer2/SpeedValue.text = str(int($HBoxToolbar/VBoxContainer/HBoxContainer2/WindSpeed.value))+" mph"


func _on_texture_rect_gui_input(event):
	if event.as_text() == "Left Mouse Button (Double Click)":
		var valX=int(($VSplitContainer/StandAlone/TextureRect.get_local_mouse_position().x/$VSplitContainer/StandAlone/TextureRect.size.x)*$CellularAutomata2D.WSX)
		var valY=int(($VSplitContainer/StandAlone/TextureRect.get_local_mouse_position().y/$VSplitContainer/StandAlone/TextureRect.size.y)*$CellularAutomata2D.WSY)
		$CellularAutomata2D.fire_queue.append(Vector2(valX,valY))
		#print($CellularAutomata2D.fire_queue)
