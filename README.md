# Enhanced SPI VHDL

The communication between the Zynq device and the external devices is established by using SPI protocol. Inside the custom IPs (AXI peripherals) it is instantiated an Enhanced SPI which was designed with the following features.
Baud rate divider for output clock signal (SCLK)
Configurable data length (8, 16, 24 and 32 bits)
Flexible Settle-time for specific devices
Configurable clock polarity (CPOL) and clock phase (CPHA).
Full duplex data transmission.

The implemented VHDL code for the Enhanced SPI is listed below.

```VHDL
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
```

The baud rate divider is implemented in the following process.

```VHDL
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
```

The mechanism for switching from states (SPI as state machine) is implemented in the following process. This process determine the number of bits that should be transmitted-received based on the selected data length, the shifting data in the internal buffers, and the setup for the next state.


```VHDL
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
```

The SPI state-machine is implemented in the following process.

```VHDL
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
```

# VHDL Simulation

For the simulation it was instantiated an Enhanced SPI, it was connected MOSI and MISO lines so the given value in the data_tx register appears in data_rx register after the transmission (full duplex).

* data_length, set to two so 24 bits will be transmitted
* settle_time, set to three to start the transmission after four clock cycles (40ns)
* baud_rate_divider, set to zero for no clock division (full speed)
* clock_polarity, set to one making high the idle state of the output clock signal
* clock_phase, set to zero in order to start the transmission with no phase delay

The data to be transmitted is set to the data_tx register (32 bits), in this simulation it set to a51188a5, since the data length was setup for having a transmission of 24 bits (8 bytes) and MOSI and MISO lines are connected, the received data in data_rx is 001188a5 (24 bits) after 24 clock cycles.
For more detailed information regarding the SPI protocol it can be referred to the documentation of standardized SPI protocol.
