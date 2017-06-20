----------------------------------------------------------------------------------
-- Company: Hoschule Bremerhaven
-- Engineer: Yarib Nevárez
-- 
-- Create Date: 21.11.2016 21:13:55
-- Design Name: ESPI
-- Module Name: espi - Behavioral
-- Revision: 2 Settle time.
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.std_logic_arith.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY espi IS
    GENERIC (DATA_LENGTH_BIT_SIZE   : INTEGER := 2;
             SETTLE_TIME_SIZE       : INTEGER := 2;
             DATA_SIZE              : INTEGER := 32;
             BAUD_RATE_DIVIDER_SIZE : INTEGER := 8);
    PORT ( clk                : IN STD_LOGIC;
           reset              : IN STD_LOGIC;
           data_length        : IN STD_LOGIC_VECTOR (DATA_LENGTH_BIT_SIZE-1 DOWNTO 0);
           baud_rate_divider  : IN STD_LOGIC_VECTOR (BAUD_RATE_DIVIDER_SIZE-1 DOWNTO 0);
           settle_time        : IN STD_LOGIC_VECTOR (SETTLE_TIME_SIZE-1 DOWNTO 0);
           clock_polarity     : IN STD_LOGIC;
           clock_phase        : IN STD_LOGIC;
           start_transmission : IN STD_LOGIC;
           transmission_done  : OUT STD_LOGIC;
           data_tx  : IN  STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0);
           data_rx  : OUT STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0) := (others => '0');
           spi_clk  : OUT STD_LOGIC;
           spi_MOSI : OUT STD_LOGIC;
           spi_MISO : IN STD_LOGIC;
           spi_cs   : OUT STD_LOGIC);
END espi;

ARCHITECTURE Behavioral OF espi IS

TYPE SPI_STATE_TYPE IS (SPI_IDLE, SPI_REDY, SPI_CLK_IDLE, SPI_CLK_ACTIVE, SPI_STOP);
SIGNAL current_state, next_state: SPI_STATE_TYPE;

SIGNAL clk_pulse : STD_LOGIC;

SIGNAL i_tx_buffer : STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0) := (others => '0');
SIGNAL i_rx_buffer : STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0) := (others => '0');
SIGNAL counter : INTEGER RANGE 0 TO DATA_SIZE-1 := 0;

CONSTANT DATA_LENGTH_0 : INTEGER := 8;
CONSTANT DATA_LENGTH_1 : INTEGER := 16;
CONSTANT DATA_LENGTH_2 : INTEGER := 24;
CONSTANT DATA_LENGTH_3 : INTEGER := 32;

--TYPE DATA_LENGTH_ARRAY IS ARRAY (3 downto 0) OF INTEGER;

--CONSTANT DATA_LENGTHS : DATA_LENGTH_ARRAY := (DATA_LENGTH_3,
--                                              DATA_LENGTH_2,
--                                              DATA_LENGTH_1,
--                                              DATA_LENGTH_0);

