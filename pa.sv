//====================================================================
//        Copyright (c) 2018 Nordic Semiconductor ASA, Norway
//====================================================================
// Created       : Karianne Krokan Kragseth at 2018-04-25
// Modified      : $Author$ $Date$
// Version       : $Revision$ $HeadURL$
//====================================================================

package pa_EventGeneratorUnit;


  // -- Common
  localparam                      INCLUDE_EVENT_GENERATOR_UNIT                                    = 1;
  localparam                      SELECT_TASK_REGISTERS                                           = 1;
  localparam                      INCLUDE_PAR_EVENTS_AND_IRQ                                      = 1;
  localparam                      SELECT_EVENT_TRIGGERS                                           = 1;
  localparam                      SELECT_NMI                                                      = 1;
  // -- PAR
  localparam                      PAR_AW                                                          = 12;
  localparam                      PAR_DW                                                          = 32;
  localparam                      PAR_WW                                                          = 4;
  localparam                      NUM_TASKS                                                       = 8;
  localparam                      NUM_EVENTS                                                      = 8;
  localparam                      NUM_CLOCK_POWER_PAIR                                            = 2;
  // -- Events base
  localparam                      ID_EVENT_GENERATOR_UNIT_EVENT_BASE                              = 'h 100;
  localparam                      ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE                              = 'h 300;
  localparam                      ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE                          = 'h 304;
  localparam                      ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE                        = 'h 308;

 localparam                       ID_EVENT_GENERATOR_UNIT_NMI_ENABLE                = 'h 320;
 localparam                       ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE            = 'h 324;
 localparam                       ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE          = 'h 328;

  // -- Tasks base and addresses
  localparam                      ID_EVENT_GENERATOR_UNIT_TASK_BASE                               = 'h 000;
  localparam                      [NUM_TASKS-1:0][PAR_AW-1:0] ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES   = fu_addArrayt(ID_EVENT_GENERATOR_UNIT_TASK_BASE );
  localparam                      [NUM_EVENTS-1:0][PAR_AW-1:0] ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES   = fu_addArraye(ID_EVENT_GENERATOR_UNIT_EVENT_BASE );
  // -- Reset Values
  localparam                      RV_IRQ_ENABLE                                                   = '0;
  localparam                      RV_TASKS                                                        = '0;
  localparam                      RV_EVENTS                                                       = '0;
  // -- PPI
  localparam                      NUM_PPI_CHANNELS                                                = 32;
  localparam                      NUM_FIXED_CHANNELS                                              = 32;
  localparam                      INCLUDE_PPIBUS                                                  = 1;
  localparam                      BYPASS_PPIBUS                                                   = 0;
  localparam                      ID_PPIBUS_CONSUMER_BASE                                         =  32'h080;
  localparam                      ID_PPIBUS_PRODUCER_BASE                                         =  32'h180;
  localparam                      CONSUMER_MASK                                                   = fu_genMask(NUM_PPI_CHANNELS);
  localparam                      PRODUCER_MASK                                                   = fu_genMask(NUM_PPI_CHANNELS);







  function automatic [NUM_PPI_CHANNELS-1:0] fu_genMask(input int numChannels);
    logic [NUM_PPI_CHANNELS-1:0] channelMask;
    for(int i = 0; i < NUM_PPI_CHANNELS; i++) begin: loop1
        channelMask[i]='b1;
      end: loop1
    return channelMask;
  endfunction

  function automatic [NUM_TASKS-1 : 0][PAR_AW-1:0] fu_addArrayt(input logic [PAR_AW-1:0] offset);
    logic [NUM_TASKS-1 : 0][PAR_AW-1:0] idConfig;

    for(int i = 0; i < NUM_TASKS; i++) begin: loop1
          idConfig[i] = offset + i*4;
        end: loop1
    return idConfig;
  endfunction

    function automatic [NUM_EVENTS-1 : 0][PAR_AW-1:0] fu_addArraye(input logic [PAR_AW-1:0] offset);
    logic [NUM_EVENTS-1 : 0][PAR_AW-1:0] idConfig;

    for(int i = 0; i < NUM_TASKS; i++) begin: loop1
          idConfig[i] = offset + i*4;
        end: loop1
    return idConfig;
  endfunction

endpackage