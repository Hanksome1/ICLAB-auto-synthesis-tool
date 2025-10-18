# Synthesis Timing Optimization Scripts

This project provides `tcsh` scripts to automatically find the **minimum viable clock cycle time** in a Synopsys Design Compiler (DC) synthesis workflow. It automates the tedious manual process of repeatedly modifying the `TEST_CYCLE` variable in `synthesis.tcl`, running synthesis, and checking timing reports. This allows you to quickly and automatically determine the performance limits of your design.

---

### Scripts & Usage


    *   **`find_min_cycle.csh` (Fixed Step Search)**
        -   Searches for the minimum cycle time using a fixed, user-defined step size.
        ```bash
        ./find_min_cycle.csh <start_cycle> <step>
        ```
        **Example:**
        ```bash
        ./find_min_cycle.csh 5.0 0.1
        ```

    *   **`find_min_cycle_auto.csh` (Auto-Refining Search - Recommended)**
        -   Automatically refines the search from a large step to a smaller one for fast and precise results.
        ```bash
        ./find_min_cycle_auto.csh <a_known_passing_start_cycle>
        ```
        **Example:**
        ```bash
        ./find_min_cycle_auto.csh 5.0
        ```
