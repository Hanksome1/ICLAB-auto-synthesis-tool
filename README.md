# Synthesis Timing Optimization Scripts

This project provides `tcsh` scripts to automatically find the **minimum viable clock cycle time** in a Synopsys Design Compiler (DC) synthesis workflow. It automates the tedious manual process of repeatedly modifying the `TEST_CYCLE` variable in `synthesis.tcl`, running synthesis, and checking timing reports. This allows you to quickly and automatically determine the performance limits of your design.

---

## How to Run Synthesis

Since synthesis can take a long time, it is recommended to run it in the background using `nohup`. This will prevent the process from being terminated if you disconnect from the server.

```bash
nohup sh run_syn.sh &
```

After running this command, the synthesis will run in the background, and all output will be redirected to a file named `nohup.out` (or `da.log` as specified in the script).

### Checking the Log

You can monitor the progress of the synthesis by checking the log file. The `run_syn.sh` script saves the log to `da.log`.

To view the log in real-time, use the `tail` command:

```bash
tail -f da.log
```

Press `Ctrl+C` to stop monitoring.

---

### Scripts & Usage


**`find_min_cycle.csh` (Fixed Step Search)**
-   Searches for the minimum cycle time using a fixed, user-defined step size.
```bash
./find_min_cycle.csh <start_cycle> <step>
```

**`find_min_cycle_auto.csh` (Auto-Refining Search - Recommended)**
-   Automatically refines the search from a large step to a smaller one for fast and precise results.
```bash
./find_min_cycle_auto.csh <a_known_passing_start_cycle>
```
