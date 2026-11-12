---------------------------------------------------------------------------------
-- composite_sync by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
--
-- Generate composite sync and blank for tv mode from h/v syncs
--
---------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity video_sync is
port(
	clk32 : in std_logic;
	pause : in std_logic;
	hsync : in std_logic;
	vsync : in std_logic;
	ntsc  : in std_logic;
	wide  : in std_logic;
	noborder : in std_logic;
	hsync_out : out std_logic;
	vsync_out : out std_logic;
	hblank : out std_logic;
	vblank : out std_logic
);
end;

architecture struct of video_sync is

	signal clk_cnt : std_logic_vector(1 downto 0);
	signal vsync_r : std_logic;
	signal hsync_r : std_logic;
	signal hsync_r0 : std_logic;
	signal hblank_i : std_logic;
	signal vblank_i : std_logic;
	signal hblank_nb : std_logic_vector(2 downto 0);
	signal vblank_nb : std_logic_vector(2 downto 0);

begin

-- noborder: active display window only (40 columns x 25 rows).
-- VIC pixels change 2 clocks after dot_count, so the window is delayed to match.
hblank <= hblank_nb(0) when noborder = '1' else hblank_i;
vblank <= vblank_nb(0) when noborder = '1' else vblank_i;

process(clk32)
	variable  dot_count : integer range 0 to 1023 := 0;
	variable line_count : integer range 0 to 511 := 0;
	variable line_reset : std_logic := '0';
	begin
	if falling_edge(clk32) then
		hsync_r0 <= hsync;
		if hsync_r0 = '0' and hsync = '1' then
			clk_cnt <= "11";
		else
			clk_cnt <= clk_cnt + '1';
		end if;
	end if;

	if rising_edge(clk32) then
		hblank_nb(1 downto 0) <= hblank_nb(2 downto 1);
		vblank_nb(1 downto 0) <= vblank_nb(2 downto 1);

		if clk_cnt = "00" and pause = '0' then
			vsync_r <= vsync;
			hsync_r <= hsync;

			if hsync_r = '0' and hsync = '1' then
				dot_count := 0;
				if line_reset = '1' then
					line_count := 0;
					line_reset := '0';
				else
					line_count := line_count + 1;
				end if;
			else
				dot_count := dot_count + 1;
			end if;

			if vsync_r = '0' and vsync = '1' then
				line_reset := '1';
			end if;
			
			if ntsc = '1' then
				if dot_count     = 054 then hsync_out <= '0'; end if;
				if dot_count     = 016 then hsync_out <= '1';
					if line_count = 000 then vsync_out <= '1'; end if;
					if line_count = 004 then vsync_out <= '0'; end if;
				end if;

				if line_count = 000 then vblank_i <= '1'; end if;
				if line_count = 013 then vblank_i <= '0'; end if;

				if line_count = 238 then vblank_nb(2) <= '1'; end if;
				if line_count = 038 then vblank_nb(2) <= '0'; end if;
				if dot_count  = 475 then hblank_nb(2) <= '1'; end if;
				if dot_count  = 155 then hblank_nb(2) <= '0'; end if;

				if wide = '0' then
					if dot_count  = 516 then hblank_i <= '1'; end if;
					if dot_count  = 112 then hblank_i <= '0'; end if;
				else
					if dot_count  = 496 then hblank_i <= '1'; end if;
					if dot_count  = 132 then hblank_i <= '0'; end if;
				end if;
			else
				if dot_count     = 048 then hsync_out <= '0'; end if;
				if dot_count     = 010 then hsync_out <= '1';
					if line_count = 307 then vsync_out <= '1'; end if;
					if line_count = 311 then vsync_out <= '0'; end if;
				end if;

				if line_count = 298 then vblank_i <= '1'; end if;
				if line_count = 028 then vblank_i <= '0'; end if;

				if line_count = 262 then vblank_nb(2) <= '1'; end if;
				if line_count = 062 then vblank_nb(2) <= '0'; end if;
				if dot_count  = 459 then hblank_nb(2) <= '1'; end if;
				if dot_count  = 139 then hblank_nb(2) <= '0'; end if;

				if wide = '0' then
					if dot_count  = 489 then hblank_i <= '1'; end if;
					if dot_count  = 107 then hblank_i <= '0'; end if;
				else
					if dot_count  = 463 then hblank_i <= '1'; end if;
					if dot_count  = 133 then hblank_i <= '0'; end if;
				end if;
			end if;

		end if;
	end if;
end process;

end architecture;