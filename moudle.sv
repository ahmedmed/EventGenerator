 //====================================================================
//        Copyright (c) 2014 Nordic Semiconductor ASA, Norway
//====================================================================
// Created       : Vegard Endresen at 2014-06-02
// Modified      : $Kristian Jerndahl$ $2018-10-08$
// Version       : $Revision$ $HeadURL$
//====================================================================


module EventGeneratorUnit #(
parameter                             INCLUDE_EVENT_GENERATOR_UNIT               = pa_EventGeneratorUnit::INCLUDE_EVENT_GENERATOR_UNIT              ,
parameter                             INCLUDE_PAR_EVENTS_AND_IRQ                 = pa_EventGeneratorUnit::INCLUDE_PAR_EVENTS_AND_IRQ                ,
parameter                             SELECT_EVENT_TRIGGERS                      = pa_EventGeneratorUnit::SELECT_EVENT_TRIGGERS                     ,
parameter                             SELECT_TASK_REGISTERS                      = pa_EventGeneratorUnit::SELECT_TASK_REGISTERS                     ,
parameter                             SELECT_NMI                                 = pa_EventGeneratorUnit::SELECT_NMI                                ,
parameter                             PAR_AW                                     = pa_EventGeneratorUnit::PAR_AW                                    ,
parameter                             PAR_DW                                     = pa_EventGeneratorUnit::PAR_DW                                    ,
parameter                             PAR_WW                                     = pa_EventGeneratorUnit::PAR_WW                                    ,
parameter                             NUM_TASKS                                  = pa_EventGeneratorUnit::NUM_TASKS                                 ,
parameter                             NUM_EVENTS                                 = pa_EventGeneratorUnit::NUM_EVENTS                                ,
parameter                             NUM_CLOCK_POWER_PAIR                       = pa_EventGeneratorUnit::NUM_CLOCK_POWER_PAIR                      ,
parameter                             ID_EVENT_GENERATOR_UNIT_EVENT_BASE         = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_EVENT_BASE        ,
parameter                             ID_EVENT_GENERATOR_UNIT_TASK_BASE          = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_TASK_BASE         ,
parameter [NUM_EVENTS-1:0][PAR_AW-1:0]ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES    = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES   ,
parameter [NUM_TASKS-1:0][PAR_AW-1:0] ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES     = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES    ,
parameter                             ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE         = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE        ,
parameter                             ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE     = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE    ,
parameter                             ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE   = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE  ,
parameter                             ID_EVENT_GENERATOR_UNIT_NMI_ENABLE         = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_NMI_ENABLE        ,
parameter                             ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE     = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE    ,
parameter                             ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE   = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE  ,
parameter                             RV_IRQ_ENABLE                              = pa_EventGeneratorUnit::RV_IRQ_ENABLE                             ,
parameter                             RV_TASKS                                   = pa_EventGeneratorUnit::RV_TASKS                                  ,
parameter                             RV_EVENTS                                  = pa_EventGeneratorUnit::RV_EVENTS                                 ,
parameter                             NUM_PPI_CHANNELS                           = pa_EventGeneratorUnit::NUM_PPI_CHANNELS                          ,
parameter                             NUM_FIXED_CHANNELS                         = pa_EventGeneratorUnit::NUM_FIXED_CHANNELS                        ,
parameter                             INCLUDE_PPIBUS                             = pa_EventGeneratorUnit::INCLUDE_PPIBUS                            ,
parameter                             BYPASS_PPIBUS                              = pa_EventGeneratorUnit::BYPASS_PPIBUS                             ,
parameter                             ID_PPIBUS_CONSUMER_BASE                    = pa_EventGeneratorUnit::ID_PPIBUS_CONSUMER_BASE                   ,
parameter                             ID_PPIBUS_PRODUCER_BASE                    = pa_EventGeneratorUnit::ID_PPIBUS_PRODUCER_BASE                   ,
parameter                             CONSUMER_MASK                              = pa_EventGeneratorUnit::CONSUMER_MASK                             ,
parameter                             PRODUCER_MASK                              = pa_EventGeneratorUnit::PRODUCER_MASK
  )
  (// -- PAR interface outputs:
   output logic  [PAR_DW-1:0]               parDi                  ,    // -- PAR Bus return data.
   output logic                             parDiSelect            ,    // -- PAR Bus return data select.
   // -- PAR interface inputs:
   input  logic  [PAR_AW-1:0]               parAddr                ,    // -- PAR Bus address.
   input  logic  [PAR_DW-1:0]               parDo                  ,    // -- PAR Bus data from MCU.
   input  logic                             parRe                  ,    // -- PAR Bus read enable.
   input  logic  [PAR_WW-1:0]               parWe                  ,    // -- PAR Bus write enable.

   // -- Outputs:
   output logic                             irqEventGeneratorUnit  ,    // -- IRQ.
   output logic                             nmiEventGeneratorUnit  ,
   // -- Inputs:
   // -- PPI interface
   input   logic [NUM_PPI_CHANNELS-1:0]     ppiBusConsumer         ,    // -- Channels with peripheral tasks
   output  logic [NUM_PPI_CHANNELS-1:0]     ppiBusProducer         ,    // -- Channels with peripheral events
   output  logic [NUM_PPI_CHANNELS-1:0]     ppiBusActive           ,    // -- Consumer status
   // -- PCGC SVI:
   in_PcgcBus.mo_slave                      pcgcBusSlave           ,
   input  logic [NUM_CLOCK_POWER_PAIR-1:0]  taskZeroPenalty        ,
   input  logic [NUM_CLOCK_POWER_PAIR-1:0]  taskFullPenalty
  );
    // ---------------------------------------------
    // -- Internal declarations:
    // ---------------------------------------------
    logic [NUM_TASKS-1:0]             events;    // -- Event: events.
    logic [NUM_TASKS-1:0]             tasks ;    // -- Task: tasks.
    logic                             reqRequest;   // -- to ReqCtrl, trigger on potential input
    // --------------------------------
    // -- PAR
    // --------------------------------
    logic [PAR_DW-1:0]                parDiEguPar;          // -- wire connections for submodules
    logic                             parDiSelectEguPar;    // -- wire connections for submodules
    logic [PAR_DW-1:0]                parDiPcgc;            // -- wire connections for submodules
    logic                             parDiSelectPcgc;      // -- wire connections for submodules
    logic [PAR_DW-1:0]                parDiPpi;             // -- wire connections for submodules
    logic                             parDiSelectPpi;       // -- wire connections for submodules

  // --------------------------------
    // -- PCGC
    // --------------------------------

    // local clocks and resets
    logic ckPar;       // clock for PCP 0
    logic ck1;        // clock for PCP 1
    logic arstPar;     // arst for PCP 0, release synchronous to ck0
    logic arst1;      // arst for PCP 1, release synchronous to ck1


    // local request signals
    logic [NUM_CLOCK_POWER_PAIR-1:0] reqResources_a;      // one bit per PCP
    logic [NUM_CLOCK_POWER_PAIR-1:0] reqResources;        // one bit per PCP
    // Pcgc peripheral interface that contains the resources and request signals for/from your IP
    in_PcgcIntPeripheral #(.NUM_CLOCK_POWER_PAIR (NUM_CLOCK_POWER_PAIR),.PCGC_VERSION (2)) uin_PcgcIntPeripheral ();
    assign uin_PcgcIntPeripheral.reqResources_a  = reqResources_a;
    assign uin_PcgcIntPeripheral.reqResources    = reqResources;
    assign uin_PcgcIntPeripheral.reqReset        = '0;
    assign uin_PcgcIntPeripheral.penaltyLevel    = '0;
    assign uin_PcgcIntPeripheral.taskZeroPenalty = '0;
    assign uin_PcgcIntPeripheral.taskFullPenalty = '0;
    assign uin_PcgcIntPeripheral.clockSource     = '0;
    assign uin_PcgcIntPeripheral.reqBuddy        = '0;
    // assign clocks and reset from the Pcgc peripheral interface to the local clocks and resets

    assign ckPar               = uin_PcgcIntPeripheral.ck[0];
    assign arstPar             = uin_PcgcIntPeripheral.arst[0];

  // ---------------------------------------------
  // -- Module instantiations:
  // ---------------------------------------------
  EventGeneratorUnitPar # (
    .INCLUDE_EVENT_GENERATOR_UNIT             (INCLUDE_EVENT_GENERATOR_UNIT),
    .INCLUDE_PAR_EVENTS_AND_IRQ               (INCLUDE_PAR_EVENTS_AND_IRQ),
    .SELECT_EVENT_TRIGGERS                    (SELECT_EVENT_TRIGGERS),
    .SELECT_TASK_REGISTERS                    (SELECT_TASK_REGISTERS),
    .SELECT_NMI                               (SELECT_NMI),
    .PAR_AW                                   (PAR_AW),
    .PAR_DW                                   (PAR_DW),
    .PAR_WW                                   (PAR_WW),
    .NUM_TASKS                                (NUM_TASKS),
    .NUM_EVENTS                               (NUM_EVENTS),
    .NUM_CLOCK_POWER_PAIR                     (NUM_CLOCK_POWER_PAIR),
    .ID_EVENT_GENERATOR_UNIT_EVENT_BASE       (ID_EVENT_GENERATOR_UNIT_EVENT_BASE),
    .ID_EVENT_GENERATOR_UNIT_TASK_BASE        (ID_EVENT_GENERATOR_UNIT_TASK_BASE),
    .ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES   (ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES),
    .ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES  (ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES),
    .ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE       (ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE),
    .ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE   (ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE),
    .ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE (ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE),
    .ID_EVENT_GENERATOR_UNIT_NMI_ENABLE       (ID_EVENT_GENERATOR_UNIT_NMI_ENABLE),
    .ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE   (ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE),
    .ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE (ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE),
    .RV_IRQ_ENABLE                            (RV_IRQ_ENABLE),
    .RV_TASKS                                 (RV_TASKS),
    .RV_EVENTS                                (RV_EVENTS)
  )u_Par(
    .parDi                      (parDiEguPar),
    .parDiSelect                (parDiSelectEguPar),
    .arstPar                    (arstPar),
    .ckPar                      (ckPar),
    .parAddr                    (parAddr),
    .parDo                      (parDo),
    .parRe                      (parRe),
    .parWe                      (parWe),
    .events                     (events),
    .tasks                      (tasks),
    .irqEventGeneratorUnit      (irqEventGeneratorUnit),
    .nmiEventGeneratorUnit       (nmiEventGeneratorUnit));
  EventGeneratorUnitReqControl # (
    .INCLUDE_EVENT_GENERATOR_UNIT (INCLUDE_EVENT_GENERATOR_UNIT),
    .NUM_CLOCK_POWER_PAIR         (NUM_CLOCK_POWER_PAIR)
  )u_ReqControl(
      .reqResources (reqResources),
      .reqResources_a (reqResources_a),
      .reqRequest (reqRequest)
);
  PcgcSlave # (
    .INCLUDE_PERIPHERAL           (INCLUDE_EVENT_GENERATOR_UNIT),
    .NUM_CLOCK_POWER_PAIR         (NUM_CLOCK_POWER_PAIR),
    .PAR_AW                       (PAR_AW),
    .PCGC_VERSION                 (2)
  )u_PcgcSlave(
    .pcgcBus                      (pcgcBusSlave),
    .pcgcIntPeripheral            (uin_PcgcIntPeripheral),
    .parAddr                      (parAddr),
    .parDo                        (parDo),
    .parRe                        (parRe),
    .parWe                        (parWe),
    .parDi                        (parDiPcgc),
    .parDiSelect                  (parDiSelectPcgc),
    .parDiMain                    (parDiEguPar),
    .parDiSelectMain              (parDiSelectEguPar)
  );
  PpiBusLegacy #(
    .APB_AW                           (PAR_AW),                   // -- Uses APB_AW, but they seem to be same size for conversion.
    .NUM_CHANNELS                     (NUM_PPI_CHANNELS),
    //.NUM_FIXED_CHANNELS               (NUM_FIXED_CHANNELS), // -- What does this even do?
    .ID_PPIBUS_CONSUMER_BASE          (ID_PPIBUS_CONSUMER_BASE),
    .ID_PPIBUS_PRODUCER_BASE          (ID_PPIBUS_PRODUCER_BASE),
    .INCLUDE_PPIBUS                   (INCLUDE_PPIBUS),
    .BYPASS_PPIBUS                    (BYPASS_PPIBUS),
    .CONSUMER_MASK                    (CONSUMER_MASK),
    .PRODUCER_MASK                    (PRODUCER_MASK)
  )u_PpiBusLegacy(
    .arst                             (arstPar),
    .ck                               (ckPar),
    .parDi                            (parDiPpi),
    //.parDi                            ({'0, parDiPpi[PAR_DW-1:0]}),
    .parDiSelect                      (parDiSelectPpi),
    .parAddr                          (parAddr[PAR_AW-1:0]),
    .parDo                            (parDo[PAR_DW-1:0]),
    .parRe                            (parRe),
    .parWe                            (parWe[PAR_WW-1:0]),
    .parDiSelectMain                  (parDiSelectPcgc),
    .parDiMain                        (parDiPcgc[PAR_DW-1:0]),
    .tasks                            (tasks),
    .events                           (events),
    .ppiBusActive                     (ppiBusActive),
    .ppiBusProducer                   (ppiBusProducer),
    .ppiBusConsumer                   (ppiBusConsumer)

  );


  generate  if (INCLUDE_EVENT_GENERATOR_UNIT == 1) begin : la_Include



    assign reqRequest = ((|parWe) | parRe) | (|ppiBusConsumer);      // -- Legal syntax! If any activity on input, requests clock. reqRequest requests ck[0] (ckPar), so no delay.
    assign parDi = parDiPpi;
    assign parDiSelect = parDiSelectPpi;


    end
    else begin : la_LeaveOut
      assign parDi = '0;
      assign parDiSelect = '0;
    end
  endgenerate


endmodule
