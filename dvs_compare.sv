// ============================================================================
// Module: dvs_compare
// Description: Top-level integration comparing reactive baseline DVFS governor
//              against the ML-assisted predictive DVFS governor (DVS Trooper).
// Course: SD0212 RTL DESIGN AND VERIFICATION
// ============================================================================
module dvs_compare (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        busy,
  input  logic        hot,
  input  logic        droop,
  input  logic [11:0] voltage_mv,
  output logic        warn,
  output logic        baseline_fast,
  output logic        predictive_fast
);

  // Instantiate Machine Learning Voltage Droop Predictor
  droop_predictor u_pred (
    .clk        (clk),
    .rst_n      (rst_n),
    .busy       (busy),
    .voltage_mv (voltage_mv),
    .warn       (warn)
  );

  // Instantiate Baseline Governor (Early warning tied to 0 -> purely reactive)
  dvs_governor u_baseline (
    .clk        (clk),
    .rst_n      (rst_n),
    .busy       (busy),
    .hot        (hot),
    .droop      (droop),
    .early_warn (1'b0),
    .fast_req   (baseline_fast)
  );

  // Instantiate Predictive Governor (Early warning driven by ML predictor)
  dvs_governor u_predictive (
    .clk        (clk),
    .rst_n      (rst_n),
    .busy       (busy),
    .hot        (hot),
    .droop      (droop),
    .early_warn (warn),
    .fast_req   (predictive_fast)
  );

endmodule
