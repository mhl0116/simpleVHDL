----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/14/2020 02:56:01 PM
-- Design Name: 
-- Module Name: datafifo_dcfeb_exdes2 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_unsigned.ALL;
USE IEEE.STD_LOGIC_arith.ALL;
USE ieee.numeric_std.ALL;
USE ieee.STD_LOGIC_misc.ALL;

library unisim;
use unisim.vcomponents.all;

LIBRARY std;
USE std.textio.ALL;

LIBRARY work;
USE work.datafifo_dcfeb_pkg.ALL;
--------------------------------------------------------------------------------
-- Entity Declaration
--------------------------------------------------------------------------------
ENTITY datafifo_dcfeb_exdes2 IS
  GENERIC(
  	   FREEZEON_ERROR : INTEGER := 0;
	   TB_STOP_CNT    : INTEGER := 2;
	   TB_SEED        : INTEGER := 24 
	 );
  PORT(
	    WR_CLK     :  IN  STD_LOGIC := '0';
	    RD_CLK     :  IN  STD_LOGIC := '0';
        RESET      :  IN  STD_LOGIC := '0';
        RESET_EXT  :  IN  STD_LOGIC := '0';
        SIM_DONE   :  OUT STD_LOGIC := '0';
        STATUS     :  OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
END ENTITY;

architecture Behavioral of datafifo_dcfeb_exdes2 is
    
    SIGNAL clk_counter_wr     : std_logic := '0';
    SIGNAL reset_counter_wr   : std_logic := '0'; 
    SIGNAL counter_wr         : std_logic_vector(18-1 downto 0) := (others => '0');
    SIGNAL done_wr            : std_logic := '0';
    SIGNAL done_wr_dly        : std_logic := '0';

    SIGNAL clk_counter_rd     : std_logic := '0';
    SIGNAL reset_counter_rd   : std_logic := '0'; 
    SIGNAL counter_rd         : std_logic_vector(18-1 downto 0) := (others => '0');
    SIGNAL done_rd            : std_logic := '0';
    
    SIGNAL checker            : std_logic := '0';
    SIGNAL counter_err        : std_logic_vector(18-1 downto 0) := (others => '0');
    
    -- fifo signals
    SIGNAL wr_clk_i                       :   STD_LOGIC := '0';
    SIGNAL rd_clk_i                       :   STD_LOGIC := '0';
    SIGNAL srst                           :   STD_LOGIC := '0';
    SIGNAL prog_full                      :   STD_LOGIC := '0';
    --SIGNAL sleep                          :   STD_LOGIC := '0';
    SIGNAL wr_rst_busy                    :   STD_LOGIC := '0';
    SIGNAL rd_rst_busy                    :   STD_LOGIC := '0';
    SIGNAL wr_en                          :   STD_LOGIC := '0';
    SIGNAL rd_en                          :   STD_LOGIC := '0';
    SIGNAL din                            :   STD_LOGIC_VECTOR(18-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL dout                           :   STD_LOGIC_VECTOR(18-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL full                           :   STD_LOGIC := '0';
    SIGNAL empty                          :   STD_LOGIC := '1';
begin

---- Clock buffers for testbench ----
wr_clk_buf: bufg
 PORT map(
   i =>  WR_CLK,
   o => wr_clk_i 
  );
  
rd_clk_buf: bufg
 PORT map(
   i =>  RD_CLK,
   o => rd_clk_i 
  );
------------------

reset_counter_wr <= RESET_EXT;
clk_counter_wr <= wr_clk_i;

reset_counter_rd <= RESET_EXT;
clk_counter_rd <= rd_clk_i;

-- 18 bits counter
process(clk_counter_wr,reset_counter_wr,full,done_wr)
begin
if(rising_edge(clk_counter_wr) ) then
    if(reset_counter_wr='1') then
        counter_wr <= b"00" & x"0000";
    elsif(done_wr='0') then
        counter_wr <= counter_wr + "1";
    else
        done_wr_dly <= done_wr;
    end if;
end if;

if(rising_edge(full)) then
    done_wr <= full;
end if;
end process;

process(clk_counter_rd,reset_counter_rd,done_wr_dly)
begin
if(rising_edge(clk_counter_rd)) then
    if(reset_counter_rd='1') then
        counter_rd <= b"00" & x"0001";
    elsif(done_wr_dly='1') then
        counter_rd <= counter_rd + x"2";
    end if;
 end if;
end process;

-- write enable for odd number in counter
wr_en <= counter_wr(0) and not done_wr;
din <= counter_wr;

--rd_en <= counter_rd(0) and done_wr;
rd_en <= done_wr_dly;
checker <= '1' when (counter_rd = dout) else '0';

process(clk_counter_rd,reset_counter_rd,done_wr_dly,counter_err)
begin
if(rising_edge(clk_counter_rd)) then
    if(reset_counter_rd='1') then
        counter_err <= b"00" & x"0000";
    elsif(done_wr_dly='1' and checker = '0') then
        counter_err <= counter_err + x"1";
    end if;
 end if;
end process;

SIM_DONE <= '1' when ((done_wr_dly  = '1') and (counter_rd + x"1" = counter_wr) ) else '0';
 
STATUS <= "00000000"; -- & AND_REDUCE(counter);

srst <= RESET;  

datafifo_dcfeb_inst : datafifo_dcfeb_top 
    PORT MAP (
           WR_CLK                    => wr_clk_i,
           RD_CLK                    => rd_clk_i,
           SRST                      => srst,
           PROG_FULL                 => prog_full,
           --SLEEP                     => sleep,    
           wr_rst_busy               => wr_rst_busy,
           rd_rst_busy               => rd_rst_busy,
           WR_EN 		             => wr_en,
           RD_EN                     => rd_en,
           DIN                       => din,
           DOUT                      => dout,
           FULL                      => full,
           EMPTY                     => empty);

end Behavioral;
