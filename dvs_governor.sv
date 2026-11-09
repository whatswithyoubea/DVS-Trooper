// ============================================================================
// Module: dvs_governor
// Description: Dynamic Voltage and Frequency Scaling (DVFS) CPU Governor.
//              Requests FAST (1) during active workload and drops to SLOW (0)
//              upon fault detection or early warning, followed by a 3-cycle
//              healthy recovery sequence.
// Course: SD0212 RTL DESIGN AND VERIFICATION
// ============================================================================
module dvs_governor (
  input  logic clk,
  input  logic rst_n,
  input  logic busy,
  input  logic hot,
  input  logic droop,
  input  logic early_warn,
  output logic fast_req
);

  logic [1:0] healthy_count;
  logic       recovering;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fast_req      <= 1'b0;
      recovering    <= 1'b0;
      healthy_count <= 2'd0;
    end else begin
      // Step 1: Immediate fault or predictive early warning override
      if (hot || droop || early_warn) begin
        fast_req      <= 1'b0;
        recovering    <= 1'b1;
        healthy_count <= 2'd0;
      end
      // Step 2: Recovery phase (requires 3 consecutive healthy cycles)
      else if (recovering) begin
        if (healthy_count == 2'd2) begin
          recovering    <= 1'b0;
          healthy_count <= 2'd0;
          fast_req      <= busy; // Restore speed to match current demand
        end else begin
          healthy_count <= healthy_count + 2'd1;
          fast_req      <= 1'b0; // Maintain throttled SLOW during recovery
        end
      end
      // Step 3: Normal steady-state operation
      else begin
        fast_req <= busy;
      end
    end
  end

endmodule
