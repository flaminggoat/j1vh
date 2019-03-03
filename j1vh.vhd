library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_MISC.ALL;
use IEEE.NUMERIC_STD.ALL;

entity j1vh is
    Generic (data_size : natural := 16);
    Port (
        sys_clk_i : in std_logic;
        sys_rst_i : in std_logic;
        io_din : in std_logic_vector (data_size - 1 downto 0);
        io_rd : out std_logic;
        io_wr : out std_logic;
        io_dout : out std_logic_vector (data_size - 1 downto 0);
        io_addr : out std_logic_vector (data_size - 1 downto 0)
    );
end j1vh;

architecture behav of j1vh is

    type stack is array (31 downto 0) of unsigned (data_size - 1 downto 0);
    signal dstack : stack;
    signal rstack : stack;

    signal dsp, n_dsp, rsp, n_rsp : unsigned(4 downto 0); -- Data stack pointer, return stack pointer
    signal n_dstkW, n_rstkW : std_logic; -- data stack write , return stack write
    
    signal insn, immediate, ramrd, st0, n_st0, st1, rst0, n_rstkD, alu_out, alu_load: unsigned(15 downto 0);
    
    signal pc, n_pc, pc_plus_1 : unsigned(12 downto 0);
    
    signal st0sel : unsigned(3 downto 0);
    
    signal n_ramWE, n_st0_in_ram : std_logic;
    
    signal alu_equal, alu_lt, alu_ltu, is_alu, is_lit, is_branching : std_logic;
    
    signal dd, rd : unsigned(1 downto 0);
        
begin

    immediate <= '0' & insn(14 downto 0);
    
    pc_plus_1 <= pc + 1;
    
    st1 <= dstack(to_integer(dsp));
    rst0 <= rstack(to_integer(rsp));

    stack_proc : process(sys_clk_i)
    begin
        if(rising_edge(sys_clk_i)) then
            if(n_dstkW = '1') then
                dstack(to_integer(n_dsp)) <= st0;
            end if;
            if(n_rstkW = '1') then
                rstack(to_integer(n_rsp)) <= n_rstkD;
            end if;
        end if;
    end process;
    
    with insn(14 downto 13) select st0sel <=
        "0000"     when "00",  -- ubranch
        "0000"     when "10",  -- call
        "0001"     when "01",  -- 0branch
        insn(11 downto 8) when "11",  -- ALU
        "XXXX"     when others;
        
    n_st0_in_ram <= '1' when n_st0(15 downto 13) = "000" else '0';

    RAM: entity work.dual_port_ram
    port map(address_a => std_logic_vector(n_pc),
        address_b => std_logic_vector(n_st0(12 downto 0)),
        clock => sys_clk_i,
        data_a => (others => '0'),
        data_b => std_logic_vector(st1(15 downto 0)),
        rden_a => '1',
        rden_b => n_st0_in_ram,
        wren_a => '0',
        wren_b => n_ramWE and n_st0_in_ram,
        unsigned(q_a) => insn,
        unsigned(q_b) => ramrd);
        
    alu_equal <= '1' when st1 = st0 else '0';
    alu_lt <= '1' when signed(st1) < signed(st0) else '0';
    alu_ltu <= '1' when st1 < st0 else '0';
    alu_load <= ramrd when st0(15 downto 13) = "000" else unsigned(io_din);
    
    with st0sel select alu_out <=
        st0                     when "0000",
        st1                     when "0001",
        st0 + st1               when "0010",
        st0 and st1             when "0011",
        st0 or st1              when "0100",
        st0 xor st1             when "0101",
        not st0                 when "0110",
        (others => alu_equal)   when "0111",
        (others => alu_lt)      when "1000",
        shift_right(st1, to_integer(st0(3 downto 0))) when "1001",
        st0 - 1                 when "1010", -- sub 1
        rst0                    when "1011", -- return stack
        alu_load                when "1100",
        shift_left(st1, to_integer(st0(3 downto 0))) when "1101",
        "000" & rsp & "000" & dsp       when "1110",
        (others => alu_ltu)     when "1111",
        (others => 'X')         when others;
        
    n_st0 <= immediate when insn(15) = '1' else alu_out;
    
    is_alu <= '1' when insn(15 downto 13) = "011" else '0';
    is_lit <= insn(15);

    io_rd <= '1' when (is_alu = '1' and (insn(11 downto 8) = "1100")) else '0';
    io_wr <= n_ramWE;
    io_addr <= std_logic_vector(st0);
    io_dout <= std_logic_vector(st1);
    
    n_ramWE <= is_alu and insn(5); -- store
    n_dstkW <= is_lit or (is_alu and insn(7));  -- data stack write
    
    dd <= insn(1 downto 0); -- data stack delta
    rd <= insn(3 downto 2); -- return stack delta
    
    n_dsp <= dsp + 1 when is_lit = '1' else
            dsp + (dd(1) & dd(1) & dd(1) & dd) when is_alu = '1' else -- add sign extended stack delta
            dsp - 1 when insn(15 downto 13) = "001" else -- predicted jump is like drop
            dsp;
            
    n_rsp <= rsp when is_lit = '1' else
            rsp + (rd(1) & rd(1) & rd(1) & rd) when is_alu = '1' else -- add sign extended stack delta
            rsp + 1 when insn(15 downto 13) = "010" else -- call
            rsp;
            
    n_rstkW <= '0' when is_lit = '1' else
              insn(6) when is_alu = '1' else
              '1' when insn(15 downto 13) = "010" else -- call
              '0';

    n_rstkD <= "000" & n_pc when is_lit = '1' else
              st0 when is_alu = '1' else
              ("00" & pc_plus_1 & '0') when insn(15 downto 13) = "010" else -- call
              "000" & n_pc;
              
    is_branching <= '1' when ((insn(15 downto 13) = "000") or 
        ((insn(15 downto 13) = "001") and (st0 = 0)) or 
        (insn(15 downto 13) = "010")) else '0';

    n_pc <= pc when sys_rst_i = '1' else
        insn(12 downto 0) when is_branching = '1' else
        rst0(13 downto 1) when (is_alu = '1' and insn(12) = '1') else -- why the offest
        pc_plus_1;
           
    main_proc : process(sys_clk_i)
    begin
        if(rising_edge(sys_clk_i)) then
            if(sys_rst_i = '1') then
                pc <= (others => '0');
                dsp <= (others => '0');
                st0 <= (others => '0');
                rsp <= (others => '0');
            else
                dsp <= n_dsp;
                pc <= n_pc;
                st0 <= n_st0;
                rsp <= n_rsp;
            end if;
        end if;
    end process;
        
end architecture;