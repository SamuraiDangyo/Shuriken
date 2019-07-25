##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

##
# Definitions
##

# User Debug [01]
DEBUG=0

XDEBUG=#nada
ifeq ($(DEBUG),1)
	XDEBUG:="-debug"
endif

##
# Targets
##

gothic: clean
	cutechess-cli \
		-variant gothic \
		-engine cmd="ruby shuriken.rb -xboard" dir=. proto=xboard \
		-engine cmd="ruby shuriken.rb -randommode -xboard" dir=. proto=xboard \
		-each tc=40/2 \
		-rounds 100 \
		-pgnout games.pgn \
		$(XDEBUG)
		
capablanca: clean
	cutechess-cli \
		-variant capablanca \
		-engine cmd="ruby shuriken.rb -xboard" dir=. proto=xboard \
		-engine cmd="ruby shuriken.rb -randommode -xboard" dir=. proto=xboard \
		-each tc=40/2 \
		-rounds 100 \
		-pgnout games.pgn \
		$(XDEBUG)
		
caparandom: clean
	cutechess-cli \
		-variant caparandom \
		-engine cmd="ruby shuriken.rb -xboard" dir=. proto=xboard \
		-engine cmd="ruby shuriken.rb -randommode -xboard" dir=. proto=xboard \
		-each tc=40/2 \
		-rounds 100 \
		-pgnout games.pgn \
		$(XDEBUG)

fairycapa: clean
	cutechess-cli \
		-variant capablanca \
		-engine cmd=fairymax proto=xboard \
		-engine cmd="ruby shuriken.rb -xboard" dir=. proto=xboard \
		-each tc=40/2 \
		-rounds 1 \
		-pgnout games.pgn \
		$(XDEBUG)
		
fairygothic: clean
	cutechess-cli \
		-variant gothic \
		-engine cmd="ruby shuriken.rb -xboard" dir=. proto=xboard \
		-engine cmd=fairymax proto=xboard \
		-each tc=40/2 \
		-rounds 100 \
		-pgnout games.pgn \
		$(XDEBUG)

falconx: clean
	xboard -cp \
		-variant falcon \
		-fcp "ruby shuriken.rb -xboard" \
		-scp "ruby shuriken.rb -randommode -xboard" \
		$(XDEBUG)

caparandomx: clean
	xboard -cp \
		-variant caparandom \
		-fcp "ruby shuriken.rb -xboard" \
		-scp "ruby shuriken.rb -randommode -xboard" \
		$(XDEBUG)

gothicx: clean
	xboard -cp \
		-variant gothic \
		-fcp "ruby shuriken.rb -xboard" \
		-scp "ruby shuriken.rb -randommode -xboard" \
		$(XDEBUG)

capablancax: clean
	xboard -cp \
		-variant capablanca \
		-fcp "ruby shuriken.rb -xboard" \
		-scp "ruby shuriken.rb -randommode -xboard" \
		$(XDEBUG)
		
xboard: clean
	xboard -cp \
		-fcp "ruby shuriken.rb -xboard" \
		-scp "ruby shuriken.rb -randommode -xboard" \
		$(XDEBUG)
		
fairyx: clean
	xboard -cp \
		-fcp "ruby shuriken.rb -xboard" \
		-scp fairymax \
		$(XDEBUG)
	
run: clean
	ruby shuriken.rb

mbenchgothic: clean
	ruby shuriken.rb -variant gothic -mbench
	
mbenchfalcon: clean
	ruby shuriken.rb -variant falcon -mbench
	
profile: clean
	ruby shuriken.rb -profile
	
stats: clean
	ruby shuriken.rb -stats 10
	
rubybench: clean
	ruby shuriken.rb -rubybench
	
bench: clean
	ruby shuriken.rb -bench
	
mbench: clean
	ruby shuriken.rb -variant capablanca -mbench
	
test: clean
	ruby shuriken.rb -test
	
falcontest: clean
	ruby shuriken.rb -variant falcon -xboard
	
tactics: clean
	ruby shuriken.rb -tactics
	
clean:
	rm -f games.pgn xboard.debug shuriken-error.txt shuriken-log.txt
