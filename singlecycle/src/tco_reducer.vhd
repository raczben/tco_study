

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
    
    -- Native output doesn't uses any "magic" it just a simple output. (Therefore) it *fails* the
    -- timing requirements.
    o_native_p          : out std_logic;
    o_native_n          : out std_logic;
    
    -- DDR output: I hoped that DDR output can be faster than simple outputs, but it *fails* too.
    o_ddr_p             : out std_logic;
    o_ddr_n             : out std_logic;
    
    -- IOB: uses `set_property IOB TRUE` in the implementation constraint file. It is *fails* also
    -- because it is not fast enough either. (However it has better timing values.)
    o_iob_p             : out std_logic;
    o_iob_n             : out std_logic
  );
end tco_reducer_top;

architecture behavioral of tco_reducer_top is

  -- To generate dummy signals
  signal q_cntr                 : unsigned(15 downto 0);
  
  -- Two registers for all outputs to improve timing
  signal q_native_d1            : std_logic;
  signal q_native_d2            : std_logic;
  signal q_ddr_d1               : std_logic;
  signal q_ddr_d2               : std_logic;
  signal q_iob_d1               : std_logic;
  signal q_iob_d2               : std_logic;
  
  signal w_ddr                  : std_logic;
  
  signal w_clk                  : std_logic;
  
  
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
  
  
  -- Each output is a bit of the counter.
  proc_cntr_to_data: process(w_clk) begin
    if rising_edge(w_clk) then
      -- Use different outputs to preserve optimization
      q_native_d1           <= q_cntr(15);
      q_iob_d1              <= q_cntr(14);
      q_ddr_d1              <= q_cntr(13);
    end if;
  end process proc_cntr_to_data;
  
  
  -- A second FF is used improve timing. (Note that shifted output is not in this process.)
  proc_d2: process(w_clk) begin
    if rising_edge(w_clk) then
      q_native_d2           <= q_native_d1;
      q_iob_d2              <= q_iob_d1;
      q_ddr_d2              <= q_ddr_d1;
    end if;
  end process proc_d2;
  
   
  ODDRE1_inst : ODDRE1
  generic map (
    IS_C_INVERTED => '0',  -- Optional inversion for C
    SRVAL => '0'           -- Initializes the ODDRE1 Flip-Flops to the specified value ('0', '1')
  )
  port map (
    Q => w_ddr,   -- 1-bit output: Data output to IOB
    C => w_clk,   -- 1-bit input: High-speed clock input
    D1 => q_ddr_d2, -- 1-bit input: Parallel data input 1
    D2 => q_ddr_d2, -- 1-bit input: Parallel data input 2
    SR => '0'  -- 1-bit input: Active High Async Reset
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
  
  -- Native
  inst_native_obufds : OBUFDS
  generic map(
    IOSTANDARD => "LVDS"
  )
  port map(
    O  => o_native_p,
    OB => o_native_n,
    I  => q_native_d2
  );
    
  -- IOB (simple)
  inst_iob_obufds : OBUFDS
  generic map(
    IOSTANDARD => "LVDS"
  )
  port map(
    O  => o_iob_p,
    OB => o_iob_n,
    I  => q_iob_d2
  );
    
    
  -- DDR
  inst_ddr_obufds : OBUFDS
  generic map(
    IOSTANDARD => "LVDS"
  )
  port map(
    O  => o_ddr_p,
    OB => o_ddr_n,
    I  => w_ddr
  );

end behavioral;
