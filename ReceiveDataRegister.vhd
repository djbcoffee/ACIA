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
-- File: ReceiveDataRegister.vhd
--
-- Description:
-- This register accepts a data byte from the receiver and holds it until the
-- host can read the data.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ReceiveDataRegister is
	port 
	(
		Clock, ReceiveComplete : in std_logic;
		ReceivedData : in std_logic_vector(7 downto 0);
		ReceiveDataRegisterBus : out std_logic_vector(7 downto 0)
	);
end ReceiveDataRegister;

architecture Behavioral of ReceiveDataRegister is
	signal ReceiveData : std_logic_vector(7 downto 0);
begin
	ReceiveRegister : process (Clock) is
		variable receiveDataReg : std_logic_vector(7 downto 0) := (others => '0');
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		ReceiveData <= receiveDataReg;

		-- System Clock Events
		-- ========================================================================
		-- If the async receiver received a byte of data then store the data in the
		-- receive data register.
		if Clock'event and Clock = '1' then
			if ReceiveComplete = '1' then
				receiveDataReg := ReceivedData;
			else
				receiveDataReg := ReceiveData;
			end if;
		end if;
		
		-- External Module Signals
		-- ========================================================================
		-- Output the contents of the receive data register for other modules to
		-- use.
		ReceiveDataRegisterBus <= receiveDataReg;
	end process ReceiveRegister;
end architecture Behavioral;
