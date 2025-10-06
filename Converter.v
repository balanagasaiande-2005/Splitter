`timescale 1ps / 1ps
module stream_splitter #(
    parameter DATA_WIDTH = 64,
    parameter ACTIVE_SAMPLES = 3276,
    parameter IDLE_SAMPLES = 1172,
    parameter ADDR_WIDTH = 12   
)(
    input wire clk,
    input wire rst_n,
    // Input stream
    input wire [DATA_WIDTH-1:0]slave_data,
    input wire valid_in,
    output wire ready_in,
    // Output streams
    output reg [31:0]data_port1,
    output reg valid1,
    output reg [31:0]data_port2,
    output reg valid2
);
    // FSM states
    typedef enum reg [1:0]{S_ACTIVE=0, S_IDLE=1, S_DRAIN=2}state_t;
    state_t state;
    reg [15:0]sample_count;
    // BRAM signals
    reg [ADDR_WIDTH-1:0] wr_addr, rd_addr;
    reg [DATA_WIDTH-1:0] bram [0:(1<<ADDR_WIDTH)-1];
    assign ready_in = 1'b1;  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count <= 0;
            state <= S_ACTIVE;
            wr_addr <= 0;
            rd_addr <= 0;
            data_port1 <= 0;
            data_port2 <= 0;
            valid1 <= 0;
            valid2 <= 0;
        end else if (valid_in) begin
            case(state)
                S_ACTIVE: begin
                    // direct pass-through
                    data_port1 <= slave_data[63:32];
                    data_port2 <= slave_data[31:0];
                    valid1 <= 1;
                    valid2 <= 1;
                    if (sample_count == ACTIVE_SAMPLES-1) begin
                        sample_count <= 0;
                        state <= S_IDLE;
                        wr_addr <= 0; // reset write pointer
                    end else begin
                        sample_count <= sample_count + 1;
                    end
                end
                S_IDLE: begin
                    // output zero, but still write incoming into BRAM
                    data_port1 <= 0;
                    data_port2 <= 0;
                    valid1 <= 1;
                    valid2 <= 1;
                    bram[wr_addr] <= slave_data;
                    wr_addr <= wr_addr + 1;
                    if (sample_count == IDLE_SAMPLES-1) begin
                        sample_count <= 0;
                        state <= S_DRAIN;
                        rd_addr <= 0; 
                    end else begin
                        sample_count <= sample_count + 1;
                    end
                end
                S_DRAIN: begin
                    // read stored BRAM and output it
                    data_port1 <= bram[rd_addr][63:32];
                    data_port2 <= bram[rd_addr][31:0];
                    valid1 <= 1;
                    valid2 <= 1;
                    rd_addr <= rd_addr + 1;
                    if (sample_count == IDLE_SAMPLES-1) begin
                        sample_count <= 0;
                        state <= S_ACTIVE;
                    end else begin
                        sample_count <= sample_count + 1;
                    end
                end
            endcase
        end
    end
endmodule
