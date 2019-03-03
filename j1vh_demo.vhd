library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_MISC.ALL;
use IEEE.NUMERIC_STD.ALL;

entity j1vh_demo is
    Port (
        clk : in std_logic;
        nrst : in std_logic;
        segments : out std_logic_vector(6 downto 0);
		cathodes : out std_logic_vector(3 downto 0)
    );
end j1vh_demo;

architecture behavioral of j1vh_demo is
	signal data, addr : std_logic_vector(15 downto 0);
    signal io_rd, io_wr, reset : std_logic;
begin
    sevenseg: entity work.seven_seg_display
    port map(
        clk => clk,
        wr => io_wr,
        addr => addr(1 downto 0),
		data => data(6 downto 0),
		segments => segments,
		cathodes => cathodes);
        
    j1: entity work.j1vh
    generic map(data_size => 16)
    port map(   
        sys_clk_i => clk,
        sys_rst_i => reset,
        io_din => (others => '0'),
        io_rd => io_rd,
        io_wr => io_wr,
        io_dout => data,
        io_addr => addr);
		
    reset <= not nrst;
    
end behavioral;
