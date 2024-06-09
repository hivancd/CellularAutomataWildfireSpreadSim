extends VBoxContainer
var directions = ["E","NE", "N", "NW", "W","SW", "S", "SE"]
var speeds = [0, 1, 2, 4, 16, 32]

var speds = []
var dirs = []
var dirsname = []
# Called when the node enters the scene tree for the first time.
func _ready():
	$CellularAutomata2D.pause = true
	
	for speed in speeds:
		for i in range(directions.size()):
			dirs.append(i)
			speds.append(speed)
			dirsname.append(directions[i])
			if speed == 0:
				break
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if $CellularAutomata2D.running_tests and $CellularAutomata2D.test_ended:
		$CellularAutomata2D.test_ended = false
		$CellularAutomata2D.pause = true
		var init_code = $VSplitContainer/StandAlone/TabContainer/INIT.text
		var exec_code = $VSplitContainer/StandAlone/TabContainer/EXEC.text
		var functions_code = $VSplitContainer/StandAlone/TabContainer/FUNC.text
		
		$CellularAutomata2D.wind_direction_string=dirsname[0]
		$CellularAutomata2D.wind_angle = dirs[0] * 2*PI/(directions.size())
		$CellularAutomata2D.wind_speed = speds[0]
		
		dirsname.remove_at(0)
		dirs.remove_at(0)
		speds.remove_at(0)
		if speds.size() <=0:
			$CellularAutomata2D.last_test = true
		
		var f = FileAccess.open("res://tests/test"+$CellularAutomata2D.wind_direction_string+str(int($CellularAutomata2D.wind_speed))+".txt",FileAccess.WRITE)
		var line = "step"+", "+"fire_count"+", "+"ashes_count"+", "+"grass_count"+", "+"forest_count"+", "+"ground_count"+", "+"water_count"+", "
		f.seek_end()
		f.store_line(line)
		f.close()
		$CellularAutomata2D._reinit_matrix(3)
		
		$CellularAutomata2D.cleanup_gpu()
		$CellularAutomata2D.clean_up_cpu()
		$CellularAutomata2D.compile(init_code, exec_code, functions_code)
		$CellularAutomata2D.pause=false
	
func _on_button_compile_pressed():
	$CellularAutomata2D.running_tests = false
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
	$HBoxToolbar/WindInd .pivot_offset = Vector2($HBoxToolbar/WindInd.size.x/2, $HBoxToolbar/WindInd.size.y/2)
	$HBoxToolbar/WindInd.rotation = 2*PI - $HBoxToolbar/VBoxContainer/HBoxContainer/WindAngle.value # Replace with function body.
	$CellularAutomata2D.wind_angle = $HBoxToolbar/VBoxContainer/HBoxContainer/WindAngle.value
	$HBoxToolbar/VBoxContainer/HBoxContainer/AngleValue.text = str(int(180 * $HBoxToolbar/VBoxContainer/HBoxContainer/WindAngle.value / PI))+" deg"


func _on_wind_speed_value_changed(value):
	$HBoxToolbar/WindInd .pivot_offset = Vector2($HBoxToolbar/WindInd.size.x/2, $HBoxToolbar/WindInd.size.y/2)
	$HBoxToolbar/WindInd.scale=Vector2(1+$HBoxToolbar/VBoxContainer/HBoxContainer2/WindSpeed.value/100,1/(1+$HBoxToolbar/VBoxContainer/HBoxContainer2/WindSpeed.value/100))
	$CellularAutomata2D.wind_speed = $HBoxToolbar/VBoxContainer/HBoxContainer2/WindSpeed.value
	$HBoxToolbar/VBoxContainer/HBoxContainer2/SpeedValue.text = str(int($HBoxToolbar/VBoxContainer/HBoxContainer2/WindSpeed.value))+" mph"

func _on_texture_rect_gui_input(event):
	if event.as_text() == "Left Mouse Button (Double Click)":
		var valX=int(($VSplitContainer/StandAlone/TextureRect.get_local_mouse_position().x/$VSplitContainer/StandAlone/TextureRect.size.x)*$CellularAutomata2D.WSX)
		var valY=int(($VSplitContainer/StandAlone/TextureRect.get_local_mouse_position().y/$VSplitContainer/StandAlone/TextureRect.size.y)*$CellularAutomata2D.WSY)
		$CellularAutomata2D.fire_queue.append(Vector2(valX,valY))

func _on_button_run_tests_pressed():
	var dirC :DirAccess = DirAccess.open("res://")
	if dirC.dir_exists("tests"):
		dirC.remove("tests")
	dirC.make_dir("tests")
	$CellularAutomata2D.running_tests = true
