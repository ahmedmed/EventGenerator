 //====================================================================
//        Copyright (c) 2018 Nordic Semiconductor ASA, Norway
//====================================================================
// Created       : Kristian Jerndahl at 2018-10-08
// Modified      : $Author$ $Date$
// Version       : $Revision$ $HeadURL$
//====================================================================


module EventGeneratorUnitReqControl #(
              parameter INCLUDE_EVENT_GENERATOR_UNIT               = pa_EventGeneratorUnit::INCLUDE_EVENT_GENERATOR_UNIT              ,
              parameter NUM_CLOCK_POWER_PAIR                       = pa_EventGeneratorUnit::NUM_CLOCK_POWER_PAIR
  )(// -- Outputs:
   output logic [NUM_CLOCK_POWER_PAIR-1:0]                            reqResources,
   output logic [NUM_CLOCK_POWER_PAIR-1:0]                            reqResources_a,
   // -- Inputs:
   input logic                              reqRequest   // Output of comb in main module
  );

  // ---------------------------------------------
  // -- Internal declarations:
  // ---------------------------------------------



  // --------------------------------
  // -- PCGC
  // --------------------------------


  generate
    if (INCLUDE_EVENT_GENERATOR_UNIT == 1) begin : la_Include
      assign reqResources[0] = reqRequest;
      assign reqResources[NUM_CLOCK_POWER_PAIR-1:1] = '0;
      assign reqResources_a = '0;
    end
    else begin : la_LeaveOut
      assign reqResources = '0;
    end
  endgenerate


endmodule
