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
-- File: StatusRegister.vhd
--
-- Description:
-- This register contains the current status of the UART.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.universal.all;

entity StatusRegister is
	port 
	(
		Clock, HostWritePulse, HostReceiveDataReadPulse, FramingError, ParityError, ReceiveComplete, StartTransmission, TransmitComplete, TxShiftPulse : in std_logic;
		HostWriteAddress : in std_logic_vector(1 downto 0);
		ReceiveDataRegisterFullBit, TransmitCompleteBit, TransmitDataRegisterEmptyBit : out std_logic;
		StatusRegisterBus : out std_logic_vector(5 downto 0)
	);
end StatusRegister;

architecture Behavioral of StatusRegister is
	signal StatusData : std_logic_vector(5 downto 0);
begin
	Status : process (Clock) is
		variable statusDataRegister : std_logic_vector(5 downto 0) := "110000";
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		StatusData <= statusDataRegister;

		-- System Clock Events
		-- ========================================================================
		-- Bit 0 Parity Error
		-- When a receive has been completed save the status of the parity check in
		-- this bit.
		if Clock'event and Clock = '1' then
			if ReceiveComplete = '1' then
				statusDataRegister(0) := ParityError;
			else
				statusDataRegister(0) := StatusData(0);
			end if;
		end if;

		-- Bit 1 Framing Error
		-- When a receive has been completed save the status of the framing check
		-- in this bit.
		if Clock'event and Clock = '1' then
			if ReceiveComplete = '1' then
				statusDataRegister(1) := FramingError;
			else
				statusDataRegister(1) := StatusData(1);
			end if;
		end if;
		
		-- Bit 2 Overrun
		-- When a receive has been completed check if the receive data register is
		-- empty and if so this bit is to cleared logic low.  Otherwise, this bit
		-- is to be set logic high to indicate that the byte currently in the
		-- receive data register has been throw out.  Bit 3 is the receive data
		-- register full bit.
		if Clock'event and Clock = '1' then
			if ReceiveComplete = '1' then
				if StatusData(3) = '0' then
					statusDataRegister(2) := '0';
				else
					statusDataRegister(2) := '1';
				end if;
			else
				statusDataRegister(2) := StatusData(2);
			end if;
		end if;
		
		-- Bit 3 Receive Data Register Full
		-- 1.  If a receive is completed then set the bit logic high
		-- 2.  If a read of the receive data register is done then clear the bit
		--     logic low
		if Clock'event and Clock = '1' then
			if ReceiveComplete = '1' then
				statusDataRegister(3) := '1';
			elsif HostReceiveDataReadPulse = '1' then
				statusDataRegister(3) := '0';
			else
				statusDataRegister(3) := StatusData(3);
			end if;
		end if;
		
		-- Bit 4 Transmit Data Register Empty
		-- 1.  If a transmission is started and the transmit shift pulse is logic
		--     high then set the bit logic high
		-- 2.  If a write of the transmit data register is done then clear the bit
		--     logic low
		if Clock'event and Clock = '1' then
			if StartTransmission = '1' and TxShiftPulse = '1' then
				statusDataRegister(4) := '1';
			elsif HostWritePulse = '1' and HostWriteAddress = TRANSMIT_DATA_REGISTER_ADDRESS then
				statusDataRegister(4) := '0';
			else
				statusDataRegister(4) := StatusData(4);
			end if;
		end if;
		
		-- Bit 5 Transmit Complete
		-- 1.  If a transmission is started and the transmit shift pulse is logic
		--     high then clear the bit logic low
		-- 2.  If a transmission is complete and the transmit shift pulse is logic
		--     high then set this bit logic high
		if Clock'event and Clock = '1' then
			if StartTransmission = '1' and TxShiftPulse = '1' then
				statusDataRegister(5) := '0';
			elsif TransmitComplete = '1' and TxShiftPulse = '1' then
				statusDataRegister(5) := '1';
			else
				statusDataRegister(5) := StatusData(5);
			end if;
		end if;

		-- External Module Signals
		-- ========================================================================
		-- Output the contents of the status register for other modules to use.
		StatusRegisterBus <= statusDataRegister;
		
		-- Break out the individual parts of the status regsiter for other modules
		-- to use.
		ReceiveDataRegisterFullBit <= statusDataRegister(3);
		TransmitDataRegisterEmptyBit <= statusDataRegister(4);
		TransmitCompleteBit <= statusDataRegister(5);
	end process Status;
end architecture Behavioral;
