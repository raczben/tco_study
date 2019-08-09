library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity tco_reducer_top is
  port (
    --  Clock and reset
    i_clk_p             : in  std_logic;
    i_clk_n             : in  std_logic;
    i_rst               : in  std_logic;
    
    --
    -- Outputs using different method to met timing
    --
    
    -- IOB with shifted clock (and multicycle path): There is a phase-shifted clock, which move the
    -- datavalid window to a given time. This PASS the timing.
    o_iob_shifted_clk_p : out std_logic;
    o_iob_shifted_clk_n : out std_logic;
    
    -- Odelay (and multicycle path): This output uses odelay with fixed delay value to shift the
    -- data valid window to a given time.
    o_odelay_p          : out std_logic;
    o_odelay_n          : out std_logic;
    
    -- Odelay with inverted clock (and multicycle path): This output uses inverted clock at the last
    -- FF then it applies odelay with fixed delay value to shift the data valid window to a given
    -- time. Notice, that this is a combined variant of the shifted clock (180 deg) and the odelay.
    o_odelay_nclk_p     : out std_logic;
    o_odelay_nclk_n     : out std_logic
  );
end tco_reducer_top;

architecture behavioral of tco_reducer_top is

  -- To generate dummy signals
  signal q_cntr                 : unsigned(15 downto 0);
  
  -- Two registers for all outputs to improve timing
  signal q_iob_shifted_clk_d1   : std_logic;
  signal q_iob_shifted_clk_d2   : std_logic;
  signal q_odelay_d1            : std_logic;
  signal q_odelay_d2            : std_logic;
  signal q_odelay_nclk_d1       : std_logic;
  signal q_odelay_nclk_d2       : std_logic;
  
  signal q_rst_d1                : std_logic;
  signal w_odelay               : std_logic;
  signal w_ddr                  : std_logic;
  signal w_odelay_01            : std_logic;
  signal w_odelay_03            : std_logic;
  signal w_odelay_casc_01       : std_logic;
  signal w_odelay_casc_02       : std_logic;
  signal w_odelay_nclk          : std_logic;
  
  signal w_clk                  : std_logic;
  signal w_clk_n                : std_logic;
  signal w_clk_shifted          : std_logic;
  signal w_clk_300              : std_logic;
  
  
  component clk_wiz_trigger
  port (
    o_clk_100_shifted   : out    std_logic;
    o_clk_300           : out    std_logic;
    -- Status and control signals
    locked              : out    std_logic;
    clk_in1             : in     std_logic
   );
  end component;
  