BEGIN

    baud_rate_division_process: PROCESS (clk, reset, baud_rate_divider, settle_time, clk_pulse)
    VARIABLE baud_rate_counter   : UNSIGNED (BAUD_RATE_DIVIDER_SIZE-1 DOWNTO 0) := (others => '0');
    VARIABLE settle_time_counter : UNSIGNED (SETTLE_TIME_SIZE-1 DOWNTO 0)       := (others => '0');
    BEGIN
        IF falling_edge(clk) THEN
            clk_pulse <= '0';
            IF reset = '1' OR current_state = SPI_IDLE THEN
                baud_rate_counter := (others => '0');
                settle_time_counter := (others => '0');
            ELSIF baud_rate_divider = CONV_STD_LOGIC_VECTOR(baud_rate_counter, BAUD_RATE_DIVIDER_SIZE) THEN
                baud_rate_counter := (others => '0');
                ----------------------------------------------------------------
                IF current_state = SPI_REDY OR current_state = SPI_STOP THEN
                    IF settle_time = CONV_STD_LOGIC_VECTOR(settle_time_counter, SETTLE_TIME_SIZE) THEN
                        clk_pulse <= '1';
                        settle_time_counter := (others => '0');
                    ELSE
                        settle_time_counter := settle_time_counter + 1;
                    END IF;
                ELSE
                    clk_pulse <= '1';
                END IF;
                ----------------------------------------------------------------
            ELSE
                baud_rate_counter := baud_rate_counter + 1;
            END IF;
        END IF;
    END PROCESS;

    spi_switch_state : PROCESS (clk, current_state, next_state)
    VARIABLE data_length_internal : UNSIGNED (1 DOWNTO 0);
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                current_state <= SPI_IDLE;
                i_tx_buffer <= (others => '0');
                i_rx_buffer <= (others => '0');
                data_rx <= (others => '0');
            ELSIF next_state = SPI_REDY THEN -- Get redy immediately
                current_state <= SPI_REDY;
                data_rx <= (others => '0');
                i_rx_buffer <= (others => '0');
                
                CASE data_length IS
                    WHEN "00" =>
                        i_tx_buffer(DATA_SIZE-1 downto DATA_SIZE-DATA_LENGTH_0) <= data_tx(DATA_LENGTH_0-1 downto 0);
                        counter <= DATA_LENGTH_0-1;
                    WHEN "01" =>
                        i_tx_buffer(DATA_SIZE-1 downto DATA_SIZE-DATA_LENGTH_1) <= data_tx(DATA_LENGTH_1-1 downto 0);
                        counter <= DATA_LENGTH_1-1;
                    WHEN "10" =>
                        i_tx_buffer(DATA_SIZE-1 downto DATA_SIZE-DATA_LENGTH_2) <= data_tx(DATA_LENGTH_2-1 downto 0);
                        counter <= DATA_LENGTH_2-1;
                    WHEN "11" =>
                        i_tx_buffer(DATA_SIZE-1 downto DATA_SIZE-DATA_LENGTH_3) <= data_tx(DATA_LENGTH_3-1 downto 0);
                        counter <= DATA_LENGTH_3-1;
                    WHEN OTHERS => NULL;
                END CASE;
            ELSIF clk_pulse = '1' THEN       -- Or Wait for the pulse
                
                IF clock_phase = '0' THEN
                    -- PUSH INPUT
                    IF next_state = SPI_CLK_ACTIVE THEN
                        i_rx_buffer <= i_rx_buffer(DATA_SIZE-2 DOWNTO 0) & spi_MISO;
                    END IF;
                    -- POP OUTPUT
                    IF next_state = SPI_CLK_IDLE THEN
                        i_tx_buffer <= i_tx_buffer(DATA_SIZE-2 downto 0) & '-';
                        counter <= counter - 1;
                    END IF;
                END IF;
                
                IF clock_phase = '1' THEN
                    -- PUSH INPUT
                    IF current_state = SPI_CLK_ACTIVE THEN
                        i_rx_buffer <= i_rx_buffer(DATA_SIZE-2 DOWNTO 0) & spi_MISO;
                    END IF;
                    -- POP OUTPUT
                    IF current_state = SPI_CLK_IDLE AND next_state = SPI_CLK_ACTIVE THEN
                        i_tx_buffer <= i_tx_buffer(DATA_SIZE-2 downto 0) & '-';
                        counter <= counter - 1;
                    END IF;
                END IF;
                
                IF current_state = SPI_STOP THEN
                    data_rx <= i_rx_buffer;
                END IF;
                
                current_state <= next_state;
            END IF;
        END IF;
    END PROCESS;
    
    
    spi_mechanism :  process (next_state, clock_polarity, current_state, start_transmission, i_tx_buffer, clock_phase, counter)
    BEGIN
        next_state <= current_state;
        spi_clk <= clock_polarity;
        spi_cs <= '1';
        spi_MOSI <= '0';
        transmission_done <= '1';

        CASE current_state IS
            WHEN SPI_IDLE =>
                IF start_transmission = '1' THEN
                    next_state <= SPI_REDY;
                END IF;
            WHEN SPI_REDY =>
                spi_cs <= '0';
                transmission_done <= '0';
                IF clock_phase = '0' THEN
                    spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                END IF;
                next_state <= SPI_CLK_ACTIVE;
            WHEN SPI_CLK_ACTIVE =>
                spi_cs <= '0';
                transmission_done <= '0';
                spi_clk <= NOT clock_polarity;
                spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                IF counter = 0 THEN
                    next_state <= SPI_STOP;
                ELSE
                    next_state <= SPI_CLK_IDLE;
                END IF;
            WHEN SPI_CLK_IDLE =>
                spi_cs <= '0';
                transmission_done <= '0';
                spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                IF counter = 0 AND clock_phase = '1' THEN
                    next_state <= SPI_STOP;
                ELSE
                    next_state <= SPI_CLK_ACTIVE;
                END IF;
            WHEN SPI_STOP =>
                IF clock_phase = '1' THEN
                    spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                END IF;
                next_state <= SPI_IDLE;
                transmission_done <= '0';
                spi_cs <= '0';
        END CASE;
    END PROCESS;

END Behavioral;
