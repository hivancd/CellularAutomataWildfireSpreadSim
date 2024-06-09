extends Node
class_name CellularAutomata2D

var current_pass 	: int = 0
var fire_queue : PackedVector2Array
#region ComputeShaderStudio

var GLSL_header = ""
## Print the current step.
@export var print_step:bool = false
## Print the current pass.
var print_passes:bool = false
## Print in Output all the generated code.
## Can be usefull for debugging.
@export var print_generated_code:bool = false
## Do not execute compute shader at launch.
@export var pause:bool = false
var running_tests :bool = false
@export var show_tests :bool = false
var test_ended = true
@export var samples_distance :int = 10
var last_test = false
## Number of passes (synchronized code) needed.
var nb_passes		: int = 2
## Workspace Size X, usually it matches the x size of your Sprite2D image
@export var WSX				: int = 128
## Workspace Size Y, usually it matches the y size of your Sprite2D image
@export var WSY				: int = 128

var wind_angle : float = 0.0
var wind_direction_string :String = ""
var wind_speed : float = 0.0
var state = {}

## Drag and drop your Sprite2D here.
@export var display_in:Node
#var matrix_future:Sprite2D

@export var cell_states : Array[StringColor] = [StringColor.new()]

## Write your initialisation code here (in GLSL)
@export_multiline var init_code : String = """
// INITIALISATION CODE (step = 0)
// You will use the following variables:
//    uint WSX, WSY (global WorkSpace in X and Y)
//    uint x,y,p (cell position)
//    int present_state (cell state. An integer random value from int.MIN and int.MAX)
//    int future_state (the new cell state)

"""

## Write your execution code here (in GLSL)
@export_multiline var exec_code : String = """
// EXECUTION CODE (step >= 1)
// You will use the following variables:
//    uint WSX, WSY (global WorkSpace in X and Y)
//    uint x,y,p (cell position)
//    int present_state (current cell state. Do not modify)
//    int future_state (the new cell state)
// STATES: 
"""

## Write your own functions here (in GLSL)
@export_multiline var functions_code : String = """
// FUNCTIONS CODE
// Write all your functions here (in GLSL)
// You can use the following global variables:
//    uint WSX, WSY (global WorkSpace in X and Y)
// Example
// int your_function(int x, int y) {
//    if (x == WSX/2 && y == WSY/2)
//       return my_state_1
//    else
//       return my_state_2
// }
"""

var rd 				: RenderingDevice
var shader 			: RID
var shader_src 		: RDShaderSource
var buffers 		: Array[RID]
var buffer_params 	: RID

var uniforms		: Array[RDUniform]
#var uniform_2 		: RDUniform
var uniform_params 	: RDUniform

var buffers_init	: bool = false
var uniforms_init	: bool = false

var bindings		: Array = []

var pipeline		: RID
var uniform_set		: RID

# Called when the node enters the scene tree for the first time.
#region _ready
#func _enter_tree():
#	cell_states = [StringColor.new(),StringColor.new()]
func _ready():
	compile(init_code,exec_code,functions_code)

var err_msg:String = ""

