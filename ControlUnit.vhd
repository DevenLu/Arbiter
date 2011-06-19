----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:49:39 06/04/2011 
-- Design Name: 
-- Module Name:    ControlUnit - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.router_library.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ControlUnit is
	generic(rsv_size		: natural;
			  word_size 	: natural;
			  address_size	: natural);
	port(
			clk				   : in std_logic;
			rst					: in std_logic;
			ram_data_in			: in std_logic_vector (word_size-1 downto 0);
			ram_data_out		: out std_logic_vector (word_size-1 downto 0);
			sch_data_in			: in std_logic_vector(address_size-1 downto 0);
			sch_data_out		: out std_logic_vector(address_size-1 downto 0);
			address				: out std_logic_vector (address_size-1 downto 0);
			rw						: out std_logic;
			ram_en				: out std_logic;
			sch_en				: out std_logic;
			n_CTRflg				: out std_logic;
			n_CtrlFlg			: in std_logic;
			n_rnaCtrl			: in std_logic_vector(rsv_size-1 downto 0);
			rna_ctrlPkt			: out std_logic_vector(rsv_size-1 downto 0)
		);
end ControlUnit;

architecture Behavioral of ControlUnit is
	signal control_pkt : std_logic_vector(rsv_size-1 downto 0);
	signal slot : 			std_logic_vector(2 downto 0) := "000";
	signal timeunit :		std_logic_vector(15 downto 0) := "0000000000000000";
	signal counter :		std_logic_vector(15 downto 0) := "0000000000000000";
	signal start : 		std_logic := '0';
	signal w_address 		: std_logic_vector(address_size-1 downto 0) := "0000";
	signal r_address		: std_logic_vector(address_size-1 downto 0) := "0000";
	signal reserved_cnt	: std_logic_vector(address_size-1 downto 0) := "0000";
	signal table_full 	: std_logic := '0';

begin

	--reset_process:		Creates a component reset of all signals
	reset_process: process
	begin
		wait until rst'event and rst = '1';
			--slot <= "000" after 1 ns;
			--nxt_addr <= "0000" after 1 ns;
			--counter <= "00000000" after 1 ns;
			--unit <= "00000000" after 1 ns;
			start <= '1' after 1 ns;
	end process;

	--timebase_process: 	Creates a "stopwatch" for establishing a timebase that
	--							the packet transfers process requires to ensure QoS.
	timebase_process: process
	begin
		wait until clk'event and clk = '1';
			if(start = '1') then
				timeunit <= timeunit + "0000000000000001";
				if(timeunit = "000000111110") then				-- 1000 cycles
					counter <= counter + "0000000000000001";			--increment the counter by 1 tick
				end if;
			end if;
	end process;

--	--scheduler_process: 	Creates the time slot alloted to a process (below)
--	--								to execute critical code that must be mutually
--	--								exclusive.
--	scheduler_process: process
--	begin
--		wait until clk'event and clk = '1';
--			if(unit = "11111111") then
--				if(slot = "100") then
--					slot <= "000" after 1 ns;					--reset
--				else
--					slot <= slot + 1 after 1 ns;				--increment the slot (time expired on current slot)
--				end if;
--			else
--				unit <= unit + 1 after 1 ns;
--			end if;
--	end process;
--	
--	--controlpacketNorth_process:	This process is responsible for control packets
--	--										sent in by the FCU from the north port
--		
	controlpacketNorth_process: process
	begin
		wait until clk'event and clk = '1';
		if(n_CtrlFlg = '1' and table_full = '0') then
			--Write to RsvTable
				n_CTRflg <= '1';
				address <= w_address;
				sch_data_out <= n_rnaCtrl(3 downto 0);
				rw <= '1';
				sch_en <= '1';
				ram_data_out <= n_rnaCtrl(19 downto 4);
				ram_en <= '1';
				rw <= '1';
				n_CTRflg <= '0';
				if(reserved_cnt < "1111") then
					w_address <= w_address + 1;
					reserved_cnt <= reserved_cnt + 1;
				else
					table_full <= '1';
				end if;
				ram_en <= '0' after 10 ns;
				sch_en <= '0' after 10 ns;
		elsif(n_CtrlFlg = '1' and table_full = '1') then
				table_full <= '1';
		end if;
	end process;
	
--	controlpacketExecute_process: process
--	begin
--		wait until clk'event and clk = '1';
--		if(n_CtrlFlg = '0') then	
--			address <= nxt_addr after 1 ns;
--			rw = '1';
--			control_pkt <= data_in after 1 ns;
--		end if;
--	end process;
	
--	generateControlPacket_process: process
--	begin
--		wait until clk'event and clk = '1';
--		if(slot = "001") then
--			address <= nxt_addr after 1 ns;
--			rw <= '0' after 1 ns;
--			rna_ctrlPkt <= data_in after 1 ns;
--		end if;
--	end process;
--			
			
--	
--	--controlpacketEast_process:	This process is responsible for control packets
--	--										sent in by the FCU from the east port
--	controlpacketEast_process: process(e_CtrlFlg)
--	begin
--		if(e_CtrlFlg'event and e_CtrlFlg = '1') then
--			--Grab packet from FCU
--			packetE <= e_rnaCtrl after 20 ns;
--			e_CTRflg <= '1' after 30 ns;
--			e_CTRflg <= '0' after 50 ns;
--			--Grab Lock
--			--Write to RsvTable
--			--Release Lock
--		end if;
--	end process;
--	
--	--controlpacketSouth_process:	This process is responsible for control packets
--	--										sent in by the FCU from the south port
--	controlpacketSouth_process: process(s_CtrlFlg)
--	begin
--		if(s_CtrlFlg'event and s_CtrlFlg = '1') then
--			--Grab packet from FCU
--			packetS <= s_rnaCtrl after 20 ns;
--			s_CTRflg <= '1' after 30 ns;
--			s_CTRflg <= '0' after 50 ns;
--			--Grab Lock
--			--Write to RsvTable
--			--Release Lock
--		end if;
--	end process;
--	
--	--controlpacketWest_process:	This process is responsible for control packets
--	--										sent in by the FCU from the west port
--	controlpacketWest_process: process(w_CtrlFlg)
--	begin
--		if(w_CtrlFlg'event and w_CtrlFlg = '1') then
--			--Grab packet from FCU
--			packetW <= w_rnaCtrl after 20 ns;
--			w_CTRflg <= '1' after 30 ns;
--			w_CTRflg <= '0' after 50 ns;
--			--Grab Lock
--			--Write to RsvTable
--			--Release Lock
--		end if;
--	end process;

end Behavioral;

