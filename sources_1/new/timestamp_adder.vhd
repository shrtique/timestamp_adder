----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.07.2018 17:40:33
-- Design Name: 
-- Module Name: timestamp_adder - Behavioral
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

entity timestamp_adder is

	Generic (
                
				--NOF_pixels  : integer := 10;    -- pixels per line
                --NOF_lines   : integer := 10;    -- lines per frame
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
end timestamp_adder;

architecture Behavioral of timestamp_adder is

	signal timestamp_local_reg : std_logic_vector(31 downto 0);
	signal timestamp_flag : std_logic;

	signal byte_counter : integer range 0 to 4;

begin

process (clk, aresetn)
begin
    if (aresetn = '0') then
        s_axis_video_tready <= '0';	
    elsif ( rising_edge(clk) )	 then
        s_axis_video_tready <= '1';	
    end if;	
end process;	
 
 -------------------------------------	

MAIN_PROC : process (clk, aresetn)
begin

	if (aresetn = '0') then

		m_axis_video_tdata   <= (others =>'0');
        m_axis_video_tvalid  <= '0';
        m_axis_video_tlast   <= '0';
        m_axis_video_tuser   <= '0';



	elsif (rising_edge(clk)) then

		if (m_axis_video_tready = '1') then

			m_axis_video_tdata   <= s_axis_video_tdata;
	        m_axis_video_tvalid  <= s_axis_video_tvalid;
	        m_axis_video_tlast   <= s_axis_video_tlast;
	        m_axis_video_tuser   <= s_axis_video_tuser;	

			if (s_axis_video_tuser = '1' OR timestamp_flag = '1') then

				if (s_axis_video_tvalid = '1') then

					m_axis_video_tdata <= timestamp_local_reg ((byte_counter * 8) - 1 downto (byte_counter - 1)*8);

				end if;

			end if;

		end if;	

	end if;	

end process MAIN_PROC; 

--ПРОЦЕСС, который будет захватывать таймстемп и будет его обновлять только по тюзеру--
--проблема в том, что таймстемп будет на момент передачи кадра в DDR, а не на момент его физического захвата: ->
--> задержка ядра питона + задержка пайплайна фильтров

--Как вариант - поставить фифо, в который будем писать в момент захвата кадра, а считывать,
-- когда сигнал будет готов для отправки в DDR

byte_counter_proc : process (clk, aresetn)
begin

	if (aresetn = '0') then
		byte_counter <= 1;
		timestamp_flag <= '0';
	elsif (rising_edge(clk)) then

		if (s_axis_video_tuser = '1' OR timestamp_flag = '1') then

			if (s_axis_video_tvalid = '1') then

				byte_counter <= byte_counter + 1;
				timestamp_flag <= '1';

				if (byte_counter = 4) then
					byte_counter <= 1;
					timestamp_flag <= '0';
				end if;	

			end if;

		end if;

	end if;

end process byte_counter_proc;	





timestamp_ff : process (clk, aresetn)
begin
	if (aresetn = '0') then

		timestamp_local_reg <= (others => '0');

	elsif (rising_edge(clk)) then

		timestamp_local_reg <= timestamp_input;

	end if;	

end process timestamp_ff;	

end Behavioral;
