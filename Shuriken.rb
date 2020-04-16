# Shuriken, a Ruby chess variant engine
# Copyright Toni Helminen
# GPLv3

module Shuriken

NAME = "Shuriken 0.42"

class Board
  def brd2str
    str, empty, counter = "", 0, 0
    80.times do |j|
      i = 10 * (7 - j / 10) + ( j % 10 )
      piece = @brd[i]
      if piece != 0
        if empty > 0
          str += empty.to_s
          empty = 0
        end
        str += "fcakqrbnp.PNBRQKACF"[piece + 9]
      else
        empty += 1
      end
      counter += 1
      if counter % 10 == 0
        str += empty.to_s if empty > 0
        str += "/" if counter < 80
        empty = 0
      end
    end
    str
  end

  def wtm2str
    @wtm ? "w" : "b"
  end

  def castle2str
    return "-" if @castle == 0
    str = ""
    if @variant == "cabarandom"
      alphas = "ABCDEFGHIJ"
      str += alphas[@castle_squares[1]] if @castle & 0x1 == 0x1
      str += alphas[@castle_squares[5]] if @castle & 0x2 == 0x2
      str += alphas[@castle_squares[1]].downcase if @castle & 0x4 == 0x4
      str += alphas[@castle_squares[5]].downcase if @castle & 0x8 == 0x8
    else
      str += @castle & 0x1 == 0x1 ? "K" : ""
      str += @castle & 0x2 == 0x2 ? "Q" : ""
      str += @castle & 0x4 == 0x4 ? "k" : ""
      str += @castle & 0x8 == 0x8 ? "q" : ""
    end
    str
  end

  def ep2str
    return "-" if @ep == -1
    "abcdefghijkl"[ @ep % 10 ] + (@ep / 10).to_s
  end

  def r502str
    @r50.to_s
  end

  def tofen
    "#{brd2str} #{wtm2str} #{castle2str} #{ep2str} #{r502str}"
  end
end # class Board

class MgenCaparandom
  ROOK_MOVES          = [[1, 0], [0, 1], [-1, 0], [0, -1]].freeze
  BISHOP_MOVES        = [[1, 1], [-1, 1], [1, -1], [-1, -1]].freeze
  KING_MOVES          = (ROOK_MOVES + BISHOP_MOVES).freeze
  KNIGHT_MOVES        = [[1, 2], [-1, 2], [1, -2], [-1, -2], [2, 1], [-2, 1], [2, -1], [-2, -1]].freeze
  MOVE_TYPE_CASTLING  = 1
  MOVE_TYPE_PROMO     = 2
  MOVE_TYPE_EP        = 5

  attr_accessor :pseudo_moves, :only_captures

  def initialize(board)
    @board, @moves            = board, []
    @x_gen, @y_gen, @from_gen = 0, 0, 0 # move generation
    @x_checks, @y_checks  = 0, 0 # checks
    @pseudo_moves         = false # 3x speed up
    @only_captures        = false # generate only captures
    @promotion_to         = @board.variant == "falcon" ? [2, 3, 4, 5, 9] : [2, 3, 4, 5, 7, 8]
    @promotion_to.freeze
  end

  # Utils

  def print_move_list
    @moves.each_with_index do |board, i| puts "#{i + 1}: #{board.move_str}"  end
  end

  def is_on_board?(x, y)
    (x >= 0 && x <= 9 && y >= 0 && y <= 7) ? true : false
  end

  def good_coord?(pos)
    (pos >= 0 && pos <= 79) ? true : false
  end

  def y_coord(pos)
    pos / 10
  end

  def x_coord(pos)
    pos % 10 # ...
  end

  # Checks

  def pawn_checks_w?(here)
    [-1, 1].each do |dir|
      px, py = @x_checks + dir, @y_checks + 1
      return true if is_on_board?(px, py) && px + py * 10 == here
    end
    false
  end

  def pawn_checks_b?(here)
    [-1, 1].each do |dir|
      px, py = @x_checks + dir, @y_checks - 1
      return true if is_on_board?(px, py) && px + py * 10 == here
    end
    false
  end

  def slider_checks_to?(slider, here)
    slider.each do |jmp|
      px, py = @x_checks, @y_checks
      while true do
        px, py = px + jmp[0], py + jmp[1]
        to = px + py * 10
        break if ! is_on_board?(px, py)
        return true if to == here
        break if ! @board.empty?(to)
      end
    end
    false
  end

  def jump_checks_to?(jumps, here)
    jumps.each do |jmp|
      px, py = @x_checks + jmp[0], @y_checks + jmp[1]
      to = px + py * 10
      return true if is_on_board?(px, py) && to == here
    end
    false
  end

  def any_black_checks_here?(no_checks)
    no_checks.each { |square| return true if checks_b?(square) }
    false
  end

  def any_white_checks_here?(no_checks)
    no_checks.each { |square| return true if checks_w?(square) }
    false
  end

  def falcon_checks?(here)
    Shuriken::FalconMoves::MOVES.each do |mv|
      px1, py1 = @x_checks + mv[0], @y_checks + mv[1]
      to1 = px1 + 10 * py1
      px2, py2 = px1 + mv[2], py1 + mv[3]
      to2 = px2 + 10 * py2
      px3, py3 = px2 + mv[4], py2 + mv[5]
      to3 = px3 + 10 * py3
      return true if (is_on_board?(px1, py1) && @board.empty?(to1) && is_on_board?(px2, py2) && @board.empty?(to2) && is_on_board?(px3, py3) && to3 == here)
    end
    false
  end

  def checks_w?(here)
    80.times do |sq|
      @x_checks, @y_checks = x_coord(sq), y_coord(sq)
      case @board.brd[sq]
      when 1 then  return true if pawn_checks_w?(here)
      when 2 then  return true if jump_checks_to?(KNIGHT_MOVES, here)
      when 3 then  return true if slider_checks_to?(BISHOP_MOVES, here)
      when 4 then  return true if slider_checks_to?(ROOK_MOVES, here)
      when 5 then  return true if slider_checks_to?(ROOK_MOVES + BISHOP_MOVES, here)
      when 6 then  return true if jump_checks_to?(KING_MOVES, here)
      when 7 then  return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(BISHOP_MOVES, here)
      when 8 then  return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(ROOK_MOVES, here)
      when 9 then return true if falcon_checks?(here)
      end
    end
    false
  end

  def checks_b?(here)
    80.times do | i |
      @x_checks, @y_checks = x_coord(i), y_coord(i)
      case @board.brd[i]
      when -1 then return true if pawn_checks_b?(here)
      when -2 then return true if jump_checks_to?(KNIGHT_MOVES, here)
      when -3 then return true if slider_checks_to?(BISHOP_MOVES, here)
      when -4 then return true if slider_checks_to?(ROOK_MOVES, here)
      when -5 then return true if slider_checks_to?(ROOK_MOVES + BISHOP_MOVES, here)
      when -6 then return true if jump_checks_to?(KING_MOVES, here)
      when -7 then return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(BISHOP_MOVES, here)
      when -8 then return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(ROOK_MOVES, here)
      when -9 then return true if falcon_checks?(here)
      end
    end
    false
  end
