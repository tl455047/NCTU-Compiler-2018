all: 	
	lex lex.l
	yacc -d -v yacctemplate.y
	gcc lex.yy.c y.tab.c -ly -ll -o parser