func compile(init : String, exec : String, functions : String):
	err_msg = ""
	step = 0
	current_pass = 0
	# Create a local rendering device.
	if not rd:
		rd = RenderingServer.create_local_rendering_device()
	if not rd:
		set_process(false)
		err_msg = "Compute shaders are not available"
		print(err_msg)
		return
		
	# *********************
	# *  SHADER CREATION  *
	# *********************

	GLSL_header = """#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Bindings to the buffers we create in our script
layout(binding = 0) buffer Params {
	int step;
	int current_pass;
	int sfx;
	int sfy;
	float wind_angle;
	float wind_speed;
};

"""


	var nb_buffers : int = 4

	# Create GLSL Header
	GLSL_header += """
uint WSX="""+str(WSX)+""";"""+"""
uint WSY="""+str(WSY)+""";
"""

	GLSL_header += """
layout(binding = 1) buffer Data0 {
	int data_present[];
};

"""
	GLSL_header += """
layout(binding = 2) buffer Data1 {
	int data_future[];
};

"""

	GLSL_header += """
layout(binding = 3) buffer Data2 {
	float data_values[];
};

"""
	GLSL_header += """
layout(binding = 4) buffer Data3 {
	float random_values[];
};

"""
	#print("0xf19b00ff".hex_to_int())

	var states_code : String = "" # States of cells
	for s in cell_states:
		var col_html:String = s.color.to_html(true)
		var R:String = col_html.substr(0,2)
		var G:String = col_html.substr(2,2)
		var B:String = col_html.substr(4,2)
		var A:String = col_html.substr(6,2)
		var line : String = "int " +s.text+ " = 0x" +A+B+G+R+";"
		line += """
"""
		states_code += line
	GLSL_header += states_code

	for s in cell_states:
		var col_html:String = s.color.to_html(true)
		var R:String = col_html.substr(0,2)
		var G:String = col_html.substr(2,2)
		var B:String = col_html.substr(4,2)
		var A:String = col_html.substr(6,2)
		var cll = "0x"+A+B+G+R
		state[s.text]=cll.hex_to_int()
		#state[s.text]=(col_html).hex_to_int()
			
	GLSL_header += """
uint nb_neighbors_4(uint x,uint y, int state) {
	uint nb = 0;
	uint x_l = uint((int(x)+int(WSX)-1)) % WSX;
	uint x_r = uint((int(x)+int(WSX)+1)) % WSX;
	uint y_d = uint((int(y)+int(WSY)-1)) % WSY;
	uint y_u = uint((int(y)+int(WSY)+1)) % WSY;
	if (data_present[x_l + y_d * WSX] == state) nb++;
	if (data_present[x_l + y_u * WSX] == state) nb++;
	if (data_present[x_r + y_d * WSX] == state) nb++;
	if (data_present[x_r + y_u * WSX] == state) nb++;
	return nb;
}
uint nb_neighbors_8(uint x,uint y, int state) {
	uint nb = 0;
	uint p = x + y * WSX;
	for(int i = int(x)-1; i <= int(x)+1; i++) {
		uint ii = uint((i+int(WSX))) % WSX;
		for(int j = int(y)-1; j <= int(y)+1; j++) {
			uint jj = uint((j+int(WSY))) % WSY;
			uint kk = ii + jj * WSX;
			if(data_present[kk] == state && kk != p)
				nb++;
		}
	}
	return nb;
}
"""

	GLSL_header += functions


	var GLSL_code : String = """
void main() {
	uint x = gl_GlobalInvocationID.x;
	uint y = gl_GlobalInvocationID.y;
	uint p = x + y * WSX;

	if(current_pass == 0) {
		int present_state = data_present[p];
		// Write your RULES below vvvvvvvvvvvvvvvvv
		int future_state = present_state;
		if(step == 0) { // Initialization ---------
""" + init + """
		} else { // Execution----------------------
""" + exec + """
		}
		// END of your RULES ^^^^^^^^^^^^^^^^^^^^^^
		data_future[p] = future_state;
	} else { // current_pass = 1
		data_present[p] = data_future[p];
	}

}
"""



	var GLSL_all : String = GLSL_header + GLSL_code
	if print_generated_code == true:
		print(GLSL_all)
	
	# Compile the shader by passing a string
	if not shader_src:
		shader_src = RDShaderSource.new()
	shader_src.set_stage_source(RenderingDevice.SHADER_STAGE_COMPUTE, GLSL_all)
	var shader_spirv := rd.shader_compile_spirv_from_source(shader_src)
	
	err_msg = shader_spirv.compile_error_compute
	
	if err_msg != "":
		printerr(err_msg)
		return
	
	shader = rd.shader_create_from_spirv(shader_spirv)









	# *********************
	# *  BUFFERS CREATION *
	# *********************
	if buffers_init == false:
		# Buffer for current_pass
		var input_paramsI :PackedInt32Array = PackedInt32Array()
		var input_paramsII :PackedFloat32Array = PackedFloat32Array()
		input_paramsI.append(step)
		input_paramsI.append(current_pass)
		
		if fire_queue.size()>0:
			input_paramsI.append(int(fire_queue[0].x))
			input_paramsI.append(int(fire_queue[0].y))
		else:
			input_paramsI.append(-1)
			input_paramsI.append(-1)
			
		input_paramsII.append(wind_angle)
		input_paramsII.append(wind_speed)
		var input_params_bytes := input_paramsI.to_byte_array()
		var input_paramsII_bytes := input_paramsII.to_byte_array()
		input_params_bytes.append_array(input_paramsII_bytes)
		# Create a GPU Buffer from the CPU one
		buffer_params = rd.storage_buffer_create(input_params_bytes.size(), input_params_bytes)
		# Buffers from/for data (Sprite2D)
		for b in nb_buffers:
			var input :PackedInt32Array = PackedInt32Array()
			for i in range(WSX):
				for j in range(WSY):
					input.append(randi())
			var input_bytes :PackedByteArray = input.to_byte_array()
			buffers.append(rd.storage_buffer_create(input_bytes.size(), input_bytes))

	buffers_init = true

	# *********************
	# * UNIFORMS CREATION *
	# *********************
	if uniforms_init == false:
		# Create current_pass uniform pass
		uniform_params = RDUniform.new()
		uniform_params.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		uniform_params.binding = 0 # this needs to match the "binding" in our shader file
		uniform_params.add_id(buffer_params)
		
		var nb_uniforms : int = 4
		for b in nb_uniforms:
			var uniform = RDUniform.new()
			uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			uniform.binding = b+1 # this needs to match the "binding" in our shader file
			uniform.add_id(buffers[b])
			uniforms.append(uniform)

		# Create the uniform SET between CPU & GPU
		bindings = [uniform_params]
		for b in nb_buffers:
			bindings.append(uniforms[b])
		
		uniform_set = rd.uniform_set_create(bindings, shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file

		uniforms_init = true


	# **************************
	# *  COMPUTE LIST CREATION *
	# **************************
	# Create a compute pipeline
	pipeline = rd.compute_pipeline_create(shader)
	
	# Execute once (should it stay?)
	# compute()
	# Read back the data from the buffer
	# display_all_values()
#endregion

func display_all_values():
	# Read back the data from the buffers
	var output_bytes :   PackedByteArray = rd.buffer_get_data(buffers[0])
	if is_instance_valid(display_in):
		display_values(display_in, output_bytes)
	var output_bytes_future :   PackedByteArray = rd.buffer_get_data(buffers[1])
	#if is_instance_valid(matrix_future):
	#	display_values(matrix_future, output_bytes)

func display_values(disp, values : PackedByteArray):
	var image_format : int = Image.FORMAT_RGBA8
	var image := Image.create_from_data(WSX, WSY, false, image_format, values)
	disp.set_texture(ImageTexture.create_from_image(image))

var step  : int = 0

func compute():
	if print_step == true && current_pass%nb_passes == 0:
		print("Step="+str(step))
	if print_passes == true:
		print(" CurrentPass="+str(current_pass))
		
	_update_uniforms()
	# Prepare the Computer List ############################################
	var compute_list : int = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, WSX>>3, WSY>>3, 1)
	rd.compute_list_end()
	#######################################################################

	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	
	# Update step and current_passe
	current_pass = (current_pass + 1) % nb_passes
	if current_pass == 0:
		step += 1

