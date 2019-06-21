CC = gcc
LEX = flex
BISON = bison

CFLAGS = -DYYDEBUG=1

BIN = program
SRC = parser.y lex.l
OBJ = main.o parser.o lex.o

all: $(BIN) clean

%.c: %.l
	$(LEX) -i -o$@ $<

%.c: %.y
	$(BISON) -d --output=parser.c $<

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN): $(SRC) $(OBJ)
	$(CC) $(CFLAGS) -o $(BIN) $(OBJ)
	mv $(BIN) ../$(BIN)

clean:
	rm -rf $(OBJ) parser.h