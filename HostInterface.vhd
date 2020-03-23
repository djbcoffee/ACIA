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
-- File: HostInterface.vhd
--
-- Description:
-- The interface to the host system.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use work.universal.all;

entity HostInterface is
	port 
	(
		Clock, CSPin, nCSPin, RnWPin : in std_logic;
		HostAddressPins : in std_logic_vector(1 downto 0);
		StatusRegisterBus : in std_logic_vector(5 downto 0);
		ReceiveDataRegisterBus, ControlRegisterBus : in std_logic_vector(7 downto 0);
		HostWritePulse, HostReceiveDataReadPulse : out std_logic;
		HostWriteAddress : out std_logic_vector(1 downto 0);
		HostWriteData : out std_logic_vector(7 downto 0);
		HostDataPins : inout std_logic_vector(7 downto 0)
	);
end HostInterface;

architecture Behavioral of HostInterface is
	signal OutputEnable : std_logic;
	
	signal HostDataIn : std_logic_vector(7 downto 0);
	signal OutputData : std_logic_vector(7 downto 0);
	signal HostWriteAddressHold : std_logic_vector(1 downto 0);
	signal HostReceiveDataReadSync : std_logic_vector(1 downto 0);
	signal HostWriteSync : std_logic_vector(1 downto 0);
	signal HostWriteDataHold : std_logic_vector(7 downto 0);
