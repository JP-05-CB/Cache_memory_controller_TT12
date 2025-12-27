`timescale 1ns / 1ps
module cache_controller(

    clk,
    rst_n,
    // CPU Interface
    cpu_req_address,
    cpu_req_datain,                                                //CPU to cache
    cpu_req_dataout,                                               //cache t CPU 
    cpu_req_rw,                                                    //Read= 0 :Write = 1 ; 
    cpu_req_valid,                                                 //1(high) when the valid date is present 
    cache_ready,                                                   //1 - finished previous and ready for new : 0 - cache is busy 
    
    // Main Memory Interface(occurs only during the cache miss )
    
    mem_req_address,
    mem_req_datain,                                                // RAM to cache
    mem_req_dataout,                                               // cache to RAM  
    mem_req_rw,
    mem_req_valid,
    mem_req_ready
);
//Finite state machines 
parameter IDLE        = 2'b00;                                    //Wait untill cpu_req_valid become high , then moves to compare tag  
parameter COMPARE_TAG = 2'b01;                                    //decision maker - checks the req address tag and check with tag stored in the cache 
parameter ALLOCATE    = 2'b10;                                    //fetch state - waits for mem_req_ready , then writes it to the cache from the memory 
parameter WRITE_BACK  = 2'b11;                                    //old data will get stored in the main memory and makes room for the data asked by  the cache

input clk;
input rst_n;

// CPU request to cache controller
input [31:0] cpu_req_address;
input [127:0] cpu_req_datain;
output [31:0] cpu_req_dataout;
input cpu_req_rw;                                                 // 1=write, 0=read
input cpu_req_valid;

// Main memory request from cache controller
output [31:0] mem_req_address;
input [127:0] mem_req_datain;
output [127:0] mem_req_dataout;
output mem_req_rw;
output mem_req_valid;
input mem_req_ready;

// Cache ready
output cache_ready;

// Cache consists of tag memory and data memory
reg [19:0] tag_mem [0:1023];
reg [127:0] data_mem [0:1023];

reg [1:0] present_state, next_state;                                //Finite state machines 
reg [31:0] cpu_req_dataout, next_cpu_req_dataout;                   //cache controller takes several clocks to complete the task , during those , it has to remember the previous data , so it stores here 
reg [31:0] cache_read_data;
reg cache_ready, next_cache_ready;

reg [31:0] mem_req_address, next_mem_req_address;                    //the previous address stores here
reg mem_req_rw, next_mem_req_rw;
reg mem_req_valid, next_mem_req_valid;
reg [127:0] mem_req_dataout, next_mem_req_dataout;
reg write_datamem_mem;                                                //if high , save the data from RAM to cache 
reg write_datamem_cpu;                                                //if high , save the data from CPU to cache 
reg tagmem_enable;                                                    //0 - Read only - only check for hit/miss by seeing tags : 1 - Write - on next clock , it overwrites the current index to next 
reg valid_bit, dirty_bit;                                             //"Dirty"- means unsaved changes - the data in cache written by CPU is different from RAM : 0 - clean(all are same) : 1- dirty 

reg [31:0] cpu_req_address_reg, next_cpu_req_address_reg;
reg [127:0] cpu_req_datain_reg, next_cpu_req_datain_reg;
reg cpu_req_rw_reg, next_cpu_req_rw_reg;

wire [17:0] cpu_addr_tag;
wire [9:0] cpu_addr_index;
wire [1:0] cpu_addr_blk_offset;
wire hit;

// CPU Address breakdown
assign cpu_addr_tag         = cpu_req_address_reg[31:14];
assign cpu_addr_index       = cpu_req_address_reg[13:4];
assign cpu_addr_blk_offset  = cpu_req_address_reg[3:2];

// Cache lookup
wire [19:0] tag_mem_entry  = tag_mem[cpu_addr_index];                        //its index has 10 bits which helps us to select a row within 1024 rows 
wire [127:0] data_mem_entry = data_mem[cpu_addr_index];
assign hit = tag_mem_entry[19] && (cpu_addr_tag == tag_mem_entry[17:0]);    //compares the Tag requested by the CPU  with the Tag stored in the cache slot
//ignores 18th bit(dirty bit) as it is not considered for the hit . 

// Initialize all cache memories to zero
integer init_i;
initial begin
    for (init_i = 0; init_i < 1024; init_i = init_i + 1) begin
        tag_mem[init_i] = 20'b0;
        data_mem[init_i] = 128'b0;
    end
    
    // VCD dumping for GTKwave
    `ifdef COCOTB_SIM
    $dumpfile("waveforms.vcd");
    $dumpvars(0, cache_controller);                                        //0: Dump everything (current module + all sub-modules).
                                                                           //1: Dump only the signals in this specific module (ignore sub-modules).
    $display("VCD dumping enabled for GTKwave");
    `endif
end

// Sequential logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        present_state    <= IDLE;
        cpu_req_dataout  <= 32'd0;
        cache_ready      <= 1'b0;
        mem_req_address  <= 32'd0;
        mem_req_rw       <= 1'b0;
        mem_req_valid    <= 1'b0;
        mem_req_dataout  <= 128'd0;
        cpu_req_address_reg <= 32'd0;
        cpu_req_datain_reg <= 128'd0;
        cpu_req_rw_reg   <= 1'b0;
    end else begin
        // Update memories
        if (tagmem_enable) begin
            tag_mem[cpu_addr_index] <= {4'b0, valid_bit, dirty_bit, cpu_addr_tag};
        end
        //datas are stored in the Cache from either CPU or RAM 
        if (write_datamem_mem) begin
            data_mem[cpu_addr_index] <= mem_req_datain;
        end else if (write_datamem_cpu) begin
            data_mem[cpu_addr_index] <= cpu_req_datain_reg;
        end
        
        // Update registers
        present_state    <= next_state;
        cpu_req_dataout  <= next_cpu_req_dataout;
        cache_ready      <= next_cache_ready;
        mem_req_address  <= next_mem_req_address; 
        mem_req_rw       <= next_mem_req_rw;
        mem_req_valid    <= next_mem_req_valid;
        mem_req_dataout  <= next_mem_req_dataout;
        cpu_req_address_reg <= next_cpu_req_address_reg;
        cpu_req_datain_reg <= next_cpu_req_datain_reg;
        cpu_req_rw_reg   <= next_cpu_req_rw_reg;
    end
end

// Combinational logic
always @(*) begin
    // Default values
    write_datamem_mem    = 1'b0;
    write_datamem_cpu    = 1'b0;
    valid_bit            = 1'b0;
    dirty_bit            = 1'b0;
    tagmem_enable        = 1'b0;
    next_state           = present_state;
    next_cpu_req_dataout = cpu_req_dataout;
    next_cache_ready     = 1'b1;
    next_mem_req_address = mem_req_address; 
    next_mem_req_rw      = mem_req_rw;
    next_mem_req_valid   = mem_req_valid;
    next_mem_req_dataout = mem_req_dataout;
    next_cpu_req_address_reg  = cpu_req_address_reg;
    next_cpu_req_datain_reg  = cpu_req_datain_reg;
    next_cpu_req_rw_reg  = cpu_req_rw_reg;

    // Data selection mux
    case (cpu_addr_blk_offset)
        2'b00: cache_read_data = data_mem_entry[31:0];
        2'b01: cache_read_data = data_mem_entry[63:32];
        2'b10: cache_read_data = data_mem_entry[95:64];
        2'b11: cache_read_data = data_mem_entry[127:96];
        default: cache_read_data = 32'd0;
    endcase

    // State machine
    case (present_state)
        IDLE: begin                                                 //since the state is IDLE , so the next values are same as present values 
            if (cpu_req_valid) begin
                next_cpu_req_address_reg = cpu_req_address;
                next_cpu_req_datain_reg = cpu_req_datain;
                next_cpu_req_rw_reg = cpu_req_rw;
                next_cache_ready = 1'b0;
                next_state = COMPARE_TAG;
            end
        end

        COMPARE_TAG: begin
            if (hit) begin
                if (!cpu_req_rw_reg) begin // Read hit
                    next_cpu_req_dataout = cache_read_data;
                    next_state = IDLE;
                end else begin // Write hit
                    write_datamem_cpu = 1'b1;
                    valid_bit = 1'b1;
                    dirty_bit = 1'b1;
                    tagmem_enable = 1'b1;                                                          //by enabling this , the dirty and valid bit get saved in the RAM
                    next_state = IDLE;//to accept the next value 
                end
            end else begin // Miss
                next_cache_ready = 1'b0;                                                           //As cache is busy 
                if (tag_mem_entry[18]) begin // Dirty
                    
                    next_mem_req_address = {tag_mem_entry[17:0], cpu_addr_index, 4'b0000};         //As there is a change in the orginal data , it has to be updated 
                                                                                                   //to the RAM ,so we are finding the address of the old data to update  
                    next_mem_req_dataout = data_mem_entry;
                    next_mem_req_rw = 1'b1;
                    next_mem_req_valid = 1'b1;
                    next_state = WRITE_BACK;                                                       //editing the old data with new modified data 
                end else begin // Clean
                    if (!cpu_req_rw_reg) begin // Read
                         
                        next_mem_req_address = {cpu_req_address_reg[31:4], 4'b0000};
                        next_mem_req_rw = 1'b0;
                        next_mem_req_valid = 1'b1;
                        next_state = ALLOCATE;
                    end else begin // Write
                        write_datamem_cpu = 1'b1;
                        valid_bit = 1'b1;
                        dirty_bit = 1'b1;
                        tagmem_enable = 1'b1;
                        next_state = IDLE;
                    end
                end
            end
        end

        ALLOCATE: begin
            next_mem_req_valid = 1'b0;
            next_cache_ready = 1'b0;
            if (mem_req_ready) begin
                write_datamem_mem = 1'b1;
                valid_bit = 1'b1;
                dirty_bit = 1'b0;
                tagmem_enable = 1'b1;
                next_state = COMPARE_TAG;
            end
        end

        WRITE_BACK: begin
            next_cache_ready = 1'b0;
            next_mem_req_valid = 1'b0;
            if (mem_req_ready) begin
                if (!cpu_req_rw_reg) begin
                    // FIX: Target register changed to mem_req_address
                    next_mem_req_address = {cpu_req_address_reg[31:4], 4'b0000};
                    next_mem_req_rw = 1'b0;
                    next_mem_req_valid = 1'b1;
                    next_state = ALLOCATE;
                end else begin
                    write_datamem_cpu = 1'b1;
                    valid_bit = 1'b1;
                    dirty_bit = 1'b1;
                    tagmem_enable = 1'b1;
                    next_state = IDLE;
                end
            end
        end

        default: next_state = IDLE;
    endcase
end

endmodule