func compute_tests():
	if print_step == true && current_pass%nb_passes == 0:
		print("Step="+wind_direction_string+str(int(wind_speed))+" "+str(step))
	if print_passes == true:
		print(" CurrentPass="+str(current_pass))
		
	_update_uniforms()
	
	# Prepare the Computer List ############################################
	var compute_list : int = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, WSX>>3, WSY>>3, 1)
	rd.compute_list_end()
	#######################################################################

	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	if step%samples_distance==0 and current_pass==(nb_passes-1):
		var data = rd.buffer_get_data(buffers[0])
		var intMatrix = data.to_int32_array()
		
		var fire = intMatrix[0]
		var ashes = intMatrix[1]
		var grass = intMatrix[2]
		var forest = intMatrix[3]
		var ground = intMatrix[4]
		var water = intMatrix[5]
		
		var fire_count = 0
		var ashes_count = 0
		var grass_count = 0
		var forest_count = 0
		var ground_count = 0
		var water_count = 0
		for value in intMatrix:
			match value:
				fire:
					fire_count += 1
				ashes:
					ashes_count += 1
				grass:
					grass_count += 1					
				forest:
					forest_count +=1
				ground:
					ground_count += 1
				water:
					water_count += 1
					
		var strValues:PackedStringArray = PackedStringArray()
		
		var f = FileAccess.open("res://tests/test"+wind_direction_string+str(int(wind_speed))+".txt",FileAccess.READ_WRITE)
		f.seek_end()
		var line = str(step)+", "+str(fire_count-1)+", "+str(ashes_count)+", "+str(grass_count)+", "+str(forest_count)+", "+str(ground_count)+", "+str(water_count)
		f.store_line(line)
		f.close()
		
		if fire_count <=1 and step!=0:
			test_ended = true
			print("SIMULATION "+wind_direction_string+str(int(wind_speed))+" TERMINATED")
			pause=true
			if last_test:
				print("TESTS FINISHED")
				last_test = false
				running_tests=false
	# Update step and current_passe
	current_pass = (current_pass + 1) % nb_passes
	if current_pass == 0:
		step += 1

func _process(_delta):
	if pause == false:
		if running_tests:
			compute_tests()
			if show_tests:
				display_all_values()
		else:
			compute()
			display_all_values()
		

