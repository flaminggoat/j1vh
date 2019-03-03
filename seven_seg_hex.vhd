library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_seg_display is
	port(
		clk : in std_logic;
        wr : in std_logic;
        addr : in std_logic_vector(1 downto 0);
		data : in std_logic_vector(6 downto 0);
		segments : out std_logic_vector(6 downto 0);
		cathodes : out std_logic_vector(3 downto 0)
	);
end seven_seg_display;

architecture behavioral of seven_seg_display is
	signal cathode_sig : std_logic_vector(3 downto 0) := "1110";
	signal digit : std_logic_vector(3 downto 0);
	signal divider : unsigned(7 downto 0) := (others => '0');
    signal digit0, digit1, digit2, digit3 : std_logic_vector(6 downto 0);
begin

    registers : process(clk)
    begin
        if rising_edge(clk) then
            if wr = '1' then
                if addr = "00" then
                    digit0 <= data;
                elsif addr = "01" then 
                    digit1 <= data;
                elsif addr = "10" then
                    digit2 <= data;
                elsif addr = "11" then
                    digit3 <= data;
                end if;
            end if;
        end if;
    end process;

	multiplex : process(clk)
	begin
		if rising_edge(clk) then
			divider <= divider + 1;
			if(divider = 255) then
				cathode_sig <= cathode_sig(2 downto 0) & cathode_sig(3);
			end if;
		end if;
	end process;
	
	cathodes <= cathode_sig;
	
	with cathode_sig select
		segments <= digit0 when "1110",
					digit1 when "1101",
					digit2 when "1011",
					digit3 when others;
		
end behavioral;

