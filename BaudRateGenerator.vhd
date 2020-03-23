---------------------------------------------------------------------------------
-- Copyright (C) 2019 Donald J. Bartley <djbcoffee@gmail.com>
--
-- This source file may be used and distributed without restriction provided that
-- this copyright statement is not removed from the file and that any derivative
-- work contains the original copyright notice and the associated disclaimer.
--
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the Free
-- Software Foundation; either version 2 of the License, or (at your option) any
-- later version.
--
-- This source file is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
--
-- You should have received a copy of the GNU General Public License along with
-- this source file.  If not, see <http://www.gnu.org/licenses/> or write to the
-- Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
-- 02110-1301, USA.
---------------------------------------------------------------------------------
-- File: BaudRateGenerator.vhd
--
-- Description:
-- Generates the baud rate pulse for the transmit module and the 8 times baud
-- rate pulse for the received based on the currently selected baud rate.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.universal.all;

entity BaudRateGenerator is
	port 
	(
		Clock : in std_logic;
		BaudRateSelect : in std_logic_vector(2 downto 0);
		TxShiftPulse, RxSamplePulse : out std_logic
	);
end BaudRateGenerator;

architecture Behavioral of BaudRateGenerator is
	signal TxBaudRatePulse : std_logic;
	signal RxBaudRatePulse : std_logic;
	
	signal DivideBy8 : std_logic_vector(2 downto 0);
	signal MainCounter : std_logic_vector(11 downto 0);
	
	attribute keep : string;
	attribute keep of TxBaudRatePulse : signal is "TRUE";
	attribute keep of RxBaudRatePulse : signal is "TRUE";
begin
	Generator : process (Clock, BaudRateSelect) is
		variable divideBy8Register : std_logic_vector(2 downto 0) := (others => '0');
		variable mainCounterRegister : std_logic_vector(11 downto 0) := (others => '0');
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		DivideBy8 <= divideBy8Register;
		MainCounter <= mainCounterRegister;

		-- If the main counter has reached the end count of the selected baud rate,
		-- and eight of those instances has occured, then assert the
		-- TxBaudRatePulse signal.
		if (BaudRateSelect = SELECT_1200 and unsigned(MainCounter) = MAX_COUNT_1200 and DivideBy8 = "111") or (BaudRateSelect = SELECT_2400 and unsigned(MainCounter) = MAX_COUNT_2400 and DivideBy8 = "111") or (BaudRateSelect = SELECT_4800 and unsigned(MainCounter) = MAX_COUNT_4800 and DivideBy8 = "111") or (BaudRateSelect = SELECT_9600 and unsigned(MainCounter) = MAX_COUNT_9600 and DivideBy8 = "111") or (BaudRateSelect = SELECT_19200 and unsigned(MainCounter) = MAX_COUNT_19200 and DivideBy8 = "111") or (BaudRateSelect = SELECT_38400 and unsigned(MainCounter) = MAX_COUNT_38400 and DivideBy8 = "111") or (BaudRateSelect = SELECT_57600 and unsigned(MainCounter) = MAX_COUNT_57600 and DivideBy8 = "111") or (BaudRateSelect = SELECT_115200 and unsigned(MainCounter) = MAX_COUNT_115200 and DivideBy8 = "111") then
			TxBaudRatePulse <= '1';
		else
			TxBaudRatePulse <= '0';
		end if;
		
		-- If the main counter has reached the end count of the selected baud rate
		-- then assert the RxBaudRatePulse signal.
		if (BaudRateSelect = SELECT_1200 and unsigned(MainCounter) = MAX_COUNT_1200) or (BaudRateSelect = SELECT_2400 and unsigned(MainCounter) = MAX_COUNT_2400) or (BaudRateSelect = SELECT_4800 and unsigned(MainCounter) = MAX_COUNT_4800) or (BaudRateSelect = SELECT_9600 and unsigned(MainCounter) = MAX_COUNT_9600) or (BaudRateSelect = SELECT_19200 and unsigned(MainCounter) = MAX_COUNT_19200) or (BaudRateSelect = SELECT_38400 and unsigned(MainCounter) = MAX_COUNT_38400) or (BaudRateSelect = SELECT_57600 and unsigned(MainCounter) = MAX_COUNT_57600) or (BaudRateSelect = SELECT_115200 and unsigned(MainCounter) = MAX_COUNT_115200) then
			RxBaudRatePulse <= '1';
		else
			RxBaudRatePulse <= '0';
		end if;
		
		-- System Clock Events
		-- ========================================================================
		if Clock'event and Clock = '1' then
			-- Increment the main counter unless one of the following conditions are
			-- present in which case the counter should be reset back to zero:
			-- 1.  The RxBaudRatePulse signal is asserted.
			if RxBaudRatePulse = '1' then
				mainCounterRegister := (others => '0');
			else
				mainCounterRegister := std_logic_vector(unsigned(MainCounter) + 1);
			end if;
			
			-- If the RxBaudRatePulse signal is asserted then change the state of
			-- the divideBy8Register.
			if RxBaudRatePulse = '1' then
				if DivideBy8(0) = '1' and DivideBy8(1) = '1' then
					divideBy8Register(2) := not DivideBy8(2);
				else
					divideBy8Register(2) := DivideBy8(2);
				end if;
				
				if DivideBy8(0) = '1' then
					divideBy8Register(1) := not DivideBy8(1);
				else
					divideBy8Register(1) := DivideBy8(1);
				end if;
				
				divideBy8Register(0) := not DivideBy8(0);
			else
				divideBy8Register := DivideBy8;
			end if;
		end if;
		
		-- External Module Signals
		-- ========================================================================
		-- Transfer the TxBaudRatePulse and RxBaudRatePulse signals outside of this
		-- modules for other modules to use.
		TxShiftPulse <= TxBaudRatePulse;
		RxSamplePulse <= RxBaudRatePulse;
	end process Generator;
end architecture Behavioral;
