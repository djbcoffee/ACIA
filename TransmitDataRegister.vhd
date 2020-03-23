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
-- File: TransmitDataRegister.vhd
--
-- Description:
-- This register accepts a data byte from the host and holds it until the
-- transmitter is ready to transmit the data byte.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.universal.all;

entity TransmitDataRegister is
	port 
	(
		Clock, HostWritePulse : in std_logic;
		HostWriteAddress : in std_logic_vector(1 downto 0);
		HostWriteData : in std_logic_vector(7 downto 0);
		TransmitDataRegisterBus : out std_logic_vector(7 downto 0)
	);
end TransmitDataRegister;

architecture Behavioral of TransmitDataRegister is
	signal TransmitData : std_logic_vector(7 downto 0);
begin
	TransmitRegister : process (Clock) is
		variable transmitDataReg : std_logic_vector(7 downto 0) := (others => '0');
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		TransmitData <= transmitDataReg;

		-- System Clock Events
		-- ========================================================================
		-- If a host write occured and the host wrote to the transmit data register
		-- then store the data in the transmit data register.
		if Clock'event and Clock = '1' then
			if HostWritePulse = '1' and HostWriteAddress = TRANSMIT_DATA_REGISTER_ADDRESS then
				transmitDataReg := HostWriteData;
			else
				transmitDataReg := TransmitData;
			end if;
		end if;
		
		-- External Module Signals
		-- ========================================================================
		-- Output the contents of the transmit data register for other modules to
		-- use.
		TransmitDataRegisterBus <= transmitDataReg;
	end process TransmitRegister;
end architecture Behavioral;
