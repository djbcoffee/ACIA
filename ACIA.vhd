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
-- File: ACIA.vhd
--
-- Description:
-- The internal structure of the ACIA in a Xilinx XC95144XL-10TQG100 CPLD.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ACIA is
	port
	(
		Clock, CSPin, nCSPin, RnWPin, RxPin, nCtsPin : in std_logic;
		HostAddressPins : in std_logic_vector(1 downto 0);
		TxPin, nRtsPin : out std_logic;
		HostDataPins : inout std_logic_vector(7 downto 0)
	);
end ACIA;

architecture Struct of ACIA is
	signal EvenParitySelectBit : std_logic;
	signal FramingError : std_logic;
	signal HandshakeEnableBit : std_logic;
	signal HostReceiveDataReadPulse : std_logic;
	signal HostWritePulse : std_logic;
	signal NumberOfStopBits : std_logic;
	signal ParityEnableBit : std_logic;
	signal ParityError : std_logic;
	signal ReceiveComplete : std_logic;
	signal ReceiveDataRegisterFullBit : std_logic;
	signal RxSamplePulse : std_logic;
	signal StartTransmission : std_logic;
	signal StickParityBit : std_logic;
	signal TransmitComplete : std_logic;
	signal TransmitCompleteBit : std_logic;
	signal TransmitDataRegisterEmptyBit : std_logic;
	signal TxShiftPulse : std_logic;
	
	signal BaudRateSelect : std_logic_vector(2 downto 0);
	signal ControlRegisterBus : std_logic_vector(7 downto 0);
	signal HostWriteAddress : std_logic_vector(1 downto 0);
	signal HostWriteData : std_logic_vector(7 downto 0);
	signal ReceiveDataRegisterBus : std_logic_vector(7 downto 0);
	signal ReceivedData : std_logic_vector(7 downto 0);
	signal StatusRegisterBus : std_logic_vector(5 downto 0);
	signal TransmitDataRegisterBus : std_logic_vector(7 downto 0);
begin
	BaudRateGenerator : entity work.BaudRateGenerator(Behavioral)
		port map (Clock, BaudRateSelect, TxShiftPulse, RxSamplePulse);
	ControlRegister : entity work.ControlRegister(Behavioral)
		port map (Clock, HostWritePulse, HostWriteAddress, HostWriteData, ParityEnableBit, EvenParitySelectBit, StickParityBit, NumberOfStopBits, HandshakeEnableBit, BaudRateSelect, ControlRegisterBus);
	HostInterface : entity work.HostInterface(Behavioral)
		port map (Clock, CSPin, nCSPin, RnWPin, HostAddressPins, StatusRegisterBus, ReceiveDataRegisterBus, ControlRegisterBus, HostWritePulse, HostReceiveDataReadPulse, HostWriteAddress, HostWriteData, HostDataPins);
	ReceiveDataRegister : entity work.ReceiveDataRegister(Behavioral)
		port map (Clock, ReceiveComplete, ReceivedData, ReceiveDataRegisterBus);
	Receiver : entity work.Receiver(Behavioral)
		port map (Clock, RxSamplePulse, ParityEnableBit, EvenParitySelectBit, StickParityBit, NumberOfStopBits, HandshakeEnableBit, ReceiveDataRegisterFullBit, RxPin, ReceiveComplete, ParityError, FramingError, nRtsPin, ReceivedData);
	StatusRegister : entity work.StatusRegister(Behavioral)
		port map (Clock, HostWritePulse, HostReceiveDataReadPulse, FramingError, ParityError, ReceiveComplete, StartTransmission, TransmitComplete, TxShiftPulse, HostWriteAddress, ReceiveDataRegisterFullBit, TransmitCompleteBit, TransmitDataRegisterEmptyBit, StatusRegisterBus);
	TransmitDataRegister : entity work.TransmitDataRegister(Behavioral)
		port map (Clock, HostWritePulse, HostWriteAddress, HostWriteData, TransmitDataRegisterBus);
	Transmitter : entity work.Transmitter(Behavioral)
		port map (Clock, TxShiftPulse, ParityEnableBit, EvenParitySelectBit, StickParityBit, NumberOfStopBits, HandshakeEnableBit, TransmitDataRegisterEmptyBit, TransmitCompleteBit, nCtsPin, TransmitDataRegisterBus, TransmitComplete, StartTransmission, TxPin);
end architecture Struct;
