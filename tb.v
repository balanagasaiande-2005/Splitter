`timescale 1ps/1ps
module tb_stream_splitter;
    localparam int TOTAL_SAMPLES = 733824;
    logic clk;
    logic rst_n;
    logic [63:0]slave_data;
    logic valid_in;
    logic ready_in;
    logic [31:0]data_port1;
    logic [31:0]data_port2;
    logic valid1;
    logic valid2;
    stream_splitter dut (
        .clk(clk),
        .rst_n(rst_n),
        .slave_data(slave_data),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .data_port1(data_port1),
        .valid1(valid1),
        .data_port2(data_port2),
        .valid2(valid2)
    );
    // Clock
    initial clk = 0;
    always #1 clk = ~clk; // 500 MHz
    // Reset
    initial begin
        rst_n = 0;
        slave_data = 0;
        valid_in = 0;
        #10;
        rst_n = 1;
        @(posedge clk);
        feed_samples();
        $display("Simulation finished.");
        $stop;
    end
    task feed_samples;
        integer file, status, i;
        reg [127:0] line_str;
        reg [63:0] value;
        begin
            file = $fopen("C:/Users/Ande Bala Naga Sai/OneDrive/Desktop/IITH/input_vectors.txt", "r");
            if (file == 0) begin
                $display("ERROR: Cannot open input_vectors.txt");
                $finish;
            end
            for (i=0; i<TOTAL_SAMPLES; i=i+1) begin
                status = $fscanf(file, "%h\n", value); // read hex per line
                if (status != 1) begin
                    $display("Error reading line %0d", i);
                    $finish;
                end
                @(posedge clk);
                slave_data <= value;
                valid_in <= 1;
            end
            @(posedge clk);
            valid_in <= 0;
            $fclose(file);
        end
    endtask

    // Monitor outputs
    initial begin
        $display("Time\tvalid1\tdata1\tvalid2\tdata2");
        $monitor("%0t\t%b\t%h\t%b\t%h", $time, valid1, data_port1, valid2, data_port2);
    end

endmodule
