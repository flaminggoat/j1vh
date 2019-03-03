library ieee;
use ieee.std_logic_1164.all;

entity tb_j1vh is
end tb_j1vh;

architecture tb of tb_j1vh is

    constant data_size : natural := 16;

    signal sys_clk_i : std_logic;
    signal sys_rst_i : std_logic;
    signal io_din    : std_logic_vector (data_size - 1 downto 0);
    signal io_rd     : std_logic;
    signal io_wr     : std_logic;
    signal io_dout   : std_logic_vector (data_size - 1 downto 0);
    signal io_addr   : std_logic_vector (data_size - 1 downto 0);

    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : entity work.j1vh
    generic map (data_size => data_size)
    port map (sys_clk_i => sys_clk_i,
              sys_rst_i => sys_rst_i,
              io_din    => io_din,
              io_rd     => io_rd,
              io_wr     => io_wr,
              io_dout   => io_dout,
              io_addr   => io_addr);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that sys_clk_i is really your main clock signal
    sys_clk_i <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        io_din <= (others => '0');

        -- Reset generation
        -- EDIT: Check that sys_rst_i is really your reset signal
        sys_rst_i <= '1';
        wait for 20 ns;
        sys_rst_i <= '0';


        -- EDIT Add stimuli here
        wait for 100000 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;