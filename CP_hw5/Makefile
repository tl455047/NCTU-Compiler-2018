TARGET = compiler
OBJECT = lex.yy.c y.tab.c y.tab.o lex.yy.o y.output parser y.tab.h main.o semcheck.o symtab.o generatecode.o
CC = gcc -g
LEX = flex
YACC = yacc -v
YACCFLAG = -d
LIBS = -lfl

all: $(TARGET)

compiler: y.tab.o lex.yy.o main.o semcheck.o symtab.o generatecode.o
	$(CC) -o $(TARGET) y.tab.o lex.yy.o main.o semcheck.o symtab.o generatecode.o  $(LIBS)

y.tab.o: y.tab.c
	$(CC) -c y.tab.c

y.tab.c: parser.y
	$(YACC) $(YACCFLAG) parser.y

lex.yy.o: lex.yy.c
	$(CC) -c lex.yy.c

lex.yy.c: lex.l
	$(LEX) lex.l

main.o: main.c
	$(CC) -c main.c

clean:
	rm -f $(TARGET) $(OBJECT)

