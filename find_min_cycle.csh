#!/bin/tcsh

# Script to automatically find the minimum non-violating cycle time for synthesis.

# --- Validation ---
if ($#argv != 2) then
    echo "Usage: `basename $0` <start_cycle> <step>"
    echo "  <start_cycle>: The initial cycle time to test (e.g., 5.0)."
    echo "  <step>       : The interval to adjust the cycle time (e.g., 0.1)."
    exit 1
endif

set current_cycle = $1
set step = $2
set direction = ""
set min_cycle = ""

# --- Initial Run ---
# First, determine if the starting cycle is passing or failing to set the search direction.

echo "--- Starting Search ---"
echo "Initial cycle time: $current_cycle, Step: $step"

# Modify synthesis.tcl for the first run
sed "s/set TEST_CYCLE .*/set TEST_CYCLE $current_cycle/" synthesis.tcl > synthesis.tcl.tmp
mv synthesis.tcl.tmp synthesis.tcl

echo "Running synthesis with TEST_CYCLE = $current_cycle..."
dc_shell -f synthesis.tcl | tee logfile >& /dev/null

# Check slack of the first run
set slack_value = `grep "slack (" report/report_time_enigma_pipeline.out | awk '{print $NF}'`
set is_violated = `echo "$slack_value < 0" | bc`

if ($is_violated == 1) then
    set direction = "increase"
    echo "Initial cycle $current_cycle has timing violations. Direction: increase."
else
    set direction = "decrease"
    set last_good_cycle = $current_cycle
    echo "Initial cycle $current_cycle passed. Direction: decrease."
endif


# --- Iteration Loop ---
while (1)
    if ($direction == "decrease") then
        set next_cycle = `echo "$current_cycle - $step" | bc`
    else
        set next_cycle = `echo "$current_cycle + $step" | bc`
    endif
    
    set current_cycle = $next_cycle

    # Modify synthesis.tcl
    sed "s/set TEST_CYCLE .*/set TEST_CYCLE $current_cycle/" synthesis.tcl > synthesis.tcl.tmp
    mv synthesis.tcl.tmp synthesis.tcl

    echo "Running synthesis with TEST_CYCLE = $current_cycle..."
    dc_shell -f synthesis.tcl | tee logfile >& /dev/null

    # Check slack
    set slack_value = `grep "slack (" report/report_time_enigma_pipeline.out | awk '{print $NF}'`
    set is_violated = `echo "$slack_value < 0" | bc`

    if ($direction == "decrease") then
        if ($is_violated == 1) then
            # Found the first failing cycle, so the last good one is the minimum.
            set min_cycle = $last_good_cycle
            echo "Violation found at $current_cycle. Minimum passing cycle is $min_cycle."
            break
        else
            # This cycle passed, keep trying smaller values.
            set last_good_cycle = $current_cycle
            echo "No violation at $current_cycle (slack: $slack_value). Continuing..."
        endif
    else # direction == "increase"
        if ($is_violated == 0) then
            # Found the first passing cycle. This is the minimum.
            set min_cycle = $current_cycle
            echo "No violation found at $current_cycle. This is the minimum passing cycle."
            break
        else
            # This cycle failed, keep trying larger values.
            echo "Violation at $current_cycle (slack: $slack_value). Continuing..."
        endif
    endif
end


# --- Finalization ---
if ($min_cycle != "") then
    echo "
--- Finalizing ---"
    echo "Running final synthesis with minimum cycle time: $min_cycle"
    sed "s/set TEST_CYCLE .*/set TEST_CYCLE $min_cycle/" synthesis.tcl > synthesis.tcl.tmp
    mv synthesis.tcl.tmp synthesis.tcl
    dc_shell -f synthesis.tcl | tee logfile >& /dev/null

    echo "
--------------------------------------------------"
    echo "Final Result:"
    echo "Minimum non-violating TEST_CYCLE is: $min_cycle"
    echo "Reports are generated for this cycle time."
    echo "--------------------------------------------------"
else
    echo "Error: Could not determine the minimum cycle time."
endif
