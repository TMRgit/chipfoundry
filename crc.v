module crc32_top (
    input  wire         clk,           // System clock
    input  wire         reset_n,       // Asynchronous active-low reset

    // Memory-mapped interface
    input  wire [3:0]   addr,          // Register address (word offset)
    input  wire [31:0]  wdata,         // Write data
    output reg  [31:0]  rdata,         // Read data
    input  wire         write_en,      // Write enable
    input  wire         read_en,       // Read enable

    // Optional interrupt output
    output reg          int_done       // High when operation done
);

    //-----------------------------------------------------------------
    // Register address map
    //-----------------------------------------------------------------
    localparam ADDR_CTRL  = 4'h0; // Control Register
    localparam ADDR_STAT  = 4'h1; // Status Register
    localparam ADDR_DATA  = 4'h2; // Input Data Register
    localparam ADDR_CRC   = 4'h3; // CRC Output Register

    //-----------------------------------------------------------------
    // Internal signals and registers
    //-----------------------------------------------------------------
    reg [31:0] ctrl_reg;     // [0]=start, [1]=reset
    reg [31:0] status_reg;   // [0]=done, [1]=busy
    reg [31:0] data_reg;
    reg [31:0] crc_result;

    wire [31:0] crc_out_wire;
    wire crc_done_wire;

    //-----------------------------------------------------------------
    // CRC Core Instance
    //-----------------------------------------------------------------
    crc32_core u_crc_core (
        .clk        (clk),
        .reset_n    (reset_n),
        .start      (ctrl_reg[0]),
        .data_valid (write_en && addr == ADDR_DATA),
        .data_in    (wdata[7:0]),
        .crc_out    (crc_out_wire),
        .done       (crc_done_wire)
    );

    //-----------------------------------------------------------------
    // Control Logic
    //-----------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ctrl_reg   <= 32'b0;
            status_reg <= 32'b0;
            data_reg   <= 32'b0;
            crc_result <= 32'b0;
            int_done   <= 1'b0;
        end
        else begin
            // Write operations
            if (write_en) begin
                case (addr)
                    ADDR_CTRL: ctrl_reg <= wdata;
                    ADDR_DATA: data_reg <= wdata;
                    default: ;
                endcase
            end

            // Status update
            if (crc_done_wire) begin
                crc_result <= crc_out_wire;
                status_reg[0] <= 1'b1;  // done = 1
                status_reg[1] <= 1'b0;  // busy = 0
                int_done <= 1'b1;
            end else if (ctrl_reg[1]) begin
                // reset command
                status_reg <= 32'b0;
                crc_result <= 32'b0;
                int_done   <= 1'b0;
            end else if (ctrl_reg[0]) begin
                status_reg[1] <= 1'b1;  // busy
                status_reg[0] <= 1'b0;  // clear done
                int_done      <= 1'b0;
            end else begin
                int_done <= 1'b0;
            end

            // Readback
            case (addr)
                ADDR_CTRL:  rdata <= ctrl_reg;
                ADDR_STAT:  rdata <= status_reg;
                ADDR_DATA:  rdata <= data_reg;
                ADDR_CRC:   rdata <= crc_result;
                default:    rdata <= 32'h00000000;
            endcase
        end
    end

endmodule





