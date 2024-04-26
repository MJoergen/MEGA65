library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity life is
   generic (
      G_ROWS       : integer;
      G_COLS       : integer;
      G_CELLS_INIT : std_logic_vector
   );
   port (
      -- Clock, reset, and enable
      rst_i    : in    std_logic;
      clk_i    : in    std_logic;
      en_i     : in    std_logic;

      -- The current board status
      board_o  : out   std_logic_vector(G_ROWS * G_COLS - 1 downto 0);

      -- Controls the individual cells of the board
      index_i  : in    integer range G_ROWS * G_COLS - 1 downto 0;
      value_i  : in    std_logic;
      update_i : in    std_logic
   );
end entity life;

architecture structural of life is

   constant C_CELLS : integer := G_ROWS * G_COLS;

   subtype  ROW_T     is integer range 0 to G_ROWS - 1;
   subtype  COL_T     is integer range 0 to G_COLS - 1;
   subtype  INDEX_T   is integer range 0 to C_CELLS - 1;

   subtype count_t is integer range 0 to 8;

   function to_index (
      row : ROW_T;
      col : COL_T
   ) return INDEX_T is
   begin
      return row * G_COLS + col;
   end function to_index;

   function get_row (
      index : INDEX_T
   ) return ROW_T is
   begin
      return index / G_COLS;
   end function get_row;

   function get_col (
      index : INDEX_T
   ) return COL_T is
   begin
      return index rem G_COLS;
   end function get_col;


   subtype  BOARD_T is std_logic_vector(C_CELLS - 1 downto 0);
   signal   board : BOARD_T := (others => '0');

   subtype  NEIGHBOURS_T is std_logic_vector(7 downto 0);
   --    type cell_neighbours_t is array (natural range <>) of neighbours_t;
   --    signal cell_neighbours : cell_neighbours_t(board'range);


   -- This is the logic of the game:
   -- 1. Any live cell with fewer than two live neighbours dies, as if caused by under-population.
   -- 2. Any live cell with two or three live neighbours lives on to the next generation.
   -- 3. Any live cell with more than three live neighbours dies, as if by overcrowding.
   -- 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

   function new_cell (
      neighbours : count_t;
      cur_cell : std_logic
   ) return std_logic is
      constant C_BIRTH   : std_logic_vector(count_t) := "000100000"; -- The fate of dead cells.
      constant C_SURVIVE : std_logic_vector(count_t) := "001100000"; -- The fate of live cells.
   begin

      case cur_cell is

         when '1' =>
            return C_SURVIVE(neighbours);

         when others =>
            return C_BIRTH(neighbours);

      end case;

      return '0';
   end function new_cell;


   function get_neighbours (
      board_v : BOARD_T;
      index_v : INDEX_T
   ) return NEIGHBOURS_T is

      constant C_N   : integer := -G_COLS;
      constant C_S   : integer := G_COLS;
      constant C_W   : integer := -1;
      constant C_E   : integer := 1;
      constant C_NW  : integer := C_N + C_W;
      constant C_NE  : integer := C_N + C_E;
      constant C_SW  : integer := C_S + C_W;
      constant C_SE  : integer := C_S + C_E;

      pure function UP(index : index_t) return index_t is
      begin
         if get_row(index) = 0 then
            return index + C_N + C_CELLS;
         else
            return index + C_N;
         end if;
      end function UP;

      pure function DOWN(index : index_t) return index_t is
      begin
         if get_row(index) = G_ROWS-1 then
            return index + C_S - C_CELLS;
         else
            return index + C_S;
         end if;
      end function DOWN;

      pure function LEFT(index : index_t) return index_t is
      begin
         if get_col(index) = 0 then
            return index + C_W + G_COLS;
         else
            return index + C_W;
         end if;
      end function LEFT;

      pure function RIGHT(index : index_t) return index_t is
      begin
         if get_col(index) = G_COLS-1 then
            return index + C_E - G_COLS;
         else
            return index + C_E;
         end if;
      end function RIGHT;

   begin
      return (board_v(UP(index_v)),
              board_v(DOWN(index_v)),
              board_v(LEFT(index_v)),
              board_v(RIGHT(index_v)),
              board_v(UP(RIGHT(index_v))),
              board_v(DOWN(RIGHT(index_v))),
              board_v(UP(LEFT(index_v))),
              board_v(DOWN(LEFT(index_v))));
   end function get_neighbours;

   function count_ones (
      input : std_logic_vector(7 downto 0)
   ) return count_t is
      --
      type     count_ones_type is array (0 to 15) of count_t;
      constant C_COUNT_ONES_4 : count_ones_type := (0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4);
   begin
      return C_COUNT_ONES_4(to_integer(input(3 downto 0))) + C_COUNT_ONES_4(to_integer(input(7 downto 4)));
   end function count_ones;

begin

   board_o <= board;

   -- This holds the actual cells
   life_proc : process (clk_i)
      variable neighbour_count_v : count_t;
   begin
      if rising_edge(clk_i) then
         if en_i = '1' then
            for index in board'range loop
               neighbour_count_v := count_ones(get_neighbours(board, index));
               board(index)      <= new_cell(neighbour_count_v, board(index));
            end loop;
         end if;
         if update_i = '1' then
            board(index_i) <= value_i;
         end if;
         if rst_i = '1' then
            board <= G_CELLS_INIT;
         end if;
      end if;
   end process life_proc;

end architecture structural;

