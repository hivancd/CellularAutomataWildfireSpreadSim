extends VBoxContainer


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

	var init_code = $VSplitContainer/StandAlone/VBoxCode/TextEditInit .text
	var exec_code = $VSplitContainer/StandAlone/VBoxCode/TextEditExec.text
	var functions_code = $VSplitContainer/StandAlone/VBoxCode/TextEditFunc.text
	
	$CellularAutomata2D.pause = true
	$CellularAutomata2D.cleanup_gpu()
	$CellularAutomata2D.clean_up_cpu()
	$CellularAutomata2D.compile(init_code, exec_code, functions_code)

	$CellularAutomata2D.display_all_values()
	
	#$LabelErrors.text = $CellularAutomata2D.err_msg
	$VSplitContainer/TextEdit.text = $CellularAutomata2D.err_msg


func _on_option_button_2_item_selected(index):
	match index:
		0:
			$VSplitContainer/StandAlone/VBoxCode/TextEditInit.visible = true
			$VSplitContainer/StandAlone/VBoxCode/TextEditExec.visible = false
			$VSplitContainer/StandAlone/VBoxCode/TextEditFunc.visible = false
		1:
			$VSplitContainer/StandAlone/VBoxCode/TextEditInit.visible = false
			$VSplitContainer/StandAlone/VBoxCode/TextEditExec.visible = true
			$VSplitContainer/StandAlone/VBoxCode/TextEditFunc.visible = false
		2:
			$VSplitContainer/StandAlone/VBoxCode/TextEditInit.visible = false
			$VSplitContainer/StandAlone/VBoxCode/TextEditExec.visible = false
			$VSplitContainer/StandAlone/VBoxCode/TextEditFunc.visible = true
