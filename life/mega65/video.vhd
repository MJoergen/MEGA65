library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
   use work.video_modes_pkg.all;

entity video is
   generic (
      G_FONT_FILE  : string;
      G_ROWS       : integer;
      G_COLS       : integer;
      G_VIDEO_MODE : video_modes_type
   );
   port (
      clk_i         : in    std_logic;
      rst_i         : in    std_logic;
      board_i       : in    std_logic_vector(G_ROWS * G_COLS - 1 downto 0);
      video_vs_o    : out   std_logic;
      video_hs_o    : out   std_logic;
      video_de_o    : out   std_logic;
      video_red_o   : out   std_logic_vector(7 downto 0);
      video_green_o : out   std_logic_vector(7 downto 0);
      video_blue_o  : out   std_logic_vector(7 downto 0)
   );
end entity video;

architecture synthesis of video is

   signal pixel_x : std_logic_vector(G_VIDEO_MODE.PIX_SIZE - 1 downto 0);
   signal pixel_y : std_logic_vector(G_VIDEO_MODE.PIX_SIZE - 1 downto 0);
   signal vs      : std_logic;
   signal hs      : std_logic;
   signal de      : std_logic;
   signal vs_d1   : std_logic;
   signal hs_d1   : std_logic;
   signal de_d1   : std_logic;
   signal vs_d2   : std_logic;
   signal hs_d2   : std_logic;
   signal de_d2   : std_logic;
   signal vs_d3   : std_logic;
   signal hs_d3   : std_logic;
   signal de_d3   : std_logic;
   signal pixel   : std_logic_vector(7 downto 0);

begin

   video_sync_inst : entity work.video_sync
      generic map (
         G_VIDEO_MODE => G_VIDEO_MODE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         vs_o      => vs,
         hs_o      => hs,
         de_o      => de,
         pixel_x_o => pixel_x,
         pixel_y_o => pixel_y
      ); -- video_sync_inst

   -- Latency 3 clock cycles
   digits_inst : entity work.digits
      generic map (
         G_FONT_FILE  => G_FONT_FILE,
         G_ROWS       => G_ROWS,
         G_COLS       => G_COLS,
         G_VIDEO_MODE => G_VIDEO_MODE
      )
      port map (
         clk_i    => clk_i,
         digits_i => board_i,
         pix_x_i  => pixel_x,
         pix_y_i  => pixel_y,
         pixel_o  => pixel
      ); -- digits_inst

   video_red_o   <= pixel;
   video_green_o <= pixel;
   video_blue_o  <= pixel;

   delay_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         vs_d1 <= vs;
         hs_d1 <= hs;
         de_d1 <= de;

         vs_d2 <= vs_d1;
         hs_d2 <= hs_d1;
         de_d2 <= de_d1;

         vs_d3 <= vs_d2;
         hs_d3 <= hs_d2;
         de_d3 <= de_d2;
      end if;
   end process delay_proc;

   video_vs_o    <= vs_d3;
   video_hs_o    <= hs_d3;
   video_de_o    <= de_d3;

end architecture synthesis;

