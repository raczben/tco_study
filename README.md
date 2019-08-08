# tco_study
Case study of synchronous FPGA signaling by adjusting the output timing

This is a case-study of synchronous FPGA signaling adjust the t_co (clock-to-output) timing. This
study uses Xilinx's Ultrascale architecture, however the metodology is general and can be aplied to
any FPGA family.

# The problem
Todays protocol mostly are *self synchronous*, which are don't need global synchronous behaviour.
But, in some case we cannot avoid global synchronity. This study shows how can it be achived using
FPGAs even in hard timing cases.

Let's assume that we want to build a [DAQ][1] (Data-acquisition) unit, which requires precision
trigger-timing. All module needs the trigger signal at the same time. (We need to assume that
all module gets the same clock with a given uncereanity.)

Altera has a quite good [cookbook][2] how to calculate timing. (Note, that all constraints can be
used for Xilinx's tools too.) The following picture is from that book. Chip-to-Chip Design with
Virtual Clocks as Input/Output Ports:

![Timing overview of synchronous devices](img/altera_timing_blockdiagram_small.png)

This study pay attention only the *B* side, where the FPGA is the signal driver.


[1]: https://en.wikipedia.org/wiki/Data_acquisition
[2]: https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/mnl_timequest_cookbook.pdf
