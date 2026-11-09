// ============================================================================
// Testbench: tb_dvs
// Description: Self-checking testbench for dvs_compare on EDA Playground.
//              Generates clock/reset, stimulates synthetic voltage traces,
//              asserts correct governor responses, and dumps VCD for EPWave.
// Course: SD0212 RTL DESIGN AND VERIFICATION
// ============================================================================
`timescale 1ns/1ps

module tb_dvs;

  logic        clk = 0;
  logic        rst_n;
  logic        busy;
  logic        hot;
  logic        droop;
  logic [11:0] voltage_mv;
  logic        warn;
  logic        baseline_fast;
  logic        predictive_fast;

  int error_count = 0;
  int check_count = 0;

  // Instantiate Unit Under Test (UUT)
  dvs_compare uut (
    .clk             (clk),
    .rst_n           (rst_n),
    .busy            (busy),
    .hot             (hot),
    .droop           (droop),
    .voltage_mv      (voltage_mv),
    .warn            (warn),
    .baseline_fast   (baseline_fast),
    .predictive_fast (predictive_fast)
  );

  // Clock generation: 100 MHz (period = 10 ns)
  always #5 clk = ~clk;

  // Verification helper task: drives inputs on negedge, checks on posedge + 1ns
  task automatic step_check(
    input logic        in_busy,
    input logic        in_hot,
    input logic        in_droop,
    input logic [11:0] in_v_mv,
    input logic        exp_warn,
    input logic        exp_base,
    input logic        exp_pred
  );
    @(negedge clk);
    busy       = in_busy;
    hot        = in_hot;
    droop      = in_droop;
    voltage_mv = in_v_mv;

    @(posedge clk);
    #1; // Settling time for registered outputs
    check_count++;

    if (warn !== exp_warn || baseline_fast !== exp_base || predictive_fast !== exp_pred) begin
      $display("[ERROR] Time %0t ns (Check %0d): Exp(warn=%b, base=%b, pred=%b) != Act(warn=%b, base=%b, pred=%b)",
               $time, check_count, exp_warn, exp_base, exp_pred, warn, baseline_fast, predictive_fast);
      error_count++;
    end else begin
      $display("[PASS] Time %0t ns (Check %0d): v_mv=%0d mV, warn=%b, base_fast=%b, pred_fast=%b",
               $time, check_count, voltage_mv, warn, baseline_fast, predictive_fast);
    end
  endtask

  initial begin
    // Setup waveform dump for EDA Playground EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_dvs);

    // Initial signals
    clk        = 0;
    rst_n      = 0;
    busy       = 0;
    hot        = 0;
    droop      = 0;
    voltage_mv = 12'd1000;

    $display("===============================================================");
    $display("STARTING SIMULATION: DVS TROOPER ML-ASSISTED DVFS GOVERNOR");
    $display("Course: SD0212 RTL DESIGN AND VERIFICATION");
    $display("===============================================================");

    // Apply Reset
    #15;
    @(negedge clk);
    rst_n = 1;
    #2;

    // ------------------------------------------------------------------------
    // Scenario 1: Initial Healthy Workload (Checks 1–3)
    // ------------------------------------------------------------------------
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b1, 1'b1);
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b1, 1'b1);
    step_check(1'b1, 1'b0, 1'b0, 12'd980,  1'b0, 1'b1, 1'b1);

    // ------------------------------------------------------------------------
    // Scenario 2: Predictive Droop Detection (Checks 4–8)
    // 980 -> 930 mV (drop = 50 mV >= 40 mV threshold, busy_count >= 3)
    // Predictive governor requests SLOW (0) 1 cycle before baseline!
    // ------------------------------------------------------------------------
    step_check(1'b1, 1'b0, 1'b0, 12'd930, 1'b1, 1'b1, 1'b0); // Warn raised, pred throttles
    step_check(1'b1, 1'b0, 1'b1, 12'd880, 1'b1, 1'b0, 1'b0); // Droop alarm asserts; baseline throttles
    step_check(1'b1, 1'b0, 1'b1, 12'd850, 1'b1, 1'b0, 1'b0);
    step_check(1'b1, 1'b0, 1'b0, 12'd900, 1'b0, 1'b0, 1'b0); // Recovery cycle 1
    step_check(1'b1, 1'b0, 1'b0, 12'd950, 1'b0, 1'b0, 1'b0); // Recovery cycle 2

    // ------------------------------------------------------------------------
    // Scenario 3: Complete Recovery back to FAST (Check 9)
    // ------------------------------------------------------------------------
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b1, 1'b1); // Recovery complete, FAST restored

    // ------------------------------------------------------------------------
    // Scenario 4: Sub-threshold Dip Rejection (35 mV < 40 mV) (Checks 10–12)
    // 1000 -> 965 mV (drop = 35 mV). Learned rule correctly rejects false warning!
    // ------------------------------------------------------------------------
    step_check(1'b1, 1'b0, 1'b0, 12'd965,  1'b0, 1'b1, 1'b1);
    step_check(1'b1, 1'b0, 1'b0, 12'd970,  1'b0, 1'b1, 1'b1);
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b1, 1'b1);

    // ------------------------------------------------------------------------
    // Scenario 5: Thermal Hot Alarm Override (Checks 13–16)
    // ------------------------------------------------------------------------
    step_check(1'b1, 1'b1, 1'b0, 12'd1000, 1'b0, 1'b0, 1'b0); // Thermal trip
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b0, 1'b0); // Recovery 1
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b0, 1'b0); // Recovery 2
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b1, 1'b1); // Recovered

    // ------------------------------------------------------------------------
    // Scenario 6: Idle Transitions (Checks 17–18)
    // ------------------------------------------------------------------------
    step_check(1'b0, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b0, 1'b0); // Idle -> SLOW
    step_check(1'b1, 1'b0, 1'b0, 12'd1000, 1'b0, 1'b1, 1'b1); // Busy -> FAST

    $display("===============================================================");
    if (error_count == 0) begin
      $display("SUCCESS: ALL %0d CHECKS PASSED PERFECTLY!", check_count);
      $display("DVS Trooper predictive governor correctly beat baseline by 1 cycle!");
    end else begin
      $display("FAILURE: %0d / %0d CHECKS FAILED!", error_count, check_count);
    end
    $display("===============================================================");

    #20;
    $finish;
  end

endmodule