begin
	-- Uses primitives for the output and input buffers that are specific to the
	-- XC9500XL series CPLD.  The output buffer uses the active low enable.
	DataBusOutBufferBit0 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(0), I => OutputData(0), T => OutputEnable);
	DataBusOutBufferBit1 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(1), I => OutputData(1), T => OutputEnable);
	DataBusOutBufferBit2 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(2), I => OutputData(2), T => OutputEnable);
	DataBusOutBufferBit3 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(3), I => OutputData(3), T => OutputEnable);
	DataBusOutBufferBit4 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(4), I => OutputData(4), T => OutputEnable);
	DataBusOutBufferBit5 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(5), I => OutputData(5), T => OutputEnable);
	DataBusOutBufferBit6 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(6), I => OutputData(6), T => OutputEnable);
	DataBusOutBufferBit7 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(7), I => OutputData(7), T => OutputEnable);
		
	DataBusInBufferBit0 : IBUF
		port map (O => HostDataIn(0), I => HostDataPins(0));
	DataBusInBufferBit1 : IBUF
		port map (O => HostDataIn(1), I => HostDataPins(1));
	DataBusInBufferBit2 : IBUF
		port map (O => HostDataIn(2), I => HostDataPins(2));
	DataBusInBufferBit3 : IBUF
		port map (O => HostDataIn(3), I => HostDataPins(3));
	DataBusInBufferBit4 : IBUF
		port map (O => HostDataIn(4), I => HostDataPins(4));
	DataBusInBufferBit5 : IBUF
		port map (O => HostDataIn(5), I => HostDataPins(5));
	DataBusInBufferBit6 : IBUF
		port map (O => HostDataIn(6), I => HostDataPins(6));
	DataBusInBufferBit7 : IBUF
		port map (O => HostDataIn(7), I => HostDataPins(7));

	Interface : process (Clock, RnWPin, CSPin, nCSPin, HostAddressPins, ReceiveDataRegisterBus, ControlRegisterBus, StatusRegisterBus) is
		variable hostWriteAddressHoldRegister : std_logic_vector(1 downto 0) := (others => '0');
		variable hostReceiveDataReadSyncRegister : std_logic_vector(2 downto 0) := (others => '0');
		variable hostWriteSyncRegister : std_logic_vector(2 downto 0) := (others => '1');
		variable hostWriteDataHoldRegister : std_logic_vector(7 downto 0) := (others => '0');
	begin
		-- Internal Module Signals
		-- ========================================================================
		-- Outputs from registers.
		HostWriteAddressHold <= hostWriteAddressHoldRegister;
		HostReceiveDataReadSync <= hostReceiveDataReadSyncRegister(1 downto 0);
		HostWriteSync <= hostWriteSyncRegister(1 downto 0);
		HostWriteDataHold <= hostWriteDataHoldRegister;

		-- Host Write Events
		-- ========================================================================
		-- Check if any host writes are in progress.  On the rising edge of the R/W
		-- pin, while the chip is selected, the state of the address and data bus
		-- pins are stored.
		if RnWPin'event and RnWPin = '1' then
			if CSPin = '1' and nCSPin = '0' then
				hostWriteAddressHoldRegister := HostAddressPins;
				hostWriteDataHoldRegister := HostDataIn;
			else
				hostWriteAddressHoldRegister := HostWriteAddressHold;
				hostWriteDataHoldRegister := HostWriteDataHold;
			end if;
		end if;
		
		-- System Clock Events
		-- ========================================================================
		if Clock'event and Clock = '1' then
			-- A three-stage register that is used to synchronize a receive data
			-- register read event.  The first register in the stage connects
			-- directly to the chip select, RnW, and address pins.  This register
			-- will take any metastability issues that may occur from the async read
			-- changing in relation to the system clock.  The second and third
			-- registers are used to detect the state of the signal.  The second and
			-- third registers are protected from metastability and their outputs
			-- can be reliably used as synchronous signals.  All together the three
			-- registers are connected in a shift configuration.
			hostReceiveDataReadSyncRegister(2) := HostReceiveDataReadSync(1);
			hostReceiveDataReadSyncRegister(1) := HostReceiveDataReadSync(0);
			if CSPin = '1' and nCSPin = '0' and RnWPin = '1' and HostAddressPins = RECEIVE_DATA_REGISTER_ADDRESS then
				hostReceiveDataReadSyncRegister(0) := '1';
			else
				hostReceiveDataReadSyncRegister(0) := '0';
			end if;
		end if;
		
		if Clock'event and Clock = '1' then
			-- A three-stage register that is used to synchronize the write
			-- indication signal.  The first register in the stage connects directly
			-- to the output of the write indication register.  This register will
			-- take any metastability issues that may occur from the async write
			-- indication signal changing in relation to the system clock.  The
			-- second and third registers are used to detect rising and falling
			-- edges from the output of the first register.  The second and third
			-- registers are protected from metastability and their outputs can be
			-- reliably used as synchronous signals.  All together the three
			-- registers are connected in a shift configuration.
			hostWriteSyncRegister(2) := HostWriteSync(1);
			hostWriteSyncRegister(1) := HostWriteSync(0);
			if CSPin = '1' and nCSPin = '0' and RnWPin = '0' then
				hostWriteSyncRegister(0) := '0';
			else
				hostWriteSyncRegister(0) := '1';
			end if;
		end if;
	
		-- Data Pins Tri-state Event
		-- ========================================================================
		-- If the chip is selected for a read operation then turn on the output
		-- driver and output the requested data.
		if RnWPin = '1' and CSPin = '1' and nCSPin = '0' then
			-- Enable the output drivers.
			OutputEnable <= '0';
			
			-- Based on the current address output the requested data.
			if HostAddressPins = RECEIVE_DATA_REGISTER_ADDRESS then
				OutputData <= ReceiveDataRegisterBus;
			elsif HostAddressPins = CONTROL_REGISTER_ADDRESS then
				OutputData <= ControlRegisterBus;
			elsif HostAddressPins = STATUS_REGISTER_ADDRESS then
				OutputData(5 downto 0) <= StatusRegisterBus;
				OutputData(6) <= '0';
				OutputData(7) <= '0';
			else
				OutputData <= (others => '0');
			end if;
		else
			-- Disable the output driver and clear outputs.
			OutputEnable <= '1';
			OutputData <= (others => '0');
		end if;
		
		-- External Module Signals
		-- ========================================================================
		-- Will pulse when a rising edge is detected from the host write sync
		-- circuit.  Pulse lasts for one system clock cycle.
		HostWritePulse <= hostWriteSyncRegister(1) and not hostWriteSyncRegister(2);
		
		-- The second and third registers of the sync register are used to detect
		-- that the signal has remained active long enough.  This ensures that the
		-- status register receive data register full flag is not cleared
		-- accidentally by a glitch or the like.  Remains logic high so long as the
		-- chip is selected for a read of the receive data register.
		HostReceiveDataReadPulse <= hostReceiveDataReadSyncRegister(1) and hostReceiveDataReadSyncRegister(2);
		
		-- Address that was latched from the address pins when a write occurred.
		HostWriteAddress <= hostWriteAddressHoldRegister;
		
		-- Data that was latched from the data pins when a write occurred.
		HostWriteData <= hostWriteDataHoldRegister;
	end process Interface;
end architecture Behavioral;