## Pass the interesting values from CPU to GPU
func _update_uniforms():
	# Create a CPU Buffer for current_pass
	var input_paramsI :PackedInt32Array = PackedInt32Array()
	input_paramsI.append(step)
	var input_paramsII :PackedFloat32Array = PackedFloat32Array()
	input_paramsI.append(current_pass)

	if fire_queue.size()>0:
		input_paramsI.append(int(fire_queue[0].x))
		input_paramsI.append(int(fire_queue[0].y))
		fire_queue.remove_at(0)
	else:
		input_paramsI.append(-1)
		input_paramsI.append(-1)
		
	input_paramsII.append(wind_angle)
	input_paramsII.append(wind_speed)
	var input_params_bytes := input_paramsI.to_byte_array()
	var input_paramsII_bytes := input_paramsII.to_byte_array()
	input_params_bytes.append_array(input_paramsII_bytes)
		# Create a GPU Buffer from the CPU one
	buffer_params = rd.storage_buffer_create(input_params_bytes.size(), input_params_bytes)
		
	# Set the new buffer thanks to a new uniform between the CPU and the GPU
	uniform_params = RDUniform.new()
	uniform_params.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_params.binding = 0 # this needs to match the "binding" in our shader file
	uniform_params.add_id(buffer_params)
	bindings[0] = uniform_params
	
	# Set the new values from the CPU to the GPU
	# Note: when changing the uniform set, use the same bindings Array (do not create a new Array)
	uniform_set = rd.uniform_set_create(bindings, shader, 0)
	

## Pass the interesting values from CPU to GPU
func _reinit_matrix(m:int):
	# Buffers from/for data (Sprite2D)
	var input :PackedInt32Array = PackedInt32Array()
	var inputc :PackedFloat32Array = PackedFloat32Array()
	var inputrand :PackedFloat32Array = PackedFloat32Array()
	
	var loaded = false
	var data=""
	#seed(666)
	
	for i in range(WSX):
		for j in range(WSY):
			inputc.append(float(0))
			inputrand.append(randf())
			if m==0:
				input.append(0x00000000)
			if m==1:
				input.append(randi())
			if m==2:
				if not loaded:
					OS.execute("python",["./terrain_generator/generator.py", str(WSX), str(WSY)])
					OS.execute("python3",["./terrain_generator/generator.py", str(WSX), str(WSY)])
					data = FileAccess.open("res://map.txt", FileAccess.READ).get_as_text()
					loaded = true
				input.append(int(data[(i+j*WSX)%data.length()]))
			if m==3:
				if not loaded:
					data = FileAccess.open("res://YoungLand.txt", FileAccess.READ).get_as_text()
					loaded = true
				input.append(int(data[(i+j*WSX)%data.length()]))
	var input_bytes :PackedByteArray = input.to_byte_array()
	var inputc_bytes :PackedByteArray = inputc.to_byte_array()
	var inputrand_bytes :PackedByteArray = inputrand.to_byte_array()
	
	buffers[0]=(rd.storage_buffer_create(input_bytes.size(), input_bytes))
	buffers[2]=(rd.storage_buffer_create(inputc_bytes.size(), inputc_bytes))
	buffers[3]=(rd.storage_buffer_create(inputrand_bytes.size(), inputrand_bytes))
	
	# Uniform
	
	var uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 1 # this needs to match the "binding" in our shader file
	uniform.add_id(buffers[0])
	bindings[1] = uniform
	var uniform2 = RDUniform.new()
	uniform2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform2.binding = 3 # this needs to match the "binding" in our shader file
	uniform2.add_id(buffers[2])
	bindings[3] = uniform2
	var uniform3 = RDUniform.new()
	uniform3.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform3.binding = 4 # this needs to match the "binding" in our shader file
	uniform3.add_id(buffers[3])
	bindings[4] = uniform3
	# Set the new values from the CPU to the GPU
	# Note: when changing the uniform set, use the same bindings Array (do not create a new Array)
	uniform_set = rd.uniform_set_create(bindings, shader, 0)

func _notification(notif):
	# Object destructor, triggered before the engine deletes this Node.
	if notif == NOTIFICATION_PREDELETE:
		cleanup_gpu()
		
func cleanup_gpu():
	if rd == null:
		return
	# All resources must be freed after use to avoid memory leaks.
	rd.free_rid(pipeline)
	pipeline = RID()

	rd.free_rid(uniform_set)
	uniform_set = RID()

	rd.free_rid(shader)
	shader = RID()

	#rd.free()
	#rd = null

func clean_up_cpu():
	#buffers = []#.clear()
	#uniforms = []#.clear()
	#bindings = []#.clear()
	pass

#endregion

func _on_button_step():
	pause = true
	compute() # current_pass = 0
	compute() # current_pass = 1
	display_all_values()

func _on_button_play():
	pause = !pause # Replace with function body.
