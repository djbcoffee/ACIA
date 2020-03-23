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
-- File: Receiver.vhd
--
-- Description:
-- Contains the receiver shift register and associated circuitry necessary to
-- receive an asynchronous data stream and provide hardware handshaking.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Receiver is
	port 
	(
		Clock, RxSamplePulse, ParityEnableBit, EvenParitySelectBit, StickParityBit, NumberOfStopBits, HandshakeEnableBit, ReceiveDataRegisterFullBit, RxPin : in std_logic;
		ReceiveComplete, ParityError, FramingError, nRtsPin : out std_logic;
		ReceivedData : out std_logic_vector(7 downto 0)
	);
end Receiver;

architecture Behavioral of Receiver is
	signal ReceiveFallingEdgePulse : std_logic;
	signal FalseStartPulse : std_logic;
	signal ReceivedAllBits : std_logic;
	signal ReceiveIdle : std_logic;
	signal ReceiveOneBitsCount : std_logic;
	signal ReceiveRts : std_logic;
	
	signal ReceiveSamplePulseCount : std_logic_vector(2 downto 0);
	signal ReceiveSync : std_logic_vector(2 downto 0);
	signal ReceiveBitCount : std_logic_vector(3 downto 0);
	signal ReceiveShift : std_logic_vector(11 downto 0);
	
	attribute keep : string;
	attribute keep of ReceivedAllBits : signal is "TRUE";
