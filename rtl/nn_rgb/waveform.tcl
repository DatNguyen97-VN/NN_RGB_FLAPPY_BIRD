#Video in signals
add wave -group "Video In" /sim_nn_rgb/duv/r_in
add wave -group "Video In" /sim_nn_rgb/duv/g_in
add wave -group "Video In" /sim_nn_rgb/duv/b_in

#Video out signals
add wave -group "Video Out" /sim_nn_rgb/duv/r_out
add wave -group "Video Out" /sim_nn_rgb/duv/g_out
add wave -group "Video Out" /sim_nn_rgb/duv/b_out

# Initialize layer and neuron indices
set layer_index 1
set neuron_index 0

# Define the list of signals that need to be set to unsigned and decimal radix
set decimal_signals {sumForActivation accumulate sum}
set unsigned_signals {out sumAdress l_connection_idx}

# Loop to find instances of gen_neuron within gen_layer instances
while {1} {
    set layer_path "/sim_nn_rgb/duv/gen_layer\[$layer_index\]"
    set neuron_path "$layer_path/gen_neuron\[$neuron_index\]/knot"
    set result [find signals $neuron_path/*]
    
    if {[llength $result] > 0} {
        # Add wave for weight parameter signal
        add wave -radix unsigned -group "Layer $layer_index" -group "Neuron $neuron_index" $neuron_path/h_weight_idx
        add wave -radix unsigned -group "Layer $layer_index" -group "Neuron $neuron_index" $neuron_path/l_weight_idx
        # Add layer and neuron
        foreach signal $result {
            # Get the signal name (strip the path to get the last part of the signal)
            set signal_name [file tail $signal]
            if {[lsearch -exact $decimal_signals $signal_name] != -1} {
                # Add wave with decimal radix for signals in the decimal_signals list
                add wave -radix decimal -group "Layer $layer_index" -group "Neuron $neuron_index" $signal
            } elseif {[lsearch -exact $unsigned_signals $signal_name] != -1} {
                # Add wave with decimal radix for signals in the unsigned_signals list
                add wave -radix unsigned -group "Layer $layer_index" -group "Neuron $neuron_index" $signal
            } else {
                # Add wave with default settings
                add wave -group "Layer $layer_index" -group "Neuron $neuron_index" $signal
            }
        }
        # Add multiplier instance
        set multi_index 0
        while {1} {
            set multi_path "$neuron_path/mult\[$multi_index\]/mult_i"
            set result [find signals $multi_path/*]
            if {[llength $result] > 0} {
                # Add wave with decimal settings
                add wave -radix decimal -group "Layer $layer_index" -group "Neuron $neuron_index" -group "Mult $multi_index" $multi_path/weight
                # Add wave with unsigned settings
                add wave -radix unsigned -group "Layer $layer_index" -group "Neuron $neuron_index" -group "Mult $multi_index" $multi_path/in
                # Add wave with unsigned settings
                add wave -radix decimal -group "Layer $layer_index" -group "Neuron $neuron_index" -group "Mult $multi_index" $multi_path/out
            } else {
                break;# Exit loop if no more mult instances found
            }
            #Next mult instance
            incr multi_index
        }
        # Next neuron
        incr neuron_index
    } else {
        # If no more gen_neuron instances in current gen_layer, move to the next gen_layer
        incr layer_index
        set neuron_index 0 ;# Reset neuron_index for the next layer
        if {[catch {find blocks $layer_path} result] != 0 || $result == ""} {
            break ;# Exit loop if no more gen_layer instances found
        }
        continue ;# Skip neuron_index incrementation for this iteration
    }
}

# Connection signals
add wave -radix unsigned -group "Connection" /CONFIG::connection

# Centroids Object signals
set centroids_signals {de_1 vs_1 endline_ff frame_ff y_axis num_pixel sum_y_axis aver_y_axis}

set duv_path "/sim_nn_rgb/duv"
set result [find signals $duv_path/*]

foreach signal $result {
    set signal_name [file tail $signal]
    if {[lsearch -exact $centroids_signals $signal_name] != -1} {
        add wave -radix unsigned -group "Centroids Object" $signal
    }
}

# up signals
add wave -radix unsigned -group "Turn Up" /sim_nn_rgb/duv/y_frame
add wave -radix unsigned -group "Turn Up" /sim_nn_rgb/duv/y_old_frame
add wave -radix unsigned -group "Turn Up" /sim_nn_rgb/duv/up

# Output the completion message
puts "Added waves for signals in all gen_layer and gen_neuron instances."