begin
  
  -- This is a simple counter for dummy data generation.
  proc_counter: process(w_clk) begin
    if rising_edge(w_clk) then 
      if i_rst = '1' then
        q_cntr <= (others => '0');
      else
        q_cntr <= q_cntr + 1 ;
      end if;  -- i_rst
    end if;  -- rising_edge(w_clk)
  end process proc_counter;
  
  -- Reset timing release
  proc_rst: process(w_clk) begin
    if rising_edge(w_clk) then
      q_rst_d1 <= i_rst;
    end if;
  end process proc_rst;
  
  -- Each output is a bit of the counter.
  proc_cntr_to_data: process(w_clk) begin
    if rising_edge(w_clk) then
      -- Use different outputs to preserve optimization
      q_iob_shifted_clk_d1  <= q_cntr(12);
      q_odelay_d1           <= q_cntr(11);
    end if;
  end process proc_cntr_to_data;
  
  
  -- A second FF is used improve timing. (Note that shifted output is not in this process.)
  proc_d2: process(w_clk) begin
    if rising_edge(w_clk) then
      q_odelay_d2           <= q_odelay_d1;
    end if;
  end process proc_d2;
  
  
  -- A second FF is used improve timing. (inverted clock.)
  proc_d2_inverted: process(w_clk_n) begin
    if rising_edge(w_clk_n) then
      q_odelay_nclk_d2     <= q_odelay_nclk_d1;
    end if;
  end process proc_d2_inverted;
  
  
  -- A second FF is used improve timing. (Shifted clock.)
  proc_d2_shifted: process(w_clk_shifted) begin
    if rising_edge(w_clk_shifted) then
      q_iob_shifted_clk_d2  <= q_iob_shifted_clk_d1;
    end if;
  end process proc_d2_shifted;
  
  
  inst_clk_wiz_trigger : clk_wiz_trigger
  port map ( 
    -- Clock out ports  
    o_clk_100_shifted   => w_clk_shifted,
    o_clk_300           => w_clk_300,
    -- Status and control signals                
    locked          => open,
    -- Clock in ports
    clk_in1         => w_clk
  );
  
  IDELAYCTRL_inst : IDELAYCTRL
  generic map (
    SIM_DEVICE => "ULTRASCALE"  -- Must be set to "ULTRASCALE" 
  )
  port map (
    RDY => open,       -- 1-bit output: Ready output
    REFCLK => w_clk_300, -- 1-bit input: Reference clock input
    RST => q_rst_d1      -- 1-bit input: Active high reset input. Asynchronous assert, synchronous deassert to
                      -- REFCLK.
  );
  

  -- Odelay chain
  ODELAYE3_nclk_inst : ODELAYE3
  generic map (
    CASCADE         => "NONE",    -- Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
    DELAY_FORMAT    => "TIME",      -- (COUNT, TIME)
    DELAY_TYPE      => "FIXED",     -- Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
    DELAY_VALUE     => 1250,        -- Output delay tap setting
    IS_CLK_INVERTED => '0',         -- Optional inversion for CLK
    IS_RST_INVERTED => '0',         -- Optional inversion for RST
    REFCLK_FREQUENCY=> 300.0,       -- IDELAYCTRL clock input frequency in MHz (200.0-2667.0).
    SIM_DEVICE      => "ULTRASCALE", -- Set the device version (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1,
                                    -- ULTRASCALE_PLUS_ES2)
    UPDATE_MODE     => "ASYNC"      -- Determines when updates to the delay will take effect (ASYNC, MANUAL,
                                    -- SYNC)
  )
  port map (
    CASC_OUT        => open, -- 1-bit output: Cascade delay output to IDELAY input cascade
    CNTVALUEOUT     => open,        -- 9-bit output: Counter value output
    DATAOUT         => w_odelay_nclk,    -- 1-bit output: Delayed data from ODATAIN input port
    CASC_IN         => '0',         -- 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
    CASC_RETURN     => '0', -- 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
    CE              => '0',         -- 1-bit input: Active high enable increment/decrement input
    CLK             => w_clk_300,   -- 1-bit input: Clock input
    CNTVALUEIN      => "000000000", -- 9-bit input: Counter value input
    EN_VTC          => '1',         -- 1-bit input: Keep delay constant over VT
    INC             => '0',         -- 1-bit input: Increment/Decrement tap delay input
    LOAD            => '0',         -- 1-bit input: Load DELAY_VALUE input
    ODATAIN         => q_odelay_nclk_d2, -- 1-bit input: Data input
    RST             => '0'          -- 1-bit input: Asynchronous Reset to the DELAY_VALUE
  );
  

  -- Odelay chain
  ODELAYE3_master_01_inst : ODELAYE3
  generic map (
    CASCADE         => "MASTER",    -- Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
    DELAY_FORMAT    => "TIME",      -- (COUNT, TIME)
    DELAY_TYPE      => "FIXED",     -- Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
    DELAY_VALUE     => 1250,        -- Output delay tap setting
    IS_CLK_INVERTED => '0',         -- Optional inversion for CLK
    IS_RST_INVERTED => '0',         -- Optional inversion for RST
    REFCLK_FREQUENCY=> 300.0,       -- IDELAYCTRL clock input frequency in MHz (200.0-2667.0).
    SIM_DEVICE      => "ULTRASCALE", -- Set the device version (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1,
                                    -- ULTRASCALE_PLUS_ES2)
    UPDATE_MODE     => "ASYNC"      -- Determines when updates to the delay will take effect (ASYNC, MANUAL,
                                    -- SYNC)
  )
  port map (
    CASC_OUT        => w_odelay_casc_01, -- 1-bit output: Cascade delay output to IDELAY input cascade
    CNTVALUEOUT     => open,        -- 9-bit output: Counter value output
    DATAOUT         => w_odelay,    -- 1-bit output: Delayed data from ODATAIN input port
    CASC_IN         => '0',         -- 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
    CASC_RETURN     => w_odelay_01, -- 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
    CE              => '0',         -- 1-bit input: Active high enable increment/decrement input
    CLK             => w_clk_300,   -- 1-bit input: Clock input
    CNTVALUEIN      => "000000000", -- 9-bit input: Counter value input
    EN_VTC          => '1',         -- 1-bit input: Keep delay constant over VT
    INC             => '0',         -- 1-bit input: Increment/Decrement tap delay input
    LOAD            => '0',         -- 1-bit input: Load DELAY_VALUE input
    ODATAIN         => q_odelay_d2, -- 1-bit input: Data input
    RST             => '0'          -- 1-bit input: Asynchronous Reset to the DELAY_VALUE
  );
  
  
  IDELAYE3_slave_02_inst : IDELAYE3
  generic map (
    CASCADE         => "SLAVE_MIDDLE",  -- Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
    DELAY_FORMAT    => "TIME",      -- Units of the DELAY_VALUE (COUNT, TIME)
    DELAY_SRC       => "IDATAIN",   -- Delay input (DATAIN, IDATAIN)
    DELAY_TYPE      => "FIXED",     -- Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
    DELAY_VALUE     => 1250,           -- Input delay value setting
    IS_CLK_INVERTED => '0',         -- Optional inversion for CLK
    IS_RST_INVERTED => '0',         -- Optional inversion for RST
    REFCLK_FREQUENCY=> 300.0,       -- IDELAYCTRL clock input frequency in MHz (200.0-2667.0)
    SIM_DEVICE      => "ULTRASCALE", -- Set the device version (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1,
                                    -- ULTRASCALE_PLUS_ES2)
    UPDATE_MODE     => "ASYNC"      -- Determines when updates to the delay will take effect (ASYNC, MANUAL,
                                    -- SYNC)
  )
  port map (
    CASC_OUT        => w_odelay_casc_02,    -- 1-bit output: Cascade delay output to ODELAY input cascade
    CNTVALUEOUT     => open,        -- 9-bit output: Counter value output
    DATAOUT         => w_odelay_01, -- 1-bit output: Delayed data output
    CASC_IN         => w_odelay_casc_01,    -- 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
    CASC_RETURN     => w_odelay_03, -- 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
    CE              => '0',         -- 1-bit input: Active high enable increment/decrement input
    CLK             => w_clk_300,   -- 1-bit input: Clock input
    CNTVALUEIN      => "000000000", -- 9-bit input: Counter value input
    DATAIN          => '0',         -- 1-bit input: Data input from the logic
    EN_VTC          => '1',         -- 1-bit input: Keep delay constant over VT
    IDATAIN         => '0',         -- 1-bit input: Data input from the IOBUF
    INC             => '0',         -- 1-bit input: Increment / Decrement tap delay input
    LOAD            => '0',         -- 1-bit input: Load DELAY_VALUE input
    RST             => i_rst          -- 1-bit input: Asynchronous Reset to the DELAY_VALUE
  );

   
  
  ODELAYE3_slave_03_inst : ODELAYE3
  generic map (
    CASCADE         => "SLAVE_END", -- Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
    DELAY_FORMAT    => "TIME",      -- (COUNT, TIME)
    DELAY_TYPE      => "FIXED",     -- Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
    DELAY_VALUE     => 1250,        -- Output delay tap setting
    IS_CLK_INVERTED => '0',         -- Optional inversion for CLK
    IS_RST_INVERTED => '0',         -- Optional inversion for RST
    REFCLK_FREQUENCY=> 300.0,       -- IDELAYCTRL clock input frequency in MHz (200.0-2667.0).
    SIM_DEVICE      => "ULTRASCALE", -- Set the device version (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1,
                                    -- ULTRASCALE_PLUS_ES2)
    UPDATE_MODE     => "ASYNC"      -- Determines when updates to the delay will take effect (ASYNC, MANUAL,
                                    -- SYNC)
  )
  port map (
    CASC_OUT        => open,        -- 1-bit output: Cascade delay output to IDELAY input cascade
    CNTVALUEOUT     => open,        -- 9-bit output: Counter value output
    DATAOUT         => w_odelay_03,    -- 1-bit output: Delayed data from ODATAIN input port
    CASC_IN         => w_odelay_casc_02,         -- 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
    CASC_RETURN     => '0',         -- 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
    CE              => '0',         -- 1-bit input: Active high enable increment/decrement input
    CLK             => w_clk_300,   -- 1-bit input: Clock input
    CNTVALUEIN      => "000000000", -- 9-bit input: Counter value input
    EN_VTC          => '1',         -- 1-bit input: Keep delay constant over VT
    INC             => '0',         -- 1-bit input: Increment/Decrement tap delay input
    LOAD            => '0',         -- 1-bit input: Load DELAY_VALUE input
    ODATAIN         => '0',         -- 1-bit input: Data input
    RST             => i_rst          -- 1-bit input: Asynchronous Reset to the DELAY_VALUE
  );
  
  
  BUFGCE_clk_inverter_inst : BUFGCE
  generic map (
    CE_TYPE     => "SYNC",     -- ASYNC, SYNC
    IS_CE_INVERTED => '0', -- Programmable inversion on CE
    IS_I_INVERTED => '1'   -- Programmable inversion on I
  )
  port map (
    O   => w_clk_n,     -- 1-bit output: Buffer
    CE  => '1',         -- 1-bit input: Buffer enable
    I   => w_clk        -- 1-bit input: Buffer
  );
    
  inst_clk_ibufds : IBUFDS
  generic map(
    IOSTANDARD => "LVDS"
  )
  port map(
    I  => i_clk_p,
    IB => i_clk_n,
    O  => w_clk
  );
    
  --
  -- LVDS output buffers for different ouputs:
  --
    
  -- IOB with shifted clock
  inst_iob_shifted_obufds : OBUFDS
  generic map(
    IOSTANDARD => "LVDS"
  )
  port map(
    O  => o_iob_shifted_clk_p,
    OB => o_iob_shifted_clk_n,
    I  => q_iob_shifted_clk_d2
  );
    
  -- IOB with odelay
  inst_odelay_obufds : OBUFDS
  generic map(
    IOSTANDARD => "LVDS"
  )
  port map(
    O  => o_odelay_p,
    OB => o_odelay_n,
    I  => w_odelay
  );
  
  -- odelay with inverted clock
  inst_odelay_nclk_obufds : OBUFDS
  generic map(
    IOSTANDARD => "LVDS"
  )
  port map(
    O  => o_odelay_nclk_p,
    OB => o_odelay_nclk_n,
    I  => w_odelay_nclk
  );
    
end behavioral;
