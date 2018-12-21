----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.07.2018 13:34:02
-- Design Name: 
-- Module Name: tb_timestamp_adder - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity tb_timestamp_adder is
--  Port ( );
end tb_timestamp_adder;

architecture Behavioral of tb_timestamp_adder is


	COMPONENT timestamp_adder is

		Generic (
	                
					NOF_pixels  : integer := 10;    -- pixels per line
	                NOF_lines   : integer := 10;    -- lines per frame
	                DATA_WIDTH  : integer := 8     -- pixel resolution -bits
	    );
	             
	    Port    ( 
	                clk                  : in STD_LOGIC; -- clk for s_axis and m_axis
	                aresetn              : in std_logic; -- reset_N
	                
	                --Input Stream--
	                s_axis_video_tdata   : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
	                s_axis_video_tvalid  : in STD_LOGIC;
	                s_axis_video_tlast   : in STD_LOGIC;
	                s_axis_video_tuser   : in STD_LOGIC;
	                s_axis_video_tready  : out STD_LOGIC;
	                ----------------
					
	                --Output Stream--
	                m_axis_video_tdata   : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
	                m_axis_video_tvalid  : out STD_LOGIC;
	                m_axis_video_tlast   : out STD_LOGIC;
	                m_axis_video_tuser   : out STD_LOGIC;
	                m_axis_video_tready  : in  STD_LOGIC;
					-----------------
					timestamp_input 	 : in std_logic_vector(31 downto 0)	
	    );			-----------------
	end COMPONENT;

	--SIGNALS--	
   signal MAIN_CLK : std_logic := '1';
   signal TUSER, TLAST, TVALID : std_logic := '0';
   signal rg_TUSER, rg_TLAST, rg_TVALID : std_logic := '0';
   signal DATA_IN  : STD_LOGIC_VECTOR (7 downto 0) := X"01";
   signal rg_DATA_IN  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   signal RESETN : std_logic := '0';
    
    
    constant clock_period : time := 10 ns;
    
    constant NOF_pixels : integer := 16;
    constant NOF_lines  : integer := 16;
	constant AXI_LITE_DATA_WIDTH : integer := 32;
	constant NOF_ticks_between_frames : integer := 50;
	

	signal IMAGE_VALID : std_logic := '0';	
	signal new_frame_flag : std_logic := '1';
	signal end_frame_flag : std_logic := '0';	
	signal new_line_flag : std_logic := '1';
	signal start_ticks_flag : std_logic := '0';
	signal pixel_counter : integer := 0;
	signal line_counter : integer := 0;
	signal ticks_counter : integer := 0;
	signal FRAME_COUNTER : integer := 0;

	signal timestamp_counter : std_logic_vector(31 downto 0) := (others => '0');	


begin


	    UUT: timestamp_adder 
    
	    GENERIC MAP (
	                       
						NOF_pixels  => NOF_pixels,    -- pixels per line
	                    NOF_lines   => NOF_lines,    -- lines per frame
	                    DATA_WIDTH  => 8     -- pixel resolution -bits
	    )
	    
	    PORT MAP (
	    
	                    clk     => MAIN_CLK,
	                    --aclken  => '1',
	                    aresetn => RESETN,
	                    
	                    
	                    s_axis_video_tdata   => rg_DATA_IN,
	                    s_axis_video_tvalid  => rg_TVALID,
	                    s_axis_video_tlast   => rg_TLAST,
	                    s_axis_video_tuser   => rg_TUSER,
	                    s_axis_video_tready  => open,
	                    
	                    m_axis_video_tdata   => open,
	                    m_axis_video_tvalid  => open,
	                    m_axis_video_tlast   => open,
	                    m_axis_video_tuser   => open,
	                    m_axis_video_tready  => '1',
	                    
	                    timestamp_input => timestamp_counter
	    );



timestamp_counter <= X"00000001" after 1000*1000 ns, X"00000002" after 2000*1000 ns, X"00000003" after 3000*1000 ns,
					 X"00000004" after 4000*1000 ns, X"00000005" after 5000*1000 ns;






---------------------------------
registering : process (MAIN_CLK)
begin 
if (rising_edge(MAIN_CLK)) then
    if (RESETN = '0') then
        
        rg_DATA_IN <= (others => '0');
        rg_TVALID <= '0';
        rg_TLAST <= '0';
        rg_TUSER <= '0';
    else
        rg_DATA_IN <= DATA_IN;
        rg_TVALID <= TVALID;
        rg_TLAST <= TLAST;
        rg_TUSER <= TUSER;
    end if;    
end if;
end process registering;
--------------------------------- 

---------------------------------

---------------------------------   

---------------------------------
TVALID_proc : process (MAIN_CLK)
begin
if (rising_edge(MAIN_CLK)) then
    if (RESETN = '0') then    
        TVALID <= '0';    
    else
        
		if (IMAGE_VALID = '1') then
			TVALID <= '1';
		else
			TVALID <= '0';
		end if;
		
		if (end_FRAME_flag = '1') then
			TVALID <= '0';
		end if;

    end if;    
