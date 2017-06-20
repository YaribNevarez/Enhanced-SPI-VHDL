----------------------------------------------------------------------------------
-- Company: Hoschule Bremerhaven
-- Engineer: Yarib Nevárez
-- 
-- Create Date: 24.11.2016 17:20:04
-- Design Name: SPI TEST SIMULATION
-- Module Name: spi_tb - Behavioral
-- Project Name: Pulse oximeter
-- Description: configurable SPI test bench
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

entity spi_tb is
--  Port ( );
end spi_tb;

architecture Behavioral of spi_tb is

COMPONENT spi IS
    PORT ( clk                : IN STD_LOGIC;
           reset              : IN STD_LOGIC;
           data_length        : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
           baud_rate_divider  : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
           settle_time        : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
           clock_polarity     : IN STD_LOGIC;
           clock_phase        : IN STD_LOGIC;
           start_transmission : IN STD_LOGIC;
           transmission_done  : OUT STD_LOGIC;
           data_tx  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
           data_rx  : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
           spi_clk  : OUT STD_LOGIC;
           spi_MOSI : OUT STD_LOGIC;
           spi_MISO : IN STD_LOGIC;
           spi_cs   : OUT STD_LOGIC);
END COMPONENT spi;

SIGNAL clk                : STD_LOGIC := '0';
SIGNAL reset              : STD_LOGIC := '0';
SIGNAL data_length        : STD_LOGIC_VECTOR (1 DOWNTO 0) := (others => '0');
SIGNAL baud_rate_divider  : STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
SIGNAL settle_time        : STD_LOGIC_VECTOR (1 DOWNTO 0) := (others => '0');
SIGNAL clock_polarity     : STD_LOGIC := '0';
SIGNAL clock_phase        : STD_LOGIC := '0';
SIGNAL start_transmission : STD_LOGIC := '0';
SIGNAL transmission_done  : STD_LOGIC := '0';
SIGNAL data_tx  : STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
SIGNAL data_rx  : STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
SIGNAL spi_clk  : STD_LOGIC := '0';
SIGNAL spi_data : STD_LOGIC := '0';
SIGNAL spi_cs   : STD_LOGIC := '0';

CONSTANT clock_period : time := 10ns;

begin

    uut : spi PORT MAP (
           clk => clk,
           reset => reset,
           data_length => data_length,
           baud_rate_divider => baud_rate_divider,
           settle_time => settle_time,
           clock_polarity => clock_polarity,
           clock_phase => clock_phase,
           start_transmission => start_transmission,
           transmission_done => transmission_done,
           data_tx => data_tx,
           data_rx => data_rx,
           spi_clk => spi_clk,
           spi_MOSI => spi_data,
           spi_MISO => spi_data,
           spi_cs => spi_cs);   
           
               -- Process to generate the clock
           clk_p : PROCESS
           BEGIN
               clk <= '0';
               wait for clock_period / 2;
               clk <= '1';
               wait for clock_period / 2;
           END PROCESS clk_p;
           
           main_test : PROCESS
           BEGIN
           wait for clock_period;
           reset <= '1';
           wait for clock_period;
           reset <= '0';
           wait for clock_period;
        ------- TEST DATA ---------
            data_tx <= x"A51188A5";
        ------- TEST 1 Byte ---------
            data_length <= "00";
            baud_rate_divider <= x"00";
            settle_time <= "11";
        ------- CPOL=0 CPHA=0 ---------
           clock_polarity <= '0';
           clock_phase <= '0';
           wait for clock_period;
           start_transmission <= '1';
           wait for clock_period;
           start_transmission <= '0';
           wait for 40*clock_period;
           
        ------- CPOL=0 CPHA=1 ---------
           clock_polarity <= '0';
           clock_phase <= '1';
           wait for clock_period;
           start_transmission <= '1';
           wait for clock_period;
           start_transmission <= '0';
           wait for 40*clock_period;

        ------- CPOL=1 CPHA=0 ---------
           clock_polarity <= '1';
           clock_phase <= '0';
           wait for clock_period;
           start_transmission <= '1';
           wait for clock_period;
           start_transmission <= '0';
           wait for 40*clock_period;
           
        ------- CPOL=1 CPHA=1 ---------
          clock_polarity <= '1';
          clock_phase <= '1';
          wait for clock_period;
          start_transmission <= '1';
          wait for clock_period;
          start_transmission <= '0';
          wait for 40*clock_period;
          
          
          ------- TEST 2 Bytes ---------
              data_length <= "01";
              baud_rate_divider <= x"01";
          ------- CPOL=0 CPHA=0 ---------
             clock_polarity <= '0';
             clock_phase <= '0';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 80*clock_period;
             
          ------- CPOL=0 CPHA=1 ---------
             clock_polarity <= '0';
             clock_phase <= '1';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 80*clock_period;
  
          ------- CPOL=1 CPHA=0 ---------
             clock_polarity <= '1';
             clock_phase <= '0';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 80*clock_period;
             
          ------- CPOL=1 CPHA=1 ---------
            clock_polarity <= '1';
            clock_phase <= '1';
            wait for clock_period;
            start_transmission <= '1';
            wait for clock_period;
            start_transmission <= '0';
            wait for 80*clock_period;

         
          ------- TEST 3 Bytes ---------
              data_length <= "10";
              baud_rate_divider <= x"00";
          ------- CPOL=0 CPHA=0 ---------
             clock_polarity <= '0';
             clock_phase <= '0';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 60*clock_period;
             
          ------- CPOL=0 CPHA=1 ---------
             clock_polarity <= '0';
             clock_phase <= '1';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 60*clock_period;
  
          ------- CPOL=1 CPHA=0 ---------
             clock_polarity <= '1';
             clock_phase <= '0';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 60*clock_period;
             
          ------- CPOL=1 CPHA=1 ---------
            clock_polarity <= '1';
            clock_phase <= '1';
            wait for clock_period;
            start_transmission <= '1';
            wait for clock_period;
            start_transmission <= '0';
            wait for 60*clock_period;


         
          ------- TEST 4 Bytes ---------
              data_length <= "11";
              baud_rate_divider <= x"00";
          ------- CPOL=0 CPHA=0 ---------
             clock_polarity <= '0';
             clock_phase <= '0';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 80*clock_period;
             
          ------- CPOL=0 CPHA=1 ---------
             clock_polarity <= '0';
             clock_phase <= '1';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 80*clock_period;
  
          ------- CPOL=1 CPHA=0 ---------
             clock_polarity <= '1';
             clock_phase <= '0';
             wait for clock_period;
             start_transmission <= '1';
             wait for clock_period;
             start_transmission <= '0';
             wait for 80*clock_period;
             
          ------- CPOL=1 CPHA=1 ---------
            clock_polarity <= '1';
            clock_phase <= '1';
            wait for clock_period;
            start_transmission <= '1';
            wait for clock_period;
            start_transmission <= '0';
            wait for 80*clock_period;    
           wait;
           END PROCESS;

end Behavioral;
