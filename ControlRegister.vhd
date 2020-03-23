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
-- File: ControlRegister.vhd
--
-- Description:
-- The control register is written by the host and controls the baud rate,
-- parity, number f stop bits, and hardware handshake.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.universal.all;

entity ControlRegister is
	port 
	(
		Clock, HostWritePulse : in std_logic;
		HostWriteAddress : in std_logic_vector(1 downto 0);
		HostWriteData : in std_logic_vector(7 downto 0);
		ParityEnableBit, EvenParitySelectBit, StickParityBit, NumberOfStopBits, HandshakeEnableBit : out std_logic;
		BaudRateSelect : out std_logic_vector(2 downto 0);
		ControlRegisterBus : inout std_logic_vector(7 downto 0)
	);
end ControlRegister;

architecture Behavioral of ControlRegister is
	signal ControlData : std_logic_vector(7 downto 0);
begin
	Control : process (Clock) is
		variable controlDataRegister : std_logic_vector(7 downto 0) := "00000" & SELECT_9600;
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		ControlData <= controlDataRegister;
		
		-- System Clock Events
		-- ========================================================================
		-- If a host write occured and the host wrote to the control register then
		-- store the data in the control register.
		if Clock'event and Clock = '1' then
			if HostWritePulse = '1' and HostWriteAddress = CONTROL_REGISTER_ADDRESS then
				controlDataRegister := HostWriteData;
			else
				controlDataRegister := ControlData;
			end if;
		end if;
		
		-- External Module Signals
		-- ========================================================================
		-- Output the contents of the control register for other modules to use.
		ControlRegisterBus <= controlDataRegister;
		
		-- Break out the individual parts of the control regsiter for other modules
		-- to use.
		BaudRateSelect <= ControlRegisterBus(2 downto 0);
		ParityEnableBit <= ControlRegisterBus(3);
		EvenParitySelectBit <= ControlRegisterBus(4);
		StickParityBit <= ControlRegisterBus(5);
		NumberOfStopBits <= ControlRegisterBus(6);
		HandshakeEnableBit <= ControlRegisterBus(7);
	end process Control;
end architecture Behavioral;
