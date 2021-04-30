//====================================================================
//        Copyright (c) 2018 Nordic Semiconductor ASA, Norway
//====================================================================
// Created       : Kristian Jerndahl at 2018-10-08
// Modified      : $Author$ $Date$
// Version       : $Revision$ $HeadURL$
//====================================================================


module EventGeneratorUnitPar #(
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
  parameter [NUM_TASKS-1:0][PAR_AW-1:0] ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES     = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES    ,
  parameter [NUM_EVENTS-1:0][PAR_AW-1:0]ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES    = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES   ,
  parameter                             ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE         = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE        ,
  parameter                             ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE     = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE    ,
  parameter                             ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE   = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE  ,
  parameter                             ID_EVENT_GENERATOR_UNIT_NMI_ENABLE         = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_NMI_ENABLE        ,
  parameter                             ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE     = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE    ,
  parameter                             ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE   = pa_EventGeneratorUnit::ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE  ,
  parameter                             RV_IRQ_ENABLE                              = pa_EventGeneratorUnit::RV_IRQ_ENABLE                             ,
  parameter                             RV_TASKS                                   = pa_EventGeneratorUnit::RV_TASKS                                  ,
  parameter                             RV_EVENTS                                  = pa_EventGeneratorUnit::RV_EVENTS
  )
  (// -- PAR interface outputs:
   output logic  [PAR_DW-1:0]               parDi                  ,    // -- PAR Bus return data.
   output logic                             parDiSelect            ,    // -- PAR Bus return data select.
   // -- PAR interface inputs:
   input  logic                             arstPar                ,
   input  logic                             ckPar                  ,
   input  logic  [PAR_AW-1:0]               parAddr                ,    // -- PAR Bus address.
   input  logic  [PAR_DW-1:0]               parDo                  ,    // -- PAR Bus data from MCU.
   input  logic                             parRe                  ,    // -- PAR Bus read enable.
   input  logic  [PAR_WW-1:0]               parWe                  ,    // -- PAR Bus write enable.

   //input  logic  [PAR_DW-1:0]               parDiParent             ,    // -- parDi from ParEventsAndIrq
   //input  logic                             parDiSelectParent       ,    // -- parDiSelect from ParEventsAndIrq
   // -- Outputs:
   output  logic [NUM_TASKS-1:0]            events                ,    // -- Events to PPI

   // -- Inputs:
   input   logic [NUM_TASKS-1:0]            tasks                 ,    // -- Tasks from PPI

   output logic                             irqEventGeneratorUnit,      // -- IRQ.
   output logic                             nmiEventGeneratorUnit      // -- IRQ.
  );
    // ---------------------------------------------
  // -- Internal declarations:
  // ---------------------------------------------


  logic [NUM_TASKS-1:0]               tasks_parWrite ;    // tasktrigger from PAR
  logic [NUM_TASKS-1:0]               taskTrigger ;       // -- Tasks to ParEventsAndIrq
  // -- PARs:
  logic [PAR_DW-1:0]                  parDiThis;       // -- parDi from ParEventsAndIrq
  logic                               parDiSelectThis; // -- parDiSelect from ParEventsAndIrq
  logic [PAR_DW-1:0]                  parDiParent;       // -- parDi from ParEventsAndIrq
  logic                               parDiSelectParent; // -- parDiSelect from ParEventsAndIrq
  logic [NUM_TASKS-1:0]               tasks_rg;          // -- Task: tasks.

  // ---------------------------------------------
  // -- Module instantiations:
  // ---------------------------------------------
  ParEventsAndIrq  #(
    .PAR_AW                                  (PAR_AW),
    .PAR_WW                                  (PAR_WW),
    .NUM_EVENTS                              (NUM_EVENTS),
    .SELECT_EVENT_TRIGGERS                   (SELECT_EVENT_TRIGGERS),
    .INCLUDE_PAR_EVENTS_AND_IRQ              (INCLUDE_PAR_EVENTS_AND_IRQ),
    .SELECT_NMI                              (SELECT_NMI),
    .ID_EVENT_BASE                           (ID_EVENT_GENERATOR_UNIT_EVENT_BASE),
    .ID_EVENT_ADDRESSES                      (ID_EVENT_GENERATOR_UNIT_EVENT_ADDRESSES),
    .ID_IRQ_ENABLE                           (ID_EVENT_GENERATOR_UNIT_IRQ_ENABLE),
    .ID_SET_IRQ_ENABLE                       (ID_EVENT_GENERATOR_UNIT_SET_IRQ_ENABLE),
    .ID_CLEAR_IRQ_ENABLE                     (ID_EVENT_GENERATOR_UNIT_CLEAR_IRQ_ENABLE),
    .ID_NMI_ENABLE                           (ID_EVENT_GENERATOR_UNIT_NMI_ENABLE),
    .ID_SET_NMI_ENABLE                       (ID_EVENT_GENERATOR_UNIT_SET_NMI_ENABLE),
    .ID_CLEAR_NMI_ENABLE                     (ID_EVENT_GENERATOR_UNIT_CLEAR_NMI_ENABLE),
    .RV_IRQ_ENABLE                           (RV_IRQ_ENABLE),
    .RV_EVENTS                               (RV_EVENTS)
  )u_ParEventsAndIrq(
    .parDi (parDiParent),
    .parDiSelect (parDiSelectParent),
    .arstPar (arstPar),
    .ckPar (ckPar),
    .parAddr (parAddr),
    .parDo    (parDo),
    .parRe           (parRe),
    .parWe   (parWe),
    .events (events),
    .irq (irqEventGeneratorUnit),
    .nmi (nmiEventGeneratorUnit),
    .eventsFromCore (taskTrigger),
    .parDiParent ('0),
    .parDiSelectParent('0)
  );








  generate if (INCLUDE_EVENT_GENERATOR_UNIT) begin : la_include
    // ---------------------------------------------
    // -- Tasks:
    // ---------------------------------------------
    for (genvar g = 0; g < NUM_TASKS; g++) begin : la_parTaskTriggers
      always_comb begin
        if(parRe) begin
          tasks_parWrite[g] <= 0;
        end else begin
          if(parWe[0] & parDo[0] & (parAddr == ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES[g])) begin
            tasks_parWrite[g] <= 1;
          end
          else begin
            tasks_parWrite[g] <= 0;
          end
        end
      end
    end : la_parTaskTriggers



    assign taskTrigger       = tasks | tasks_parWrite;

    // ---------------------------------------------
    // -- Local PAR write and read:
    // ---------------------------------------------
    // -- PAR write process on ckPar (single accessed registers).
       // -- Double accessed registers:
    if(SELECT_TASK_REGISTERS == 1) begin : la_parTaskRegistersEnabled
      always_ff @(posedge ckPar or posedge arstPar) begin : la_DoubleAccessedParWrite
        if (arstPar) begin
          tasks_rg <= RV_TASKS;
        end
        else begin
          for (int i = 0; i < NUM_TASKS; i ++) begin
            if (taskTrigger[i]) begin
              tasks_rg[i] <= 1'b 1;
            end
            else if (parWe[0]) begin
              if (!parDo[0] && (parAddr == ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES[i])) begin
                tasks_rg[i] <= 1'b 0;
              end
            end
          end
        end
      end : la_DoubleAccessedParWrite

      always_comb begin : la_ParRead
        if (parRe) begin
          parDiThis        = 32'd 0;
          for (int i = 0; i < NUM_TASKS; i++) begin
            if (parAddr == ID_EVENT_GENERATOR_UNIT_TASK_ADDRESSES[i]) begin
              parDiSelectThis = 1;
              parDiThis       = {{32-1 {1'b 0}}, tasks_rg[i]};
            end
          end

        end
        else begin
          parDiThis        = 32'd 0;
          parDiSelectThis  =  1'b 0;
        end
      end : la_ParRead

    end : la_parTaskRegistersEnabled
    else begin : la_noparTaskRegistersEnabled
        assign tasks_rg = '0;
    end : la_noparTaskRegistersEnabled
    // ---------------------------------------------
    // -- ParDiSelect and ParDi Multiplexing:
    // ---------------------------------------------
    always_comb begin
        if (parDiSelectParent)
          parDi = parDiParent;
        else if (parDiSelectThis)
          parDi = parDiThis;
        else
          parDi = 'h 0;
    end

    assign parDiSelect = parDiSelectParent | parDiSelectThis;


  end else begin : la_leavout
    assign tasks = '0;
    assign taskTrigger ='0;
  end
  endgenerate


endmodule
