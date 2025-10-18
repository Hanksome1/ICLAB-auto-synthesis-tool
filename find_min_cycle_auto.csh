#!/bin/tcsh

# Script to automatically find the minimum non-violating cycle time for synthesis
# by iteratively refining the search step.

# --- Validation ---
if ($#argv != 1) then
    echo "Usage: `basename $0` <start_cycle>"
    echo "  <start_cycle>: A cycle time that is known to pass timing (e.g., 5.0)."
    exit 1
endif

# --- Setup ---
set current_cycle = $1
set last_good_cycle = $current_cycle
set steps = (1 0.1 0.01 0.005)
set min_cycle = ""

# --- Initial Check ---
# Verify that the starting cycle actually passes timing.
echo "--- Verifying Start Cycle ---"
echo "Testing initial cycle time: $current_cycle"
sed "s/set TEST_CYCLE .*/set TEST_CYCLE $current_cycle/" synthesis.tcl > synthesis.tcl.tmp && mv synthesis.tcl.tmp synthesis.tcl
dc_shell -f synthesis.tcl | tee logfile >& /dev/null
set slack_value = `grep "slack (" report/report_time_enigma_pipeline.out | awk '{print $NF}'`

if ("$slack_value" == "") then
    echo "Error: Could not find slack in the report. Cannot verify start_cycle."
    exit 1
endif

set is_violated = `awk -v slack="$slack_value" 'BEGIN { print(slack < 0) }'`

if ($is_violated == 1) then
    echo "Error: The provided start_cycle ($current_cycle) has timing violations. Please provide a known passing cycle time."
    exit 1
endif
echo "Start cycle $current_cycle passed timing."


# --- Main Search Loop ---
foreach step ($steps)
    echo "
--- Searching with step = $step ---"
    # Start searching downwards from the last known good cycle
    while (1)
        set last_good_cycle = $current_cycle
        set current_cycle = `awk -v current="$current_cycle" -v step="$step" 'BEGIN { print(current - step) }'`

        # Modify synthesis.tcl
        sed "s/set TEST_CYCLE .*/set TEST_CYCLE $current_cycle/" synthesis.tcl > synthesis.tcl.tmp && mv synthesis.tcl.tmp synthesis.tcl

        echo "Running synthesis with TEST_CYCLE = $current_cycle..."
        dc_shell -f synthesis.tcl | tee logfile >& /dev/null

        # Check slack
        set slack_value = `grep "slack (" report/report_time_enigma_pipeline.out | awk '{print $NF}'`
        if ("$slack_value" == "") then
            echo "Warning: Could not find slack in the report. Assuming violation to be safe."
            set is_violated = 1
        else
            set is_violated = `awk -v slack="$slack_value" 'BEGIN { print(slack < 0) }'`
        endif

        if ($is_violated == 1) then
            echo "Violation found at $current_cycle."
            # Revert to the last good cycle for the next, finer search.
            set current_cycle = $last_good_cycle
            echo "Reverting to last known good cycle: $current_cycle for next step."
            break # Exit this inner loop to proceed to the next finer step
        else
            echo "No violation at $current_cycle (slack: $slack_value). Continuing..."
            # The loop will continue with an even smaller cycle time.
        endif
    end
end

# --- Finalization ---
set min_cycle = $current_cycle # After all loops, current_cycle holds the final best value.

echo "
--- Finalizing ---"
echo "Final search complete. Minimum cycle found: $min_cycle"
echo "Running final synthesis with minimum cycle time: $min_cycle"
sed "s/set TEST_CYCLE .*/set TEST_CYCLE $min_cycle/" synthesis.tcl > synthesis.tcl.tmp && mv synthesis.tcl.tmp synthesis.tcl
dc_shell -f synthesis.tcl | tee logfile >& /dev/null

echo "
--------------------------------------------------"
echo "Final Result:"
echo "Minimum non-violating TEST_CYCLE is: $min_cycle"
echo "Reports are generated for this cycle time."
echo "--------------------------------------------------"
