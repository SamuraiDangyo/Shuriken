##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

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
	
	CENTRAL_BONUS_X = [1,2,3,4,5,5,4,3,2,1].freeze
	CENTRAL_BONUS_Y = [1,2,3,4,4,3,2,1].freeze
	
	CENTRAL_SCORE = {
		1 => 0.5,
		2 => 5,
		3 => 5,
		4 => 3,
		5 => 2,
		6 => 0.2,
		7 => 3,
		8 => 3
	}
	
	EVAL_PST_MG = []

	def EvalCaparandom.init
		return if EVAL_PST_MG.length > 0
		7.times do |i|
			arr = []
			79.times do |j|
				score = 0.1 * (MATERIAL_SCORE[i + 1] + 2 * CENTRAL_SCORE[i + 1] * (CENTRAL_BONUS_X[j % 10 ] + CENTRAL_BONUS_Y[j / 10]))
				arr.push(score)
			end
			EVAL_PST_MG.push(arr)
		end
		EVAL_PST_MG.freeze
	end
	
	def EvalCaparandom.eval(board)
		score = 0
		board.brd.each_with_index do |p, i|
			score += case p
				when 1 then
					EVAL_PST_MG[0][i]
				when 2 then
					EVAL_PST_MG[1][i]
				when 3 then
					EVAL_PST_MG[2][i]
				when 4 then
					EVAL_PST_MG[3][i]
				when 5 then
					EVAL_PST_MG[4][i]
				when 6 then
					EVAL_PST_MG[5][i]
				when 7 then
					EVAL_PST_MG[6][i]
				when 8 then
					EVAL_PST_MG[7][i]
				when -1 then
					-EVAL_PST_MG[0][board.flip_coord(i)]
				when -2 then
					-EVAL_PST_MG[1][board.flip_coord(i)]
				when -3 then
					-EVAL_PST_MG[2][board.flip_coord(i)]
				when -4 then
					-EVAL_PST_MG[3][board.flip_coord(i)]
				when -5 then
					-EVAL_PST_MG[4][board.flip_coord(i)]
				when -6 then
					-EVAL_PST_MG[5][board.flip_coord(i)]
				when -7 then
					-EVAL_PST_MG[6][board.flip_coord(i)]
				when -8 then
					-EVAL_PST_MG[7][board.flip_coord(i)]
				else
					0
				end
		end
		#score += 0.05 * rand()
		0.01 * score
	end
	
	def EvalCaparandom.material(board)
		score = 0
		board.brd.each do |p|
			score += case p
				when 1..8 then
					MATERIAL_SCORE[p]
				when -8..-1 then
					-MATERIAL_SCORE[-p]
				else
					0
				end
		end
		score
	end
end # module EvalCaparandom

end # module Shuriken
