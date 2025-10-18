set TOP_DIR $TOPLEVEL
set RPT_DIR report
set NET_DIR netlist

sh rm -rf ./$TOP_DIR
sh rm -rf ./$RPT_DIR
sh rm -rf ./$NET_DIR
sh mkdir ./$TOP_DIR
sh mkdir ./$RPT_DIR
sh mkdir ./$NET_DIR

# Define a lib path
define_design_lib $TOPLEVEL -path ./$TOPLEVEL

# Add your hdl files here
analyze -library $TOPLEVEL -format verilog "../hdl/ICLAB_enigma/enigma_pipeline.v"
#analyze -library $TOPLEVEL -format verilog "../hdl/ICLAB_enigma/rotor_dual.v"
analyze -library $TOPLEVEL -format verilog "../hdl/ICLAB_enigma/rotor_shift.v"
analyze -library $TOPLEVEL -format verilog "../hdl/ICLAB_enigma/rotorB_fixed.v"
analyze -library $TOPLEVEL -format verilog "../hdl/ICLAB_enigma/plugboard_dual.v"
analyze -library $TOPLEVEL -format verilog "../hdl/ICLAB_enigma/whitening.v"
analyze -library $TOPLEVEL -format verilog "../hdl/ICLAB_enigma/bitswitch.v"

# Elaborate your design
elaborate $TOPLEVEL -architecture verilog -library $TOPLEVEL

# Solve multiple instance
set uniquify_naming_style "%s_mydesign_%d"
uniquify

# Link the design
current_design $TOPLEVEL
link