module crc32_core (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        start,
    input  wire        data_valid,
    input  wire [7:0]  data_in,
    output reg  [31:0] crc_out,
    output reg         done
);
    localparam [31:0] POLY     = 32'hEDB88320;
    localparam [31:0] INIT     = 32'hFFFFFFFF;
    localparam [31:0] XOR_OUT  = 32'hFFFFFFFF;

    reg [31:0] crc_reg;
    reg [7:0]  d;
    integer i;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            crc_reg <= INIT;
            crc_out <= 32'h0;
            done    <= 1'b0;
        end
        else if (start) begin
            crc_reg <= INIT;
            done    <= 1'b0;
        end
        else if (data_valid) begin
            d = data_in;
            for (i = 0; i < 8; i = i + 1) begin
                if ((crc_reg[0] ^ d[0]) == 1'b1)
                    crc_reg = (crc_reg >> 1) ^ POLY;
                else
                    crc_reg = (crc_reg >> 1);
                d = d >> 1;
            end
            crc_out <= crc_reg ^ XOR_OUT;
            done    <= 1'b1;
        end
        else begin
            done <= 1'b0;
        end
    end
endmodule





// Verilog Testbench for CRC32 Accelerator System
//   No array arguments ? 100% pure Verilog-2001 compliant
//=====================================================================
`timescale 1ns/1ps


module tb_crc32_system;

    
    reg clk, reset_n;
    reg write_en, read_en;
    reg [3:0] addr;
    reg [31:0] wdata;
    wire [31:0] rdata;
    wire int_done;

    // Instantiate DUT
    crc32_top uut (
        .clk(clk),
        .reset_n(reset_n),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .write_en(write_en),
        .read_en(read_en),
        .int_done(int_done)
    );

    // ---------------------------------------------
    // Clock generation (100 MHz)
    // ---------------------------------------------
    always #5 clk = ~clk;

    
    reg [7:0] msg1 [0:8];   // "123456789"
    reg [7:0] msg2 [0:8];   // "123456788"
    reg [7:0] msg3 [0:2];   // "ABC"
    reg [7:0] msg4 [0:4];   // "HELLO"

    // Expected CRC values (IEEE 802.3)
    reg [31:0] exp1, exp2, exp3, exp4;

    initial begin
        msg1[0]="1"; msg1[1]="2"; msg1[2]="3"; msg1[3]="4";
        msg1[4]="5"; msg1[5]="6"; msg1[6]="7"; msg1[7]="8"; msg1[8]="9";

        msg2[0]="1"; msg2[1]="2"; msg2[2]="3"; msg2[3]="4";
        msg2[4]="5"; msg2[5]="6"; msg2[6]="7"; msg2[7]="8"; msg2[8]="8";

        msg3[0]="A"; msg3[1]="B"; msg3[2]="C";

        msg4[0]="H"; msg4[1]="E"; msg4[2]="L"; msg4[3]="L"; msg4[4]="O";

        //  Correct expected CRC-32 values
        exp1 = 32'hCBF43926; // "123456789"
        exp2 = 32'hBCF309B0; // "123456788"
        exp3 = 32'hA3830348; // "ABC"
        exp4 = 32'hC1446436; // "HELLO"
    end

    
    task run_crc_test;
        input integer test_id;
        input integer length;
        input [31:0] expected;
        input [127:0] label;

        integer j;
        reg [7:0] byte_val;

        begin
            $display("\n===============================");
            $display("Running %s", label);
            $display("===============================");

            // Start new CRC
            @(posedge clk);
            addr = 4'h0; wdata = 32'h1; write_en = 1;
            @(posedge clk);
            write_en = 0;

            // Feed input bytes
            for (j = 0; j < length; j = j + 1) begin
                case (test_id)
                    1: byte_val = msg1[j];
                    2: byte_val = msg2[j];
                    3: byte_val = msg3[j];
                    4: byte_val = msg4[j];
                    default: byte_val = 8'h00;
                endcase

                @(posedge clk);
                addr  = 4'h2;
                wdata = {24'h0, byte_val};
                write_en = 1;
                @(posedge clk);
                write_en = 0;
            end

            // Allow hardware to finish
            #30;

            // Read result
            addr = 4'h3; read_en = 1;
            @(posedge clk);
            read_en = 0;

            // Print result
            $display("Computed CRC32 = %h", rdata);
            if (rdata == expected)
                $display("PASS: %s CRC matched expected %h", label, expected);
            else
                $display(" FAIL: %s expected %h but got %h", label, expected, rdata);
        end
    endtask

    // ---------------------------------------------
    // Main Test Sequence
    // ---------------------------------------------
    initial begin
        // Initialize
        clk = 0;
        reset_n = 0;
        write_en = 0;
        read_en = 0;
        addr = 0;
        wdata = 0;

        // Optional waveform dump (for GTKWave or ModelSim ?view wave?)
        $dumpfile("tb_crc32_system.vcd");
        $dumpvars(0, tb_crc32_system);

        // Reset system
        #20 reset_n = 1;
        $display("Reset complete. Starting tests...");

        // Run multiple test vectors
        run_crc_test(1, 9, exp1, "Test 1 - 123456789");
        run_crc_test(2, 9, exp2, "Test 2 - 123456788");
        run_crc_test(3, 3, exp3, "Test 3 - ABC");
        run_crc_test(4, 5, exp4, "Test 4 - HELLO");

        #100;
        $display("\n==== ALL TESTS COMPLETED ====");
        $finish;
    end

endmodule



