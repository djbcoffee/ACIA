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
-- File: Transmitter.vhd
--
-- Description:
-- Contains the transmitter shift register and associated circuitry necessary to
-- transmit an asynchronous data stream and provide hardware handshaking.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Transmitter is
	port 
	(
		Clock, TxShiftPulse, ParityEnableBit, EvenParitySelectBit, StickParityBit, NumberOfStopBits, HandshakeEnableBit, TransmitDataRegisterEmptyBit, TransmitCompleteBit, nCtsPin : in std_logic;
		TransmitDataRegisterBus : in std_logic_vector(7 downto 0);
		TransmitComplete, StartTransmission, TxPin : out std_logic
	);
end Transmitter;

architecture Behavioral of Transmitter is
	signal LoadShiftRegister : std_logic;
	signal TransmittedAllBits : std_logic;
	signal LoadZeroParityBit : std_logic;
	signal TransmitOneBitsCount : std_logic;

	signal CtsSync : std_logic_vector(1 downto 0);
	signal TransmitBitCount: std_logic_vector(3 downto 0);
	signal TransmitShift : std_logic_vector(8 downto 0);

	attribute keep : string;
	attribute keep of LoadShiftRegister : signal is "TRUE";
	attribute keep of TransmittedAllBits : signal is "TRUE";
	attribute keep of LoadZeroParityBit : signal is "TRUE";