end # class MgenCaparandom

class MgenCaparandomWhite < Shuriken::MgenCaparandom
  def initialize(board)
    super board
  end

  def add_new_move(me, to, type_of_move = 0)
    fail unless good_coord?(to)
    board2 = @board
    copy = @board.copy_me
    copy.from = @from_gen
    copy.to = to
    copy.eat = copy.brd[to]
    fail "Can't eat king" if copy.eat == -6
    return if @only_captures && copy.eat >= 0
    copy.wtm = ! copy.wtm
    ep = copy.ep
    copy.ep = -1
    copy.r50 += 1
    copy.promo = type_of_move == MOVE_TYPE_PROMO ? me : 0
    copy.castled = 0
    copy.brd[@from_gen] = 0
    copy.brd[to] = me
    copy.r50 = 0 if copy.eat != 0
    if me == 1
      copy.r50 = 0
      copy.ep = @from_gen + 10 if type_of_move == MOVE_TYPE_EP
      copy.brd[to - 10] = 0 if to == ep
    elsif me == 6
      copy.castle &= 0x4 | 0x8
      if type_of_move == MOVE_TYPE_CASTLING
        if to == 8
          copy.castled = 1
          copy.brd[copy.castle_squares[1]] = 0 if copy.castle_squares[1] != to
          copy.brd[to - 1] = 4
        else
          copy.castled = 2
          copy.brd[copy.castle_squares[1 + 4]] = 0 if copy.castle_squares[1 + 4] != to
          copy.brd[to + 1] = 4
        end
      end
    end
    @board = copy
    if @pseudo_moves
      @moves.push << copy
    elsif !checks_b?(@board.find_white_king)
      copy.handle_castle_rights
      @moves.push << copy
    end
    @board = board2
  end

  def add_new_pawn_move(to)
    if to >= 70
      @promotion_to.each do | i |
        add_new_move(i, to, MOVE_TYPE_PROMO)
      end
    else
      add_new_move(1, to)
    end
  end

  def generate_pawn_moves_1
    to = @x_gen + (@y_gen + 1) * 10
    add_new_pawn_move(to) if (to < 80 && @board.empty?(to))
  end

  def generate_pawn_moves_2
    to = @from_gen + 2 * 10
    add_new_move(1, to, MOVE_TYPE_EP) if (y_coord(@from_gen) == 1 && @board.empty?(to - 10) && @board.empty?(to))
  end

  def generate_pawn_eat_moves
    [-1, 1].each do | dir |
      px, py = @x_gen + dir, @y_gen + 1
      if is_on_board?(px, py)
        to = px + py * 10
        if @board.black?(to)
          add_new_pawn_move(to)
        elsif @board.ep > 0 && to == @board.ep
          add_new_pawn_move(to)
        end
      end
    end
  end

  def generate_pawn_moves
    generate_pawn_moves_1
    generate_pawn_moves_2
    generate_pawn_eat_moves
  end

  def generate_jump_moves(jumps, me = 2)
    jumps.each do | jmp |
      px, py = @x_gen + jmp[0], @y_gen + jmp[1]
      to = px + py * 10
      add_new_move(me, to) if (is_on_board?(px, py) && @board.walkable_w?(to))
    end
  end

  def generate_slider_moves(slider, me = 3)
    slider.each do | jmp |
      px, py = @x_gen, @y_gen
      loop do
        px, py = px + jmp[0], py + jmp[1]
        break if !is_on_board?(px, py)
        to = px + py * 10
        add_new_move(me, to) if @board.walkable_w?(to)
        break if !@board.empty?(to)
      end
    end
  end

  def generate_falcon_moves
    isin = []
    Shuriken::FalconMoves::MOVES.each do | mv |
      px1, py1 = @x_gen + mv[0], @y_gen + mv[1]
      to1 = px1 + py1 * 10
      px2, py2 = px1 + mv[2], py1 + mv[3]
      to2 = px2 + py2 * 10
      px3, py3 = px2 + mv[4], py2 + mv[5]
      to3 = px3 + py3 * 10
      if is_on_board?(px1, py1) && @board.empty?(to1) && is_on_board?(px2, py2) && @board.empty?(to2) \
          and is_on_board?(px3, py3) && @board.walkable_w?(to3) && !isin.include?(to3)
        add_new_move(9, to3)
        isin.push << to3
      end
    end
  end

  def generate_castle_OO_moves
    return unless @board.castle & 0x1 == 0x1
    king, rook = @board.castle_squares[0], @board.castle_squares[1]
    return unless (@board.brd[king] == 6 && @board.brd[rook] == 4)
    castle_square = @board.castle_squares[2]
    direction = @board.castle_squares[3]
    no_checks = [castle_square] # calculate no checks squares
    position = king
    loop do
      no_checks.push << position
      return if (position != king && position != rook && @board.brd[position] != 0)
      break if position == castle_square
      position += direction
    end
    return if ![0, 6].include?(@board.brd[7])
    return if any_black_checks_here? no_checks
    add_new_move(6, castle_square, MOVE_TYPE_CASTLING)
  end

  def generate_castle_OOO_moves
    return unless @board.castle & 0x2 == 0x2
    king, rook = @board.castle_squares[0 + 4], @board.castle_squares[1 + 4]
    return unless (@board.brd[king] == 6 && @board.brd[rook] == 4)
    castle_square = @board.castle_squares[2 + 4]
    direction = @board.castle_squares[3 + 4]
    no_checks = [castle_square] # calculate no checks squares
    position = king
    loop do
      no_checks.push << position
      return if (position != king && position != rook && @board.brd[position] != 0)
      break if position == castle_square
      position += direction
    end
    return if ![0, 6].include?(@board.brd[3])
    return if (rook == 0 && @board.brd[1] != 0) # space between rook && castle square
    return if any_black_checks_here?(no_checks)
    add_new_move(6, castle_square, MOVE_TYPE_CASTLING)
  end

  def generate_moves
    @moves = []
    80.times do | i |
      @x_gen, @y_gen, @from_gen = x_coord(i), y_coord(i), i
      case @board.brd[i]
      when 1 then generate_pawn_moves
      when 2 then generate_jump_moves(KNIGHT_MOVES, 2)
      when 3 then generate_slider_moves(BISHOP_MOVES, 3)
      when 4 then generate_slider_moves(ROOK_MOVES, 4)
      when 5 then  generate_slider_moves(BISHOP_MOVES + ROOK_MOVES, 5)
      when 6 then
        generate_jump_moves(KING_MOVES, 6)
        generate_castle_OO_moves
        generate_castle_OOO_moves
      when 7
        generate_jump_moves(KNIGHT_MOVES, 7)
        generate_slider_moves(BISHOP_MOVES, 7)
      when 8
        generate_jump_moves(KNIGHT_MOVES, 8)
        generate_slider_moves(ROOK_MOVES, 8)
      when 9
        generate_falcon_moves
      end
    end
    @moves#.dup
  end