begin
	Receive : process (Clock, RxSamplePulse, ParityEnableBit, NumberOfStopBits, StickParityBit, EvenParitySelectBit) is
		variable receiveIdleRegister : std_logic := '1';
		variable receiveOneBitsCountRegister : std_logic := '0';
		variable receiveRtsRegister :std_logic := '0';
		variable receiveSamplePulseCountRegister : std_logic_vector(2 downto 0) := (others => '0');
		variable receiveSyncRegister : std_logic_vector(2 downto 0) := (others => '1');
		variable receiveBitCountRegister: std_logic_vector(3 downto 0) := (others => '0');
		variable receiveShiftRegister : std_logic_vector(11 downto 0) := (others => '0');
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		ReceiveIdle <= receiveIdleRegister;
		ReceiveOneBitsCount <= receiveOneBitsCountRegister;
		ReceiveRts <= receiveRtsRegister;
		ReceiveSamplePulseCount <= receiveSamplePulseCountRegister;
		ReceiveSync <= receiveSyncRegister;
		ReceiveBitCount <= receiveBitCountRegister;
		ReceiveShift <= receiveShiftRegister;
		
		-- Falling edge detect signal from sync circuit connected to the Rx Pin.
		-- Pulse lasts for one system clock cycle.
		ReceiveFallingEdgePulse <= not ReceiveSync(1) and ReceiveSync(2);
		
		-- A false start occurs if the first sample is not a logic low.
		if RxSamplePulse = '1' and unsigned(ReceiveSamplePulseCount) = 3 and unsigned(ReceiveBitCount) = 0 and ReceiveSync(1) = '1' then
			FalseStartPulse <= '1';
		else
			FalseStartPulse <= '0';
		end if;
		
		-- We have received all bits when:
		-- Parity Enable Bit	Number Of Stop Bits	Total Bits
		--         0                 0                10
		--         0                 1                11
		--         1                 0                11
		--         1                 1                12
		if ReceiveIdle = '0' and ParityEnableBit = '0' and NumberOfStopBits = '0' and unsigned(ReceiveBitCount) = 10 then
			ReceivedAllBits <= '1';
		elsif ReceiveIdle = '0' and ParityEnableBit = '0' and NumberOfStopBits = '1' and unsigned(ReceiveBitCount) = 11 then
			ReceivedAllBits <= '1';
		elsif ReceiveIdle = '0' and ParityEnableBit = '1' and NumberOfStopBits = '0' and unsigned(ReceiveBitCount) = 11 then
			ReceivedAllBits <= '1';
		elsif ReceiveIdle = '0' and ParityEnableBit = '1' and NumberOfStopBits = '1' and unsigned(ReceiveBitCount) = 12 then
			ReceivedAllBits <= '1';
		else
			ReceivedAllBits <= '0';
		end if;
		
		-- System Clock Events
		-- ========================================================================
		if Clock'event and Clock = '1' then
			-- The receive idle register has the following rules:
			-- 1.  If the receive idle register is logic one (e.g. receiver is idle)
			--     and a falling edge is detected on the Rx pin then go into a
			--     non-idle state which is logic zero.
			-- 2.  If a false start is detected then go back to idle state.
			-- 3.  If the receive has been completed go back to idle state.
			if ReceiveIdle = '1' and ReceiveFallingEdgePulse = '1' then
				receiveIdleRegister := '0';
			elsif FalseStartPulse = '1' then
				receiveIdleRegister := '1';
			elsif ReceivedAllBits = '1' then
				receiveIdleRegister := '1';
			else
				receiveIdleRegister := ReceiveIdle;
			end if;
		end if;

		if Clock'event and Clock = '1' then
			-- The receive one bits count register has the following rules:
			-- 1.  If receiver is idle this register is cleared to logic zero.
			-- 2.  If receive bit count register has a value of 1 to 8 inclusive
			--     and
			--     receive sample pulse count register has a value of 7
			--     and
			--     the Rx pin data is logic high
			--     then
			--     the register is to be toggled
			-- 3.  If receive bit count register has a value of 9
			--     and
			--     receive sample pulse count register has a value of 7
			--     and
			--     parity enable bit is logic high
			--     and
			--     stick parity bit is logic low
			--     and
			--     the Rx pin data is logic high
			--     then
			--     the register is to be toggled
			if ReceiveIdle = '1' then
				receiveOneBitsCountRegister := '0';
			elsif unsigned(ReceiveBitCount) >= 1 and unsigned(ReceiveBitCount) <= 8 and unsigned(ReceiveSamplePulseCount) = 7 and ReceiveSync(1) = '1' and RxSamplePulse = '1' then
				receiveOneBitsCountRegister := not ReceiveOneBitsCount;
			elsif unsigned(ReceiveBitCount) = 9 and unsigned(ReceiveSamplePulseCount) = 7 and ParityEnableBit = '1' and StickParityBit = '0' and ReceiveSync(1) = '1' and RxSamplePulse = '1' then
				receiveOneBitsCountRegister := not ReceiveOneBitsCount;
			else
				receiveOneBitsCountRegister := ReceiveOneBitsCount;
			end if;
		end if;

		if Clock'event and Clock = '1' then
			-- The receive RTS register has the following rules:
			-- 1.  If the handshake enable bit is logic low then this register is
			--     set to logic low.
			-- 2.  If the received all bits signal is logic high then this register
			--     is set to logic high.
			-- 3.  If this register is logic high and the receiver data register
			--     full bit is logic low then this register is set to logic low.
			if HandshakeEnableBit = '0' then
				receiveRtsRegister := '0';
			elsif ReceivedAllBits = '1' then
				receiveRtsRegister := '1';
			elsif ReceiveRts = '1' and ReceiveDataRegisterFullBit = '0' then
				receiveRtsRegister := '0';
			else
				receiveRtsRegister := ReceiveRts;
			end if;
		end if;

		if Clock'event and Clock = '1' then
			-- The receive sample pulse count register has the following rules:
			-- 1.  If receiver is idle this register is cleared to logic zero.
			-- 2.  If receive bit count register equals zero
			--     and
			--     this register equals 3
			--     and
			--     rx sample pulse is logic high
			--     then
			--     reset this register back to zero
			-- 3.  if the rx sample pulse is logic high then increment this
			--     register.
			if ReceiveIdle = '1' then
				receiveSamplePulseCountRegister := (others => '0');
			elsif unsigned(ReceiveBitCount) = 0 and unsigned(ReceiveSamplePulseCount) = 3 and RxSamplePulse = '1' then
				receiveSamplePulseCountRegister := (others => '0');
			elsif RxSamplePulse = '1' then
				receiveSamplePulseCountRegister := std_logic_vector(unsigned(ReceiveSamplePulseCount) + 1);
			else
				receiveSamplePulseCountRegister := ReceiveSamplePulseCount;
			end if;
		end if;
			
		if Clock'event and Clock = '1' then
			-- A three-stage register that is used to synchronize the Rx pin async
			-- signal.  The first register in the stage connects directly to the Rx
			-- pin.  This register will take any metastability issues that may occur
			-- from the async Rx pin changing in relation to the system clock.  The
			-- second register is used to read the data, while the second and third
			-- registers are used to detect a falling edge from the output of the
			-- first register.  The second and third registers are protected from
			-- metastability and their outputs can be reliably used as synchronous
			-- signals.  All together the three registers are connected in a shift
			-- configuration.
			receiveSyncRegister(2) := ReceiveSync(1);
			receiveSyncRegister(1) := ReceiveSync(0);
			receiveSyncRegister(0) := RxPin;
		end if;

		if Clock'event and Clock = '1' then
			-- The receive bit count register has the following rules:
			-- 1.  If receiver is idle this register is cleared to logic zero.
			-- 2.  If the rx sample pulse is logic high
			--     and
			--     receive sample pulse count register equals 3
			--     and
			--     the Rx pin data is logic low
			--     and
			--     this register is equal to zero
			--     then
			--     increment this register
			-- 3.  If the rx sample pulse is logic high
			--     and
			--     receive sample pulse count register equals 7
			--     then
			--     increment this register
			if ReceiveIdle = '1' then
				receiveBitCountRegister := (others => '0');
			elsif RxSamplePulse = '1' and unsigned(ReceiveSamplePulseCount) = 3 and ReceiveSync(1) = '0' and unsigned(ReceiveBitCount) = 0 then
				receiveBitCountRegister := std_logic_vector(unsigned(ReceiveBitCount) + 1);
			elsif RxSamplePulse = '1' and unsigned(ReceiveSamplePulseCount) = 7 then
				receiveBitCountRegister := std_logic_vector(unsigned(ReceiveBitCount) + 1);
			else
				receiveBitCountRegister := ReceiveBitCount;
			end if;
		end if;

		if Clock'event and Clock = '1' then
			-- The receive shift register has the following rules:
			-- 1.  If receiver is not idle
			--     and
			--     the rx sample pulse is logic high
			--     and
			--     receive sample pulse count register equals 3
			--     and
			--     receive bit count register is equal to zero
			--     then
			--     shift data from rx pin into this register.
			-- 2.  If receiver is not idle
			--     and
			--     the rx sample pulse is logic high
			--     and
			--     receive sample pulse count register equals 7
			--     then
			--     shift data from rx pin into this register.
			if ReceiveIdle = '0' and RxSamplePulse = '1' and unsigned(ReceiveSamplePulseCount) = 3 and unsigned(ReceiveBitCount) = 0 then
				receiveShiftRegister(0) := ReceiveShift(1);
				receiveShiftRegister(1) := ReceiveShift(2);
				receiveShiftRegister(2) := ReceiveShift(3);
				receiveShiftRegister(3) := ReceiveShift(4);
				receiveShiftRegister(4) := ReceiveShift(5);
				receiveShiftRegister(5) := ReceiveShift(6);
				receiveShiftRegister(6) := ReceiveShift(7);
				receiveShiftRegister(7) := ReceiveShift(8);
				receiveShiftRegister(8) := ReceiveShift(9);
				receiveShiftRegister(9) := ReceiveShift(10);
				receiveShiftRegister(10) := ReceiveShift(11);
				receiveShiftRegister(11) := ReceiveSync(1);
			elsif ReceiveIdle = '0' and RxSamplePulse = '1' and unsigned(ReceiveSamplePulseCount) = 7 then
				receiveShiftRegister(0) := ReceiveShift(1);
				receiveShiftRegister(1) := ReceiveShift(2);
				receiveShiftRegister(2) := ReceiveShift(3);
				receiveShiftRegister(3) := ReceiveShift(4);
				receiveShiftRegister(4) := ReceiveShift(5);
				receiveShiftRegister(5) := ReceiveShift(6);
				receiveShiftRegister(6) := ReceiveShift(7);
				receiveShiftRegister(7) := ReceiveShift(8);
				receiveShiftRegister(8) := ReceiveShift(9);
				receiveShiftRegister(9) := ReceiveShift(10);
				receiveShiftRegister(10) := ReceiveShift(11);
				receiveShiftRegister(11) := ReceiveSync(1);
			else
				receiveShiftRegister := ReceiveShift;
			end if;
		end if;
		
		-- External Module Signals
		-- ========================================================================
		-- Transfer the received all bits internal signal to the receive complete
		-- external signal for other modules to use.
		ReceiveComplete <= ReceivedAllBits;
		
		-- Generate the parity error signal using the following rules:
		-- Even Parity Select bit - When logic low, an odd number of logic ones are
		-- checked in the data word bits and parity bit.  When logic high, an even
		-- number of logic ones is checked.
		-- Stick Parity bit - When Even Parity Select bit and Stick Parity bit are
		-- logic high the parity bit is checked as a logic low.  When Stick Parity
		-- bit is logic high and Even Parity Select bit is a logic low then the
		-- Parity bit is checked as a logic high.  If Stick Parity bit is a logic
		-- low then Stick Parity is disabled.
		-- Parity Enable Bit	Number Of Stop Bits	Total Bits
		--         1                 0                11
		--         1                 1                12
		if ParityEnableBit = '0' then
			ParityError <= '0';
		elsif StickParityBit = '1' and EvenParitySelectBit = '0' and NumberOfStopBits = '0' then
			if receiveShiftRegister(10) = '1' then
				ParityError <= '0';
			else
				ParityError <= '1';
			end if;
		elsif StickParityBit = '1' and EvenParitySelectBit = '1' and NumberOfStopBits = '0' then
			if receiveShiftRegister(10) = '0' then
				ParityError <= '0';
			else
				ParityError <= '1';
			end if;
		elsif StickParityBit = '1' and EvenParitySelectBit = '0' and NumberOfStopBits = '1' then
			if receiveShiftRegister(9) = '1' then
				ParityError <= '0';
			else
				ParityError <= '1';
			end if;
		elsif StickParityBit = '1' and EvenParitySelectBit = '1' and NumberOfStopBits = '1' then
			if receiveShiftRegister(9) = '0' then
				ParityError <= '0';
			else
				ParityError <= '1';
			end if;
		elsif EvenParitySelectBit = '0' then
			if receiveOneBitsCountRegister = '1' then
				ParityError <= '0';
			else
				ParityError <= '1';
			end if;
		else	-- EvenParitySelectBit = '1'
			if receiveOneBitsCountRegister = '0' then
				ParityError <= '0';
			else
				ParityError <= '1';
			end if;
		end if;
		
		-- Generate the framing error signals by looking for a logic low start bit
		-- and logic high stop bit(s).  The placement of the start and stop bit(s)
		-- within the shift register to based on the number of bits received as
		-- illustrated in the following table:
		-- Parity Enable Bit	Number Of Stop Bits	Total Bits
		--         0                 0                10
		--         0                 1                11
		--         1                 0                11
		--         1                 1                12
		if ParityEnableBit = '0' and NumberOfStopBits = '0' then
			if receiveShiftRegister(2) = '0' and receiveShiftRegister(11) = '1' then
				FramingError <= '0';
			else
				FramingError <= '1';
			end if;
		elsif ParityEnableBit = '0' and NumberOfStopBits = '1' then
			if receiveShiftRegister(1) = '0' and receiveShiftRegister(10) = '1' and receiveShiftRegister(11) = '1' then
				FramingError <= '0';
			else
				FramingError <= '1';
			end if;
		elsif ParityEnableBit = '1' and NumberOfStopBits = '0' then
			if receiveShiftRegister(1) = '0' and receiveShiftRegister(11) = '1' then
				FramingError <= '0';
			else
				FramingError <= '1';
			end if;
		else	-- ParityEnableBit = '1' and NumberOfStopBits = '1'
			if receiveShiftRegister(0) = '0' and receiveShiftRegister(10) = '1' and receiveShiftRegister(11) = '1' then
				FramingError <= '0';
			else
				FramingError <= '1';
			end if;
		end if;
		
		-- Generate the data byte received.  The placement of the byte within the
		-- shift register to based on the number of bits received as illustrated
		-- in the following table:
		-- Parity Enable Bit	Number Of Stop Bits	Total Bits
		--         0                 0                10
		--         0                 1                11
		--         1                 0                11
		--         1                 1                12
		if ParityEnableBit = '0' and NumberOfStopBits = '0' then
			ReceivedData(7 downto 0) <= receiveShiftRegister(10 downto 3);
		elsif ParityEnableBit = '0' and NumberOfStopBits = '1' then
			ReceivedData(7 downto 0) <= receiveShiftRegister(9 downto 2);
		elsif ParityEnableBit = '1' and NumberOfStopBits = '0' then
			ReceivedData(7 downto 0) <= receiveShiftRegister(9 downto 2);
		else	-- ParityEnableBit = '1' and NumberOfStopBits = '1'
			ReceivedData(7 downto 0) <= receiveShiftRegister(8 downto 1);
		end if;
		
		-- Put the contents of the RTS register onto the RTS pin.
		nRtsPin <= receiveRtsRegister;
	end process Receive;
end architecture Behavioral;
