module vgs_controller (
    input wire clk,
    input wire rst_n,              
    input wire InVGS,
    output reg OutVGS,
    output reg FlybackVGS
);

reg rising_edge_detected;         // Flag to track InVGS rising edge
reg falling_edge_detected;        // Flag to track falling edge for sequencing

// Handle positive edge of clock
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        FlybackVGS <= 1;          // Default state is high
        rising_edge_detected <= 0;
        falling_edge_detected <= 0;
    end else begin
        if (InVGS) begin
            if (!rising_edge_detected) begin
                // InVGS just went high
                FlybackVGS <= 0;
                rising_edge_detected <= 1;
                falling_edge_detected <= 0;
            end
        end else begin  // InVGS is low
            rising_edge_detected <= 0;
            if (OutVGS) begin
                // OutVGS is high, do normal turn-off sequence
                FlybackVGS <= 1;  // FlybackVGS goes high first
                falling_edge_detected <= 1;  // Signal for OutVGS to go low on next negedge
            end else if (!FlybackVGS && !falling_edge_detected) begin
                // Short pulse case: OutVGS never went high
                FlybackVGS <= 1;  // Return FlybackVGS to high
                falling_edge_detected <= 0;
            end
        end
    end
end

// Handle negative edge of clock
always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        OutVGS <= 0;
    end else begin
        if (InVGS && rising_edge_detected) begin
            OutVGS <= 1;  // OutVGS goes high half clock after InVGS
        end else if (falling_edge_detected) begin
            OutVGS <= 0;  // OutVGS goes low half a clock after FlybackVGS went high
        end
    end
end

endmodule
