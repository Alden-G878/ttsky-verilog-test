/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module RangeFinder
   #(parameter WIDTH=16)
    (input  logic [WIDTH-1:0] data_in,
     input  logic             clock, reset,
     input  logic             go, finish,
     output logic [WIDTH-1:0] range,
     output logic [WIDTH-1:0] high_q, low_q,
     output logic             error);

// Put your code here
    logic reg_en, reg_zero, en_error;
    logic [WIDTH-1:0] min, max;
  	assign high_q = max;
  	assign low_q = min;
    // FSM
    enum {wait_for_go, going, err} currState, nextState;
    always_ff @(posedge clock, posedge reset) begin
        if(reset!=1'b1) currState <= nextState;
        else currState <= wait_for_go;
    end

    always_comb begin
        en_error = 1'b0;
        nextState = wait_for_go;
        reg_zero = 1'b0;
	reg_en = 1'b0;
        if(reset==1'b1) reg_zero = 1'b1;
        case(currState)
            wait_for_go: begin
                            reg_zero = 1'b1;
                            nextState = wait_for_go;
                            if(go==1'b1) begin
                                nextState = going;
                                reg_en = 1'b1;
                            end
                            if(finish==1'b1) begin
                                nextState = err;
                                reg_zero = 1'b1;
                                en_error = 1'b1;
                            end
                            if(go==1'b1 && finish==1'b1) begin
                                nextState = err;
                                reg_zero = 1'b1;
                                en_error = 1'b1;
                            end
                         end
            going:       begin
                            if(go==1'b1) begin
                                nextState = err;
                                en_error = 1'b1;
                                reg_zero = 1'b1;
                            end
                            else if(finish==1'b1) begin
                                nextState = wait_for_go;
                                reg_en = 1'b1;
                            end
                            else begin
                                nextState = going;
                                reg_en = 1'b1;
                            end
                         end
            err:       begin
                            if(go==1'b1) begin
                                nextState = going;
                                reg_en = 1'b1;
                                en_error = 1'b0;
                            end
                            else begin
                                nextState = err;
                                en_error = 1'b1;
                            end
                         end
        endcase
    end

    always_ff @(posedge clock) begin
        if(en_error == 1'b1) error <= 1'b1;
        else error <= 1'b0;
    end

    // min
    always_ff @(posedge clock) begin
        if(reg_en==1'b1 && min > data_in) min <= data_in;
        if(reg_zero==1'b1) min <= {WIDTH{1'b1}};
    end

    // max
    always_ff @(posedge clock) begin
        if(reg_en==1'b1 && max < data_in) max <= data_in;
        if(reg_zero==1'b1) max <= {WIDTH{1'b0}};
    end

    // difference
    assign range = max - min;
endmodule: RangeFinder

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_oe[0] = 1'b0;
  assign uio_oe[1] = 1'b0;
  assign uio_oe[2] = 1'b1;
  assign uio_oe[3] = 1'b0; // unused
  assign uio_oe[4] = 1'b0; // usused
  assign uio_oe[5] = 1'b0; // unused
  assign uio_oe[6] = 1'b0; // unused
  assign uio_oe[7] = 1'b0; // unused

  assign uio_out[0] = 1'b0;
  assign uio_out[1] = 1'b0;
  assign uio_out[3] = 1'b0;
  assign uio_out[4] = 1'b0;
  assign uio_out[5] = 1'b0;
  assign uio_out[6] = 1'b0;
  assign uio_out[7] = 1'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

  wire rst;
  wire [7:0] high_q, low_q;
  assign rst = ~rst_n;

  RangeFinder #(8) rf(.data_in(ui_in), .clock(clk), .reset(rst), .go(uio_in[0]), .finish(uio_in[1]), .error(uio_out[2]), .range(uo_out), .high_q(high_q), .low_q(low_q));

endmodule