end # class MgenCaparandomWhite

class Engine
  RESULT_DRAW      = 1
  RESULT_BLACK_WIN = 2
  RESULT_WHITE_WIN = 4

  def init_mate_bonus
    @mate_bonus = [1] * 100
    (0..20).each { |i| @mate_bonus[i] += 20 - i }
    @mate_bonus[0] = 50
    @mate_bonus[1] = 40
    @mate_bonus[2] = 30
    @mate_bonus[3] = 25
  end

  def history_reset
    @history.reset
  end

  def history_remove
    @board = @history.remove
  end

  def history_undo
    @board = @history.undo
  end

  def print_move_list(moves)
    moves.each_with_index do |board, i| puts "#{i+1}. #{board.move_str} : #{board.score}" end
  end

  def move_list
    mgen  = @board.mgen_generator
    moves = mgen.generate_moves
    moves.each_with_index do |board, i| puts "#{i+1}. #{board.move_str} : #{board.score}" end
  end
end # class Engine

class BoardCaparandom < Shuriken::Board
  GOTHIC_POS = "rnbqckabnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNBQCKABNR w KQkq - 0 1"
  CAPA_POS   = "rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1"
  FALCON_POS = "rnbfqkfbnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNBFQKFBNR w KQkq - 0 1"

  PIECES = {
    ".":  0, # .
    "P":  1, # Pawn
    "p": -1,
    "N":  2, # Knight
    "n": -2,
    "B":  3, # Bishop
    "b": -3,
    "R":  4, # Rook
    "r": -4,
    "Q":  5, # Queen
    "q": -5,
    "K":  6, # King
    "k": -6,
    "A":  7, # Arcbishop
    "a": -7,
    "C":  8, # Chancellor
    "c": -8,
    "F":  9, # Falcon
    "f": -9
  }.freeze

  attr_accessor :brd, :variant, :nodetype, :hash, :ep, :wtm, :eat, :from, :to, :castle, :castle_squares, :r50, :score, :promo, :castled, :index

  def initialize(variant)
    @variant = variant
    initme
  end

  def initme
    @brd = [0] * 80
    @castle, @ep, @wtm, @from, @to, @r50, @eat = 0, -1, true, 0, 0, 0, 0
    @score, @promo, @castled = 0, 0, 0
    # white O-O   : [ king_pos, rook_pos, castle_square, direction ]
    # white O-O-O : [ king_pos, rook_pos, castle_square, direction ]
    @castle_squares           = [-1] * 2 * 4
    @index, @hash, @nodetype  = 0, 0, 0 # 2: draw 1: win -1: loss
  end

  def mgen_generator
    @wtm ? Shuriken::MgenCaparandomWhite.new(self) : Shuriken::MgenCaparandomBlack.new(self)
  end

  def create_hash
    @hash = 0
    80.times do | i | @hash ^= Shuriken::Zobrist.get(20 * i + 8 + @brd[i]) end
    @hash ^= Shuriken::Zobrist.get(20 * 80 + (@wtm ? 1 : 0)) ^ Shuriken::Zobrist.get(20 * 81 + (@ep == -1 ? 1 : 0)) ^ Shuriken::Zobrist.get(20 * 82 + @castle)
  end

  # TODO write castling stuff
  def legal?
    pieces = [0] * 20
    @brd.each { |piece| pieces[piece + 9] += 1 }
    return false if pieces[-6 + 9] == 0 || pieces[6 + 9] == 0
    true
  end

  def move_str
    return "O-O" if (@castled == 1 && @variant == "caparandom")
    return "O-O-O" if (@castled == 2 && @variant == "caparandom")
    fromx, fromy = x_coord(@from), y_coord(@from)
    tox, toy = x_coord(@to), y_coord(@to)
    str = ("a".ord + fromx).chr << (fromy + 1).to_s << ("a".ord + tox).chr << (toy + 1).to_s
    ps = @variant == "falcon" ? "nbrqkkkf" : "nbrqkac"
    if @promo > 1
      str << ps[@promo - 2]
    elsif @promo < -1
      str << ps[-@promo - 2]
    end
    str
  end

  def make_move(me, from, to)
    fail unless (good_coord?(from) && good_coord?(to))
    @eat = @brd[to]
    @ep = -1
    @r50 += 1
    @brd[to], @brd[from] = me, 0
    @r50 = 0 if @eat
    if @wtm
      if me == 1
        @r50 = 0
        @ep = from + 10 if (y_coord(from) == 1 && y_coord(to) == 3)
      elsif me == 6
        @castle &= 0x4 | 0x8
      end
    else
      if me == -1
        @r50 = 0
        @ep = from - 10 if (y_coord(from) == 8 - 2 && y_coord(to) == 8 - 4)
      elsif me == -6
        @castle &= 0x1 | 0x2
      end
    end
    handle_castle_rights
  end

  def find_white_king
    @brd.index { |x| x == 6 }
  end

  def find_black_king
    @brd.index { |x| x == -6 }
  end

  def find_piece_all(piece)
    @brd.index { |x| x == piece }
  end

  def find_piece(start_square, end_square, me, diff = 1)
    start = start_square
    loop do
      return start if @brd[start] == me
      fail "Couldn't Find: '#{me}'" if start == end_square
      start += diff
    end
  end

  def just_kings?
    80.times do |sq| return false if (@brd[sq] != 6 && @brd[sq] != -6) end
    true
  end

  def material_draw?
    80.times do |sq| return false if (@brd[sq] != 6 && @brd[sq] != -6 && @brd[sq] != 0) end
    true
  end

  def handle_castle_rights
    if @castle & 0x1 == 0x1
      @castle &= (0x2 | 0x4 | 0x8) if @brd[@castle_squares[1]] != 4
    end
    if @castle & 0x2 == 0x2
      @castle &= (0x1 | 0x4 | 0x8) if @brd[@castle_squares[1 + 4]] != 4
    end
    if @castle & 0x4 == 0x4
      @castle &= (0x1 | 0x2 | 0x8) if @brd[70 + @castle_squares[1]] != -4
    end
    if @castle & 0x8 == 0x8
      @castle &= (0x1 | 0x2 | 0x4) if @brd[70 + @castle_squares[1 + 4]] != -4
    end
  end

  def make_castle_squares
    if @castle & 0x1 == 0x1
      king          = find_piece(0, 10 - 1, 6, 1)
      rook_r        = find_piece(king, 10 - 1, 4, 1)
      castle_square = 10 - 2
      @castle_squares[0] = king
      @castle_squares[1] = rook_r
      @castle_squares[2] = castle_square
      @castle_squares[3] = king < castle_square ? 1 : -1
    end
    if @castle & 0x2 == 0x2
      king          = find_piece(0, 10 - 1, 6, 1)
      rook_l        = find_piece(king, 0, 4, -1)
      castle_square = 2
      @castle_squares[4] = king
      @castle_squares[5] = rook_l
      @castle_squares[6] = castle_square
      @castle_squares[7] = king < castle_square ? 1 : -1
    end
    if @castle & 0x4 == 0x4
      king          = find_piece(10 * 8 - 10, 10 * 8 - 1, -6, 1)
      rook_r        = find_piece(king, 10 * 8 - 1, -4, 1)
      castle_square, pos = 10 * 8 - 2, 10 * 8 - 10
      @castle_squares[0] = king - pos
      @castle_squares[1] = rook_r - pos
      @castle_squares[2] = castle_square - pos
      @castle_squares[3] = king < castle_square ? 1 : -1
    end
    if @castle & 0x8 == 0x8
      king          = find_piece(10 * 8 - 10, 10 * 8 - 1, -6, 1)
      rook_l        = find_piece(king, 10 * 8 - 10, -4, -1)
      castle_square, pos = 10 * 8 - 10 + 2, 10 * 8 - 10
      @castle_squares[4] = king - pos
      @castle_squares[5] = rook_l - pos
      @castle_squares[6] = castle_square - pos
      @castle_squares[7] = king < castle_square ? 1 : -1
    end
  end

  def copy_me()
    copy = Shuriken::BoardCaparandom.new(@variant)
    copy.brd, copy.castle_squares, copy.castle, copy.ep, copy.wtm, copy.from, copy.to = @brd.dup, @castle_squares.dup, @castle, @ep, @wtm, @from, @to
    copy
  end

  def startpos(spos)
    pos = case spos
      when "gothic"
        GOTHIC_POS
      when "capablanca"
        CAPA_POS
      when "falcon"
        FALCON_POS
      else
        CAPA_POS
    end
    use_fen(pos)
  end

  def use_fen(pos)
    initme
    fen(pos)
    make_castle_squares
  end

  def y_coord(pos)
    pos / 10
  end

  def x_coord(pos)
    pos % 10 # ...
  end

  def last_rank?(square)
    y_coord(square) == 7 ? true : false
  end

  def first_rank?(x)
    y_coord(x) == 0 ? true : false
  end

  def empty?(pos)
    @brd[pos] == 0 ? true : false
  end

  def walkable_w?(square)
    @brd[square] < 1 ? true : false
  end

  def walkable_b?(square)
    @brd[square] > -1 ? true : false
  end

  def black?(square)
    @brd[square] < 0 ? true : false
  end

  def white?(square)
    @brd[square] > 0 ? true : false
  end

  def is_on_board?(x, y)
    (x >= 0 && x < 10 && y >= 0 && y < 8) ? true : false
  end

  def good_coord?(pos)
    (pos >= 0 && pos < 80) ? true : false
  end

  def mirror_board
    half = ((10 * 8) / 2 - 1).to_i
    (0..half).each do | i |
      x, y = x_coord(i), y_coord(i)
      flip_y = x + (8 - 1 - y) * 10
      p1 = @brd[i]
      p2 = @brd[flip_y]
      @brd[i] = p2
      @brd[flip_y] = p1
    end
  end

  def flip_coord(coord)
    (8 - 1 - y_coord(coord)) * 10 + x_coord(coord)
  end

  def fen_board(str)
    pos = 0
    str.gsub(/\d+/) { | m | "_" * m.to_i }
      .gsub(/\//) { | m | "" }
      .each_char do | c |
        PIECES.each do | piece, num |
          if c == piece.to_s
            @brd[pos] = num
            break
          end
        end
        pos += 1
      end
  end

  def fen_wtm(str)
    @wtm = str == "w" ? true : false
  end

  def fen_KQkq(str)
    found = false
    str.each_char do | ch |
      {0x1 => "K", 0x2 => "Q", 0x4 => "k", 0x8 => "q"}.each do | hex, kqkq |
        if ch == kqkq
          @castle |= hex
          found = true
        end
      end
    end
    return if found

    wking, bking = find_piece_all(6) - 70, find_piece_all(-6)
    str.each_char do | ch |
      if ("A".."J").include? ch
        num = ch.ord - "A".ord
        @castle |= num > wking ? 0x1 : 0x2
      elsif ("a".."j").include? ch
        num = ch.ord - "a".ord
        @castle |= num > bking ? 0x4 : 0x8
      end
    end
  end

  def fen_ep(str)
    return if (str == "-" or str.length < 2)
    @ep = (str[0].ord - "a".ord) + 10 * str[1].to_i
  end

  def fen_r50(str)
    @r50 = str.to_i
  end

  def fen(str)
    initme
    str = str.strip.split(" ")
    fen_board(str[0]) if str.length >= 0
    fen_wtm(str[1])   if str.length >= 1
    fen_KQkq(str[2])  if str.length >= 2
    fen_ep(str[3])    if str.length >= 3
    fen_r50(str[4])   if str.length >= 4
    mirror_board
  end

  def str_castle
    str = ""
    {"K" => 0x1, "Q" => 0x2, "k" => 0x4, "q" => 0x8}.each do |a, b| str += a if @castle.to_i & b == b end
    str.empty? ? "-" : str
  end

  def material
    Shuriken::EvalCaparandom.material(self)
  end

  def print_board
    str, flip_it = "", false
    80.times do |sq|
      x, y = x_coord(sq), y_coord(sq)
      piece = @brd[x + (8 - y - 1) * 10]
      if flip_it
        piece = -@brd[x + y * 10]
      end
      ch = "."
      PIECES.each do |piece2, num|
        if num.to_s == piece.to_s
          ch = piece2.to_s
        end
      end
      str << ch
       if (sq + 1) % 10 == 0
      str << " " + ((8 - sq / 10).to_i).to_s + "\n"
       end
    end
    10.times { |i| str << ("a".ord + i).chr }
    puts str << "\n[ wtm: #{@wtm} ]\n" << "[ castle: #{str_castle} ]\n" << "[ ep: #{@ep} ]\n\n"
  end
end # class BoardCaparandom

class EngineCaparandom < Shuriken::Engine
  attr_accessor :board, :random_mode, :gameover, :move_now, :debug, :time, :movestogo, :printinfo

  INF            = 1000
  MATERIAL_SCALE = 0.01

  def initialize(variant, random_mode: false)
    init_mate_bonus
    @board        = Shuriken::BoardCaparandom.new(variant)
    @random_mode  = random_mode
    @history      = Shuriken::History.new
    @board.startpos(variant)
    @printinfo, @time, @movestogo, @stop_time, @stop_search, @nodes, @move_now, @debug, @gameover = true, 10, 40, 0, false, 0, false, false, false
  end

  def make_move?(move)
    mgen  = @board.mgen_generator
    moves = mgen.generate_moves
    moves.each do |board|
      if board.move_str == move
        @history.add(board)
        @board = board
        return true
      end
    end
    puts "illegal move: #{move}"
    false
    #fail "Shuriken Error: Illegal Move: '#{move}'"
  end

  def print_score(moves, depth, started)
    return unless @printinfo
    moves = moves.sort_by(&:score).reverse
    best = moves[0]
    n = (100 * (Time.now - started)).to_i
    puts " #{depth}     #{(best.score).to_i}     #{n}     #{@nodes}     #{best.move_str}"
  end

  def search_moves_w(cur, depth, total = 0)
    @nodes += 1
    @stop_search = (Time.now > @stop_time || total > 90)
    return 0 if @stop_search
    return MATERIAL_SCALE * cur.material if depth < 1
    mgen = Shuriken::MgenCaparandomWhite.new(cur)
    moves = mgen.generate_moves
    if moves.length == 0 # assume mate
      return 0.1 * @mate_bonus[total] * -INF
    end
    search_moves_b(moves.sample, depth - 1, total + 1)
  end

  def search_moves_b(cur, depth, total = 0)
    @nodes += 1
    @stop_search = (Time.now > @stop_time || total > 90)
    return 0 if @stop_search
    return MATERIAL_SCALE * cur.material if depth < 1
    mgen = Shuriken::MgenCaparandomBlack.new(cur)
    moves = mgen.generate_moves
    if moves.length == 0 # assume mate
      return 0.1 * @mate_bonus[total] * INF
    end
    search_moves_w(moves.sample, depth - 1, total + 1)
  end

  def search(moves)
    now = Time.now
    time4print = 0.5
    #@stop_time = now + (@time / ((@movestogo < 1 ? 30 : @movestogo) + 2)) # no time losses
    divv = @movestogo < 10 ? 20 : 30
    @stop_time = now + (@time / divv)
    depth = 2
    while true
      moves.each do | board |
        puts "> #{@nodes} / #{board.move_str}" if @debug
        next if board.nodetype == 2
        depth = 3 + rand(20)
        board.score += board.wtm ? search_moves_w(board, depth, 0) : search_moves_b(board, depth, 0)
        if Time.now > @stop_time || @move_now
          print_score(moves, depth, now)
          return
        end
      end
      if Time.now - now > time4print
        now = Time.now
        print_score(moves, depth, now)
      end
    end
  end

  def draw_moves(moves)
    moves.each do | board |
      if @history.is_draw?(board)
        board.nodetype, board.score = 2, 0
      end
    end
  end

  def hash_moves(moves)
    moves.each { |board| board.create_hash }
  end

  def game_status(mgen, moves)
    if moves.length == 0
      if @board.wtm && mgen.checks_b?(@board.find_white_king)
        return Shuriken::Engine::RESULT_BLACK_WIN
      elsif !@board.wtm && mgen.checks_w?(@board.find_black_king)
        return Shuriken::Engine::RESULT_WHITE_WIN
      end
      return Shuriken::Engine::RESULT_DRAW
    end
    @board.create_hash
    if @history.is_draw?(@board, 3) || @board.material_draw?
      return Shuriken::Engine::RESULT_DRAW
    end
    0
  end

  def is_gameover?(mgen, moves)
    @board.create_hash
    if @history.is_draw?(@board, 3)
      puts "1/2-1/2 {Draw by repetition}"
      return true
    end
    if moves.length == 0
      if @board.wtm && mgen.checks_b?(@board.find_white_king)
        puts "0-1 {Black mates}"
      elsif ! @board.wtm && mgen.checks_w?(@board.find_black_king)
        puts "1-0 {White mates}"
      end
      puts "1/2-1/2 {Stalemate}"
      return true
    end
    false
  end

  def think
    @nodes    = 0
    @move_now = false
    @history.reset
    board    = @board
    mgen     = @board.mgen_generator
    moves    = mgen.generate_moves
    hash_moves(moves)
    draw_moves(moves)
    func = -> { board.wtm ? moves.sort_by(&:score).reverse : moves.sort_by(&:score) }
    @gameover = is_gameover?(mgen, moves)
    return if @gameover
    if @random_mode
      @board = moves.sample
    else
      search(moves)
      moves = func.call
      @board = moves[0]
    end
    print_move_list(moves) if @debug
    @history.add(@board)
    @board.move_str
  end
end # class EngineCaparandom

module EvalCaparandom
  MATERIAL_SCORE = {
    1 => 1,
    2 => 3,
    3 => 3,
    4 => 5,
    5 => 9,
    6 => 6,
    7 => 8,
    8 => 8
  }

  def EvalCaparandom.material(board)
    score = 0
    board.brd.each do |piece|
      score += case piece
        when 1..8 then    MATERIAL_SCORE[ piece]
        when -8..-1 then -MATERIAL_SCORE[-piece]
        else 0 end
    end
    score
  end
end # module EvalCaparandom

module FalconMoves
  MOVES = []

  def FalconMoves.init
    return if MOVES.length > 0
    [
      [[ 1,  0], [ 1,  1]],
      [[ 1,  0], [ 1, -1]],
      [[-1,  0], [-1,  1]],
      [[-1,  0], [-1, -1]],
      [[ 0,  1], [ 1,  1]],
      [[ 0,  1], [-1,  1]],
      [[ 0, -1], [-1, -1]],
      [[ 0, -1], [ 1, -1]]
    ].each do | o |
      s, d = o[0], o[1]
      # ssd,dss,sds,dsd,dds,sdd
      MOVES.push(s + s + d)
      MOVES.push(d + d + s)
      MOVES.push(d + s + s)
      MOVES.push(s + d + d)
      MOVES.push(s + d + s)
      MOVES.push(d + s + d)
    end
    MOVES.freeze
  end
end # module FalconMoves

module Fen
  # RR NN BB Q C K A
  def Fen.make_caparandom_pos
    str = "." * 10
    put_piece = -> { i = rand(10); i = rand(10) while s[i] != "."; i }

    king      = rand(1..8)
    l_rook    = rand(king)
    r_rook    = king + 1 + rand([1, 9 - (king + 1)].max)
    str[king]   = "k"
    str[l_rook] = "r"
    str[r_rook] = "r"

    fail if r_rook == king || l_rook == king

    wb = put_piece.()
    str[wb] = "b"

    bb = rand(10)
    while str[bb] != "." || bb % 2 == wb % 2
      bb = rand(10)
    end
    str[bb] = "b"

    %|acnnq|.each_char { |piece| str[put_piece.()] = piece }

    pieces = str
    str << "/" + "p" * 10 << "/10" * 4 << "/" + "P" * 10 << "/" + pieces.upcase << " w " << ("A".ord + r_rook).chr << ("A".ord + l_rook).chr << ("a".ord + r_rook).chr << ("a".ord + l_rook).chr << " - 0"
  end
end # module Fen

class History
  def initialize
    reset
  end

  def reset
    @data = []
    @pos = -1
  end

  def debug
    puts "@pos: #{@pos} .. @data: #{@data.length}"
  end

  def remove
    if @pos > 1
      board = @data[@pos - 2]
      @pos -= 2
      return board
    end
    @data.last
  end

  def undo
    if @pos > 0
      board = @data[@pos - 1]
      @pos -= 1
      return board
    end
    @data.last
  end

  def add(board)
    @data.push(board)
    @pos += 1
  end

  def is_draw?(board, repsn = 2)
    len, hash = @data.length, board.hash
    i, n, reps = len - 1, 0, 0
    return true if board.r50 >= 99
    while i > 0
      break if n >= 100
      reps += 1 if hash == @data[i].hash
      n, i = n + 1, i - 1
      return true if reps >= repsn
    end
    false
  end
end # class History

class MgenCaparandomBlack < Shuriken::MgenCaparandom
  def initialize(board)
    super(board)
  end

  def add_new_move(me, to, type_of_move = 0)
    fail unless good_coord?(to)
    board2 = @board
    copy = @board.copy_me
    copy.from = @from_gen
    copy.to = to
    copy.eat = copy.brd[to]
    fail "Can't eat king" if copy.eat == 6
    return if @only_captures && copy.eat <= 0
    copy.wtm = ! copy.wtm
    ep = copy.ep
    copy.ep = -1
    copy.r50 += 1
    copy.promo = type_of_move == MOVE_TYPE_PROMO ? me : 0
    copy.castled = 0
    copy.brd[@from_gen] = 0
    copy.brd[to] = me
    copy.r50 = 0 if copy.eat != 0
    if me == -1
      copy.r50 = 0
      copy.ep = @from_gen - 10 if type_of_move == MOVE_TYPE_EP
      copy.brd[to + 10] = 0 if to == ep
    elsif me == -6
      copy.castle &= 0x1 | 0x2
      if type_of_move == MOVE_TYPE_CASTLING
        if to == 70 + 8
          copy.castled = 1
          copy.brd[70 + copy.castle_squares[1]] = 0 if 70 + copy.castle_squares[1] != to
          copy.brd[to - 1] = -4
        else
          copy.castled = 2
          copy.brd[70 + copy.castle_squares[1 + 4]] = 0 if 70 + copy.castle_squares[1 + 4] != to
          copy.brd[to + 1] = -4
        end
      end
    end
    @board = copy
    if @pseudo_moves
      @moves.push << copy
    elsif !checks_w?(@board.find_black_king)
      copy.handle_castle_rights
      @moves.push << copy
    end
    @board = board2
  end

  # have to check promos
  def add_new_pawn_move(to)
    if to < 10
      @promotion_to.each { |i| add_new_move(-1 * i, to, MOVE_TYPE_PROMO) }
    else
      add_new_move(-1, to)
    end
  end

  def generate_pawn_moves_1
    to = @x_gen + (@y_gen - 1) * 10
    add_new_pawn_move(to) if (to >= 0 && @board.empty?(to))
  end

  def generate_pawn_moves_2
    to = @from_gen - 2 * 10
    add_new_move(-1, to, MOVE_TYPE_EP) if (y_coord(@from_gen) == 7 - 1 && @board.empty?(to + 10) && @board.empty?(to))
  end

  def generate_pawn_eat_moves
    [-1, 1].each do |dir|
      px, py = @x_gen + dir, @y_gen - 1
      if is_on_board?(px, py)
        to = px + py * 10
        if @board.white?(to)
          add_new_pawn_move(to)
        elsif @board.ep > 0 && to == @board.ep
          add_new_pawn_move(to)
        end
      end
    end
  end

  def generate_pawn_moves
    generate_pawn_moves_1
    generate_pawn_moves_2
    generate_pawn_eat_moves
  end

  def generate_jump_moves(jumps, me = -2)
    jumps.each do |jmp|
      px, py = @x_gen + jmp[0], @y_gen + jmp[1]
      to = px + py * 10
      add_new_move(me, to) if (is_on_board?(px, py) && @board.walkable_b?(to))
    end
  end

  def generate_slider_moves(slider, me = -3)
    slider.each do |jmp|
      px, py = @x_gen, @y_gen
      loop do
        px, py = px + jmp[0], py + jmp[1]
        break if !is_on_board?(px, py)
        to = px + py * 10
        add_new_move(me, to) if @board.walkable_b?(to)
        break if !@board.empty?(to)
      end
    end
  end

  def generate_falcon_moves
    isin = []
    Shuriken::FalconMoves::MOVES.each do |mv|
      px1, py1 = @x_gen + mv[0], @y_gen + mv[1]
      to1 = px1 + py1 * 10
      px2, py2 = px1 + mv[2], py1 + mv[3]
      to2 = px2 + py2 * 10
      px3, py3 = px2 + mv[4], py2 + mv[5]
      to3 = px3 + py3 * 10
      if (is_on_board?(px1, py1) && @board.empty?(to1) && is_on_board?(px2, py2) && @board.empty?(to2) \
          && is_on_board?(px3, py3) && @board.walkable_b?(to3) && !isin.include?(to3))
        add_new_move(-9, to3)
        isin.push << to3
      end
    end
  end

  def generate_castle_OO_moves
    return unless @board.castle & 0x4 == 0x4
    king, rook = 70 + @board.castle_squares[0], 70 + @board.castle_squares[1]
    return unless (@board.brd[king] == -6 && @board.brd[rook] == -4)
    castle_square = 70 + @board.castle_squares[2]
    direction = @board.castle_squares[3]

    no_checks = [castle_square] # calculate no checks squares
    position = king
    loop do
      no_checks.push << position
      return if (position != king && position != rook && @board.brd[position] != 0)
      break if position == castle_square
      position += direction
    end
    return if ![0, -6].include?(@board.brd[70 + 7])

    return if any_white_checks_here?(no_checks)
    add_new_move(-6, castle_square, MOVE_TYPE_CASTLING)
  end

  # setboard r2qck3r/ppp1pp1ppp/2n1bapn2/3p6/10/7P2/PPPPPPP1PP/RNBQC1KBNR b kq - 3 8
  def generate_castle_OOO_moves
    return unless @board.castle & 0x8 == 0x8
    king, rook = 70 + @board.castle_squares[0 + 4], 70 + @board.castle_squares[1 + 4]
    return unless (@board.brd[king] == -6 && @board.brd[rook] == -4)
    castle_square = 70 + @board.castle_squares[2 + 4]
    direction = @board.castle_squares[3 + 4]

    no_checks = [castle_square] # calculate no checks squares
    position = king
    loop do
      no_checks.push << position
      return if (position != king && position != rook && @board.brd[position] != 0)
      break if position == castle_square
      position += direction
    end

    return if ![0, -6].include?(@board.brd[70 + 3])
    return if rook == 70 && @board.brd[71] != 0 # space between rook && castle square
    return if any_white_checks_here?(no_checks)
    add_new_move(-6, castle_square, MOVE_TYPE_CASTLING)
  end

  def generate_moves
    @moves = []
    80.times do |sq|
      @x_gen, @y_gen, @from_gen = x_coord(sq), y_coord(sq), sq
      case @board.brd[sq]
      when -1 then generate_pawn_moves
      when -2 then generate_jump_moves(KNIGHT_MOVES, -2)
      when -3 then generate_slider_moves(BISHOP_MOVES, -3)
      when -4 then generate_slider_moves(ROOK_MOVES, -4)
      when -5 then generate_slider_moves(BISHOP_MOVES + ROOK_MOVES, -5)
      when -6
        generate_jump_moves(KING_MOVES, -6)
        generate_castle_OO_moves
        generate_castle_OOO_moves
      when -7
        generate_jump_moves(KNIGHT_MOVES, -7)
        generate_slider_moves(BISHOP_MOVES, -7)
      when -8
        generate_jump_moves(KNIGHT_MOVES, -8)
        generate_slider_moves(ROOK_MOVES, -8)
      when -9
        generate_falcon_moves
      end
    end
    @moves#.dup
  end
end # class MgenCaparandomBlack

class Xboard
  def initialize(variant, random_mode = false)
    @variant        = variant
    @random_mode    = random_mode
    @engine         = Shuriken::EngineCaparandom.new(variant, random_mode: random_mode)
    @movestogo_orig = 40
    @forcemode      = false
    Signal.trap("SIGPIPE", "SYSTEM_DEFAULT")
    trap("INT", "IGNORE") # no interruptions
  end

  def print_xboard
    rv = @random_mode ? " random" : ""
    puts "feature myname=\"#{Shuriken::NAME}#{rv}\""
    puts "feature variants=\"capablanca,gothic,caparandom,falcon\""
    puts "feature setboard=1"
    puts "feature ping=1"
    puts "feature done=1"
  end

  def play
    @engine.think
  end

  def update_movestogo
    if @engine.movestogo == 1
      @engine.movestogo =  @movestogo_orig
    elsif @engine.movestogo > 0
      @engine.movestogo -= 1
    end
  end

  def cmd_variant(variant)
    @variant = variant
    @engine = Shuriken::EngineCaparandom.new(@variant, random_mode: @random_mode)
  end

  def cmd_new
    @engine.history_reset
    @engine = Shuriken::EngineCaparandom.new(@variant, random_mode: @random_mode)
    @canmakemove = true
  end

  def cmd_level(level)
    @engine.movestogo = level.to_i
    @movestogo_orig = @engine.movestogo
  end

  def cmd_go
    if @canmakemove
      puts "move #{play}"
      @canmakemove = false
    end
  end

  def cmd_move(move)
    update_movestogo # update counter
    if @engine.make_move?(move)
      @canmakemove = true
      if @canmakemove && ! @engine.gameover
        puts "move #{play}"
        @canmakemove = false
      end
    end
  end

  def go
    puts "#{Shuriken::NAME} by Toni Helminen"
    @movestogo_orig, @canmakemove = 40, true
    $stdin.each do |cmd|
      cmd.strip!
      case cmd
      when "xboard", "hard", "easy", "random", "nopost", "post", "white", "black", /^computer/, /^st/, /^otim/, /^accepted/, /^result/ then
        # ignore
      when "remove"             then @engine.history_remove
      when "undo"               then @engine.history_undo
      when "?"                  then @engine.move_now = true
      when /^protover/          then print_xboard
      when /^ping\s+(.*)/       then puts "pong #{$1}"
      when /^variant\s+(.*)/    then cmd_variant($1)
      when "new"                then cmd_new
      when "list"               then @engine.move_list
      when /^level\s+(.+)\s+.*/ then cmd_level($1)
      when /^time\s+(.+)/       then @engine.time = 0.01 * $1.to_i
      when /^setboard\s+(.+)/   then @engine.board.use_fen($1)
      when "quit"               then return
      when "p"                  then @engine.board.print_board
      when "force"              then @forcemode = true
      when "go"                 then cmd_go
      else # assume move
        cmd_move(cmd)
      end
    end
  end
end # class Xboard

module Zobrist
  HASH = []

  def Zobrist.init
    return if HASH.length > 0
    10_000.times do | i | HASH.push(rand(1024) | (rand(1024) << 10) | (rand(1024) << 20) | (rand(1024) << 30) | (rand(1024) << 40)) end
  end

  def Zobrist.get(n)
    HASH[n]
  end
end # module Zobrist

class Cmd
  attr_accessor :engine, :random_mode

  def initialize
    @variant      = "caparandom" # default
    @random_mode  = false
    @fen          = "rnbqckabnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNBQCKABNR w KQkq - 0 1"
  end

  def xboard
    xboard = Shuriken::Xboard.new(@variant, @random_mode)
    xboard.go
  end

  def args
    if ARGV.length == 1 and ARGV[0] == "-version"
      puts "#{Shuriken::NAME} by Toni Helminen"
      return
    elsif ARGV.length == 1 and ARGV[0] == "-random"
      @random_mode = true
    end
    xboard
  end
end # class Cmd

module Main
  def Main.init
    $stdout.sync              = true
    Thread.abort_on_exception = true
    Shuriken::Zobrist.init
    Shuriken::FalconMoves.init
  end

  def Main.go
    cmd = Shuriken::Cmd.new
    cmd.args
  end
end # module Main
end # module Shuriken

if __FILE__ == $0
  Shuriken::Main.init # init just once
  Shuriken::Main.go
end