begin
	Transmit : process (Clock, TransmitCompleteBit, TransmitDataRegisterEmptyBit, TxShiftPulse, ParityEnableBit, NumberOfStopBits, HandshakeEnableBit, EvenParitySelectBit, StickParityBit) is
		variable transmitOneBitsCountRegister : std_logic := '0';
		variable ctsSyncRegister : std_logic_vector(1 downto 0) := (others => '0');
		variable transmitBitCountRegister: std_logic_vector(3 downto 0) := (others => '0');
		variable transmitShiftRegister : std_logic_vector(8 downto 0) := (others => '1');
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		TransmitOneBitsCount <= transmitOneBitsCountRegister;
		CtsSync <= ctsSyncRegister;
		TransmitBitCount <= transmitBitCountRegister;
		TransmitShift <= transmitShiftRegister;

		-- Internal Module Signals
		-- ========================================================================
		-- The shift register is loaded under the following conditions:
		-- 1.  The transmit complete bit of the status register is logic high
		--     and
		--     the transmit data register empty bit of the status register is logic
		--     low
		-- 2.  The current transmission is complete using below table
		--     and
		--     the transmitter data register empty bit is logic low
		-- Parity Enable Bit	Number Of Stop Bits	Total Bits
		--         0                 0                10
		--         0                 1                11
		--         1                 0                11
		--         1                 1                12
		if HandshakeEnableBit = '1' and CtsSync(1) = '1' then
			LoadShiftRegister <= '0';
		elsif TransmitCompleteBit = '1' and TransmitDataRegisterEmptyBit = '0' then
			LoadShiftRegister <= '1';
		elsif ParityEnableBit = '0' and NumberOfStopBits = '0' and unsigned(TransmitBitCount) = 10 and TransmitDataRegisterEmptyBit = '0' then
			LoadShiftRegister <= '1';
		elsif ParityEnableBit = '0' and NumberOfStopBits = '1' and unsigned(TransmitBitCount) = 11 and TransmitDataRegisterEmptyBit = '0' then
			LoadShiftRegister <= '1';
		elsif ParityEnableBit = '1' and NumberOfStopBits = '0' and unsigned(TransmitBitCount) = 11 and TransmitDataRegisterEmptyBit = '0' then
			LoadShiftRegister <= '1';
		elsif ParityEnableBit = '1' and NumberOfStopBits = '1' and unsigned(TransmitBitCount) = 12 and TransmitDataRegisterEmptyBit = '0' then
			LoadShiftRegister <= '1';
		else
			LoadShiftRegister <= '0';
		end if;

		-- We have transmitted all bits when the following table is satisfied:
		-- Parity Enable Bit	Number Of Stop Bits	Total Bits
		--         0                 0                10
		--         0                 1                11
		--         1                 0                11
		--         1                 1                12
		if ParityEnableBit = '0' and NumberOfStopBits = '0' and unsigned(TransmitBitCount) = 10 then
			TransmittedAllBits <= '1';
		elsif ParityEnableBit = '0' and NumberOfStopBits = '1' and unsigned(TransmitBitCount) = 11 then
			TransmittedAllBits <= '1';
		elsif ParityEnableBit = '1' and NumberOfStopBits = '0' and unsigned(TransmitBitCount) = 11 then
			TransmittedAllBits <= '1';
		elsif ParityEnableBit = '1' and NumberOfStopBits = '1' and unsigned(TransmitBitCount) = 12 then
			TransmittedAllBits <= '1';
		else
			TransmittedAllBits <= '0';
		end if;
		
		-- A logic low parity bit is loaded into the shift register under the
		-- following conditions:
		-- 1.  The transmit bit count equals decimal value of 9
		--     and
		--     the parity enable bit is logic high
		--     and
		--     even parity select bit is logic low
		--     and
		--     the stick parity bit is logic low
		--     and
		--     transmit one bits count is logic high
		-- 2.  The transmit bit count equals decimal value of 9
		--     and
		--     the parity enable bit is logic high
		--     and
		--     even parity select bit is logic high
		--     and
		--     the stick parity bit is logic low
		--     and
		--     transmit one bits count is logic low
		-- 3.  The transmit bit count equals decimal value of 9
		--     and
		--     the parity enable bit is logic high
		--     and
		--     even parity select bit is logic high
		--     and
		--     the stick parity bit is logic high
		if unsigned(TransmitBitCount) = 9 and ParityEnableBit = '1' and EvenParitySelectBit = '0' and StickParityBit = '0' and TransmitOneBitsCount = '1' then
			LoadZeroParityBit <= '1';
		elsif unsigned(TransmitBitCount) = 9 and ParityEnableBit = '1' and EvenParitySelectBit = '1' and StickParityBit = '0' and TransmitOneBitsCount = '0' then
			LoadZeroParityBit <= '1';
		elsif unsigned(TransmitBitCount) = 9 and ParityEnableBit = '1' and EvenParitySelectBit = '1' and StickParityBit = '1' then
			LoadZeroParityBit <= '1';
		else
			LoadZeroParityBit <= '0';
		end if;

		-- System Clock Events
		-- ========================================================================
		if Clock'event and Clock = '1' then
			-- The transmit one bits count register has the following rules:
			-- 1.  If all bits have been transmitted this register is cleared to
			--     logic low.
			-- 2.  If transmit bit count register has a decimal value of 1 to 8
			--     inclusive
			--     and
			--     transmit shift pulse is logic high
			--     and
			--     the shift register bit 1 is logic high
			--     then
			--     the register is to be toggled
			if TransmittedAllBits = '1' then
				transmitOneBitsCountRegister := '0';
			elsif unsigned(TransmitBitCount) >= 1 and unsigned(TransmitBitCount) <= 8 and TxShiftPulse = '1' and TransmitShift(1) = '1' then
				transmitOneBitsCountRegister := not TransmitOneBitsCount;
			else
				transmitOneBitsCountRegister := TransmitOneBitsCount;
			end if;
		end if;
		
		if Clock'event and Clock = '1' then
			-- A two-stage register that is used to synchronize the CTS pin async
			-- signal.  The first register in the stage connects directly to the CTS
			-- pin.  This register will take any metastability issues that may occur
			-- from the async CTS pin changing in relation to the system clock.  The
			-- second register is used to read the data.  The second register is
			-- protected from metastability and its output can be reliably used as a
			-- synchronous signal.  All together the two registers are connected in
			-- a shift configuration.
			ctsSyncRegister(1) := CtsSync(0);
			ctsSyncRegister(0) := nCtsPin;
		end if;

		if Clock'event and Clock = '1' then
			-- The transmit bit count register has the following rules:
			-- 1.  If all bits have been transmitted
			--     and
			--     the load shift register signal is logic low
			--     and
			--     the transmit shift pulse is logic high
			--     then
			--     load a deciaml value of zero into the register
			-- 2.  If load shift register signal is logic high
			--     and
			--     the transmit shift pulse is logic high
			--     then
			--     this register is set to decimal value 1
			-- 3.  If the register does not have a decimal value of zero
			--     and
			--     the transmit shift pulse is logic high
			--     then
			--     increment this register
			if TransmittedAllBits = '1' and LoadShiftRegister = '0' and TxShiftPulse = '1' then
				transmitBitCountRegister := (others => '0');
			elsif LoadShiftRegister = '1' and TxShiftPulse = '1' then
				transmitBitCountRegister := "0001";
			elsif TransmitBitCount /= "0000" and TxShiftPulse = '1' then
				transmitBitCountRegister := std_logic_vector(unsigned(TransmitBitCount) + 1);
			else
				transmitBitCountRegister := TransmitBitCount;
			end if;
		end if;

		if Clock'event and Clock = '1' then
			-- The transmit shift register has the following rules:
			-- 1.  If load shift register signal is logic high
			--     and
			--     the transmit shift pulse is logic high
			--     then
			--     this register is loaded with a logic low in bit position 0 and
			--     the transmit data in bits 1 through 8 inclusive
			-- 2.  If load zero parity bit signal is logic high
			--     and
			--     transmit shift pulse is logic high
			--     then
			--     load a logic low into bit position 0
			-- 3.  If the transmit bit count register does not equal a decimal value
			--     of zero
			--     and
			--     transmit shift pulse is logic high
			--     then
			--     right shift the regsiter loading a logic high into the most
			--     significant bit position
			if LoadShiftRegister = '1' and TxShiftPulse = '1' then
				transmitShiftRegister(0) := '0';
				transmitShiftRegister(8 downto 1) := TransmitDataRegisterBus(7 downto 0);
			elsif LoadZeroParityBit = '1' and TxShiftPulse = '1' then
				transmitShiftRegister(0) := '0';
				transmitShiftRegister(8 downto 1) := TransmitShift(8 downto 1);
			elsif TransmitBitCount /= "0000" and TxShiftPulse = '1' then
				transmitShiftRegister(0) := TransmitShift(1);
				transmitShiftRegister(1) := TransmitShift(2);
				transmitShiftRegister(2) := TransmitShift(3);
				transmitShiftRegister(3) := TransmitShift(4);
				transmitShiftRegister(4) := TransmitShift(5);
				transmitShiftRegister(5) := TransmitShift(6);
				transmitShiftRegister(6) := TransmitShift(7);
				transmitShiftRegister(7) := TransmitShift(8);
				transmitShiftRegister(8) := '1';
			else
				transmitShiftRegister := TransmitShift;
			end if;
		end if;
		
		-- External Module Signals
		-- ========================================================================
		-- Transfer the transmitted all bits internal signal to the transmit
		-- complete external signal for other modules to use.
		TransmitComplete <= TransmittedAllBits;
		
		-- Transfer the load shift register internal signal to the start
		-- transmission external signal for other modules to use.
		StartTransmission <= LoadShiftRegister;
		
		-- Connect the least significant bit of the shift register to the Tx pin.
		TxPin <= transmitShiftRegister(0);
	end process Transmit;
end architecture Behavioral;
