# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3

# [yes/no]
DEBUG=no

XDEBUG=
ifeq ($(DEBUG),yes)
	XDEBUG:="-debug"
endif

all:
	ruby Shuriken.rb

gothic:
	cutechess-cli -variant gothic	-engine cmd="ruby Shuriken.rb" dir=. proto=xboard -engine cmd="ruby Shuriken.rb -random" dir=. proto=xboard -each tc=40/2 -rounds 100 $(XDEBUG)

capablanca:
	cutechess-cli -variant capablanca -engine cmd="ruby Shuriken.rb" dir=. proto=xboard -engine cmd="ruby Shuriken.rb -random" dir=. proto=xboard -each tc=40/2 -rounds 100	$(XDEBUG)

caparandom:
	cutechess-cli -variant caparandom -engine cmd="ruby Shuriken.rb" dir=. proto=xboard -engine cmd="ruby Shuriken.rb -random" dir=. proto=xboard -each tc=40/2 -rounds 100	$(XDEBUG)

falconx:
	xboard -cp -variant falcon -fcp "ruby Shuriken.rb" -scp "ruby Shuriken.rb -random" $(XDEBUG)

clean:
	rm -f games.pgn xboard.debug Shuriken-error.txt Shuriken-log.txt
