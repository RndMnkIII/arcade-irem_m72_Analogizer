# TCL Script para generar configuración de PLL con Quartus sin GUI
# Uso: quartus_sh -t generar_config.tcl --in 74.25 --out 99.450559 --name pll99

# Procesar argumentos
foreach {arg val} $quartus(args) {
    if {$arg == "--in"} {
        set freq_in $val
    } elseif {$arg == "--out"} {
        set freq_out $val
    } elseif {$arg == "--name"} {
        set pll_name $val
    }
}

if {![info exists freq_in] || ![info exists freq_out] || ![info exists pll_name]} {
    puts "Faltan argumentos. Uso: --in=74.25 --out=96 --name=pll96"
    exit 1
}

load_package altpll

set_instance_parameter inclk0_input_frequency "$freq_in MHz"
set_instance_parameter clk0_output_frequency "$freq_out MHz"

# Salidas derivadas de salida0
set_instance_parameter clk1_multiply_by 1
set_instance_parameter clk1_divide_by 3

set_instance_parameter clk2_multiply_by 1
set_instance_parameter clk2_divide_by 12

set_instance_parameter clk3_multiply_by 1
set_instance_parameter clk3_divide_by 12
set_instance_parameter clk3_phase_shift "90"

set_instance_parameter operation_mode "normal"
set_instance_parameter intended_device_family "Cyclone V"

set_module_assignment output_directory "./$pll_name"
generate_component altpll $pll_name

puts "Generado PLL: $pll_name con entrada $freq_in MHz y salida $freq_out MHz"
