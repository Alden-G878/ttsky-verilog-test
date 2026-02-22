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