end if;
end process TVALID_proc;
---------------------------------

---------------------------------
TUSER_proc : process (MAIN_CLK)
begin
if (rising_edge(MAIN_CLK)) then
    if (RESETN = '0') then    
        TUSER <= '0';    
    else
        
		if (IMAGE_VALID = '1') then
			if (new_FRAME_flag = '1') then
				TUSER <= '1';
			else
				TUSER <= '0';
			end if;
		end if;
    end if;    
end if;
end process TUSER_proc;
---------------------------------

---------------------------------
TLAST_proc : process (MAIN_CLK)
begin
if (rising_edge(MAIN_CLK)) then
    if (RESETN = '0') then    
        TLAST <= '0';    
    else
        
		if (IMAGE_VALID = '1') then
			if (PIXEL_COUNTER = NOF_pixels - 1 ) then
				TLAST <= '1';
			else
				TLAST <= '0';
			end if;
		end if;
    end if;    
end if;
end process TLAST_proc;
---------------------------------

---------------------------------
PIXEL_COUNTER_proc : process (MAIN_CLK)
begin
if (rising_edge(MAIN_CLK)) then
    if (RESETN = '0') then    
        PIXEL_COUNTER <= 0;
		new_LINE_flag <= '1';	
    else
    
		if (IMAGE_VALID = '1') then
		
			PIXEL_COUNTER <= PIXEL_COUNTER + 1;
			new_LINE_flag <= '0';

			if (PIXEL_COUNTER = NOF_pixels ) then
				PIXEL_COUNTER <= 1;
				new_LINE_flag <= '1';	
			end if;
		end if;	
		
		if (end_FRAME_flag = '1' ) then
            PIXEL_COUNTER <= 0;
        end if; 
		

    end if;    
end if;
end process PIXEL_COUNTER_proc;
---------------------------------

---------------------------------
LINE_COUNTER_proc : process (MAIN_CLK)
begin
if (rising_edge(MAIN_CLK)) then
    if (RESETN = '0') then    
        LINE_COUNTER <= 0;
		end_FRAME_flag <= '0';	
		FRAME_COUNTER <= 0;
    else
        
		if (IMAGE_VALID = '1') then
		
			if (new_LINE_flag = '1') then
				LINE_COUNTER <= LINE_COUNTER + 1;
			end if;
		
			if ((LINE_COUNTER = NOF_lines ) AND (PIXEL_COUNTER = NOF_pixels)) then
				LINE_COUNTER <= 0;
			end if;
			
			if ((LINE_COUNTER = NOF_lines) AND (PIXEL_COUNTER = NOF_pixels - 1)) then
				end_FRAME_flag <= '1';
				FRAME_COUNTER <= FRAME_COUNTER + 1;
			else
				end_FRAME_flag <= '0';
			end if;	
			
		end if;	

    end if;    
end if;
end process LINE_COUNTER_proc;
---------------------------------

---------------------------------    
MAIN_CLK <= not MAIN_CLK after 5 ns;  
RESETN <= '1' after 1480 ns;   
---------------------------------

DATA_IN_proc : process (MAIN_CLK)
variable data_var : integer := 0;
begin
if (rising_edge(MAIN_CLK)) then
    if (RESETN = '0') then    
        DATA_IN (7 downto 1) <= (others => '0');
        DATA_IN (0) <= '1';
		data_var := 1;	
    else
        
		if (IMAGE_VALID = '1') then
			data_var := data_var + 1;
			DATA_IN <= (std_logic_vector (to_unsigned(data_var, 8)));
		end if;	

    end if;    
end if;
end process DATA_IN_proc;


IMAGE_VALID_proc : process (MAIN_CLK)
begin

if (rising_edge(MAIN_CLK)) then
	if (RESETN = '0') then
		IMAGE_VALID <= '0';
		ticks_counter <= 0;
		new_FRAME_flag <= '1';
	else
		
		if (new_FRAME_flag = '1') then
		
			if (IMAGE_VALID <= '0') then
			
				IMAGE_VALID <= '1';
				
			elsif (IMAGE_VALID <= '1') then
			
				new_FRAME_flag <= '0';
			end if;

		end if; 
		
		
		
		if (end_FRAME_flag = '1') then
			--ticks_counter <= ticks_counter + 1;
			start_ticks_flag <= '1';
			IMAGE_VALID <= '0';
		end if;
		
		if (start_ticks_flag = '1' AND FRAME_COUNTER > 0) then
		    ticks_counter <= ticks_counter + 1;
		end if;
		
		if (ticks_counter = NOF_ticks_between_frames ) then
			ticks_counter <= 0;
			new_FRAME_flag <= '1';
			start_ticks_flag <= '0';
		end if;
		
		
		
	end if;
end if;

end process IMAGE_VALID_proc;




end Behavioral;
