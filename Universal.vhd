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
-- File: Universal.vhd
--
-- Description:
-- Contains universal information for the project.
---------------------------------------------------------------------------------
-- DJB 03/25/19 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Universal is
	--Baud Rate Selects:
	constant SELECT_1200 : std_logic_vector(2 downto 0) := "000";
	constant SELECT_2400 : std_logic_vector(2 downto 0) := "001";
	constant SELECT_4800 : std_logic_vector(2 downto 0) := "010";
	constant SELECT_9600 : std_logic_vector(2 downto 0) := "011";
	constant SELECT_19200 : std_logic_vector(2 downto 0) := "100";
	constant SELECT_38400 : std_logic_vector(2 downto 0) := "101";
	constant SELECT_57600 : std_logic_vector(2 downto 0) := "110";
	constant SELECT_115200 : std_logic_vector(2 downto 0) := "111";

	--Baud Rate 8x Counter Values:
	constant MAX_COUNT_1200 : unsigned(11 downto 0) := to_unsigned(3839, 12);
	constant MAX_COUNT_2400 : unsigned(11 downto 0) := to_unsigned(1919, 12);
	constant MAX_COUNT_4800 : unsigned(11 downto 0) := to_unsigned(959, 12);
	constant MAX_COUNT_9600 : unsigned(11 downto 0) := to_unsigned(479, 12);
	constant MAX_COUNT_19200 : unsigned(11 downto 0) := to_unsigned(239, 12);
	constant MAX_COUNT_38400 : unsigned(11 downto 0) := to_unsigned(119, 12);
	constant MAX_COUNT_57600 : unsigned(11 downto 0) := to_unsigned(79, 12);
	constant MAX_COUNT_115200 : unsigned(11 downto 0) := to_unsigned(39, 12);

	--Addresses:
	constant TRANSMIT_DATA_REGISTER_ADDRESS : std_logic_vector(1 downto 0) := "00";
	constant RECEIVE_DATA_REGISTER_ADDRESS : std_logic_vector(1 downto 0) := "00";
	constant CONTROL_REGISTER_ADDRESS : std_logic_vector(1 downto 0) := "01";
	constant STATUS_REGISTER_ADDRESS : std_logic_vector(1 downto 0) := "10";
end package Universal;

package body Universal is

end package body Universal;
