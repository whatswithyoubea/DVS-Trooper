// ============================================================================
// Module: droop_predictor
// Description: ML-assisted voltage droop predictor using learned thresholds.
//              Computes cycle-to-cycle voltage delta and monitors workload
//              duration to predict droop events before hardware alarms trip.
// Course: SD0212 RTL DESIGN AND VERIFICATION
// ============================================================================
module droop_predictor #(
  parameter int DROP_THRESHOLD = 40,   // Trained voltage drop threshold (mV)
  parameter int BUSY_THRESHOLD = 3     // Trained sustained busy count threshold
)(
  input  logic        clk,
  input  logic        rst_n,
  input  logic        busy,
  input  logic [11:0] voltage_mv,
  output logic        warn
);

  logic [11:0] previous_voltage;
  logic        history_valid;
  logic [7:0]  busy_count;
  logic [7:0]  next_busy_count;
  logic [11:0] voltage_drop;

  // Combinational next busy count with 8-bit saturation (max 255)
  always_comb begin
    if (!busy) begin
      next_busy_count = 8'd0;
    end else if (busy_count < 8'd255) begin
      next_busy_count = busy_count + 8'd1;
    end else begin
      next_busy_count = 8'd255;
    end
  end

  // Combinational voltage drop calculation (non-negative drop)
  always_comb begin
    if (history_valid && (previous_voltage > voltage_mv)) begin
      voltage_drop = previous_voltage - voltage_mv;
    end else begin
      voltage_drop = 12'd0;
    end
  end

  // Sequential state and registered warning prediction
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      previous_voltage <= 12'd0;
      history_valid    <= 1'b0;
      busy_count       <= 8'd0;
      warn             <= 1'b0;
    end else begin
      previous_voltage <= voltage_mv;
      history_valid    <= 1'b1;
      busy_count       <= next_busy_count;

      // Predict warning based on trained decision rule:
      // History must be valid, drop must exceed threshold, and busy samples >= threshold
      warn <= history_valid &&
              (voltage_drop >= DROP_THRESHOLD[11:0]) &&
              (next_busy_count >= BUSY_THRESHOLD[7:0]);
    end
  end

endmodule
