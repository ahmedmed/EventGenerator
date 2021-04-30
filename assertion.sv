//====================================================================
//        Copyright (c) 2017 Nordic Semiconductor ASA, Norway
//====================================================================
// Created       : chsh at 2017-02-07
// Modified      : $Author$ $Date$
// Version       : $Revision$ $HeadURL$
//====================================================================

module assertionsEventGeneratorUnit (
  output int errorCntAssertion
  );


endmodule




`ifndef errmsg
  `define errmsg(msg) \
    assertionErrorCnt++; \
    $display(st_err_head); $error(msg); $display(st_err_foot);
`else
  `define ERRMSG_DEFINE_ERROR
`endif

`ifndef assert_arst_Core
  //To be used in assertions on scaled clock to core (source either 1MHz or 16MHz).
  `define assert_arst_Core(assertionLabel, arg, disableIf, msgArg) \
    assertionLabel : assert property (@(posedge ckCore) disable iff (arst[1] || runningParVerifier || disableAssertions || (disableIf)) arg) \
                     else begin automatic string msg = msgArg; `errmsg(msg); end
`else
  `define ASSERTARSTCORE_DEFINE_ERROR
`endif

`ifndef assert_arst_1
  //To be used in assertions on 1MHz source clock.
  `define assert_arst_1(assertionLabel, arg, disableIf, msgArg) \
    assertionLabel : assert property (@(posedge ck1M)   disable iff (arst[1] || runningParVerifier || disableAssertions || (disableIf)) arg) \
                     else begin automatic string msg = msgArg; `errmsg(msg); end
`else
  `define ASSERTARST1_DEFINE_ERROR
`endif

`ifndef assert_arst
  //To be used in assertions on 16MHz source clock.
  `define assert_arst(assertionLabel, arg, disableIf, msgArg) \
    assertionLabel : assert property (@(posedge ck)     disable iff (arst[1] || runningParVerifier || disableAssertions || (disableIf)) arg) \
                     else begin automatic string msg = msgArg;  `errmsg(msg); end
`else
  `define ASSERTARST_DEFINE_ERROR
`endif
  // ------------------------------
  // Example use of above Macro's:
  // ------------------------------
  // logic testBit = 1'b0;
  // -------- Print out unformatted string as "comment" :
  //  `assert_arst(testAssertion_1,                          // label
  //               testBit == 1'b1,                          // property
  //               0,                                        // additional disable condition
  //               "I'm just writing a string.");            // Unformatted Message
  //-------- Print out of formatted string using $sformatf:
  //  `assert_arst(testAssertion_2,
  //               testBit == 1'b1,
  //               0,
  //               $sformatf("This string is formatted %0d, %0h", 512512, 15));



  //--------------------------------------------------
  // -- Internal variables:
  //--------------------------------------------------
  string st_err_head = "";
  string st_err_foot = "";
  string msg         = "";
  int     assertionErrorCnt         ;
  logic   [63:0] coreCount          ;

  assign coreCount = arst[1] ? 63'b0 : count;


`ifdef ASSERT_ON
`endif

  initial begin
    `ifdef ERRMSG_DEFINE_ERROR
      $info("Macro `errmsg was already defined elsewhere. Something may not work as intended!");
    `endif
    `ifdef ASSERTARSTCORE_DEFINE_ERROR
      $info("Macro `assert_arst_core was already defined elsewhere. Something may not work as intended!");
    `endif
    `ifdef ASSERTARST1_DEFINE_ERROR
      $info("Macro `assert_arst_1 was already defined elsewhere. Something may not work as intended!");
    `endif
    `ifdef ASSERTARST_DEFINE_ERROR
      $info("Macro `assert_arst was already defined elsewhere. Something may not work as intended!");
    `endif
  end


  //--------------------------------------------------
  // -- Assertion instantiations:
  //--------------------------------------------------