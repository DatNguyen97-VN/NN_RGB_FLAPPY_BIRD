import math

def sigmoid(x):
    return 1 / (1 + math.exp(-x))

# Compute sigmoid values for the 17-bit input range
lut_size = 2**17  # [-65536 : +65535]
lut = []

for i in range(lut_size):
    # Normalize the input: scale from 0-131071 to -6 to +6
    normalized_input = (i / (lut_size - 1)) * 12 - 6  # Apply the normalization formula
    sigmoid_value = sigmoid(normalized_input)
    # Scale sigmoid output to 8-bit range (0-100)
    scaled_output = round(sigmoid_value * 100)
    lut.append(scaled_output)

# Write the LUT to a file in 8'hXX format
with open('sigmoid_lut.sv', 'w') as f:
    f.write("package sigmoid_package;\n\n")
    f.write(f"const logic [7:0] sigmoid_lut [{lut_size}]")
    f.write("= '{\n")
    for value in lut[:-1]:  # Write all but the last value
        f.write(f"8'h{value:02X},\n")
    # Write the last value
    f.write(f"8'h{lut[-1]:02X}\n")
    f.write("};\n\nendpackage\n")

print("Sigmoid LUT generated and written to sigmoid_lut.sv")
