/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used solely      *
*     for design, simulation, implementation and creation of design files      *
*     limited to Xilinx devices or technologies. Use with non-Xilinx           *
*     devices or technologies is expressly prohibited and immediately          *
*     terminates your license.                                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY     *
*     FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY     *
*     PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE              *
*     IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS       *
*     MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY       *
*     CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY        *
*     RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY        *
*     DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE    *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A    *
*     PARTICULAR PURPOSE.                                                      *
*                                                                              *
*     Xilinx products are not intended for use in life support appliances,     *
*     devices, or systems.  Use in such applications are expressly             *
*     prohibited.                                                              *
*                                                                              *
*     (c) Copyright 1995-2016 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/
// You must compile the wrapper file data_ram.v when simulating
// the core, data_ram. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

// The synthesis directives "translate_off/translate_on" specified below are
// supported by Xilinx, Mentor Graphics and Synplicity synthesis
// tools. Ensure they are correct for your synthesis tool(s).

// test
`timescale 1ns/1ps

module data_ram(
  clka,
  wea,
  addra,
  dina,
  douta,
  clkb,
  web,
  addrb,
  dinb,
  doutb
);

input clka;
input [3 : 0] wea;
input [7 : 0] addra;
input [31 : 0] dina;
output [31 : 0] douta;
input clkb;
input [3 : 0] web;
input [7 : 0] addrb;
input [31 : 0] dinb;
output [31 : 0] doutb;

// ENTITY data_ram_ip IS
//   PORT (
//     clka : IN STD_LOGIC;
//     wea : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
//     addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
//     dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
//     douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
//     clkb : IN STD_LOGIC;
//     web : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
//     addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
//     dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
//     doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
//   );
// END data_ram_ip;

data_ram_ip entity (
  .clka(clka),
  .wea(wea),
  .addra(addra),
  .dina(dina),
  .douta(douta),
  .clkb(clkb),
  .web(web),
  .addrb(addrb),
  .dinb(dinb),
  .doutb(doutb)
);


endmodule
