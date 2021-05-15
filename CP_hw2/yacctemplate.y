%{
#include <stdio.h>
#include <stdlib.h>
int yylex();
extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
%}
%union { int value; double dval; char* text; }
%token SEMICOLON    /* ; */
%token ID           /* identifier */
%token INT CONST VOID READ BOOLEAN WHILE DO IF ELSE TRUE FALSE FOR PRINT BOOL FLOAT DOUBLE STRING CONTINUE BREAK RETURN
%token NUM FLOAT_NUM
%token STRING_VALUE SCIENTIFIC
$token SMALL_EQUAL BIG_EQUAL EQUAL AND OR NOT_EQUAL
%left OR
%left AND
%nonassoc '!'
%left '<' '>' SMALL_EQUAL BIG_EQUAL EQUAL NOT_EQUAL
%left '+' '-'
%left '*' '/' '%'
%nonassoc MINUS
%start program
%%


expression : elem
		   ;
elem : elem '+' elem 
	 | elem '-' elem
	 | elem '*' elem 
	 | elem '/' elem 
	 | elem '>' elem
	 | elem '<' elem
	 | elem '%' elem
	 | elem SMALL_EQUAL elem
	 | elem BIG_EQUAL elem
	 | elem EQUAL elem
	 | elem AND elem
	 | elem OR elem
	 | elem NOT_EQUAL elem
	 | '(' elem ')' 
	 | '-' elem %prec MINUS 
	 | '!' elem
	 | VALUE
	 | ID
	 | ID array
	 ;
program : declaration_list
		;

declaration_list : declaration_list declaration 
				 | declaration
				 ;

declaration : const_decl 
            | type var_decl 
            | type ID '(' par_decl_list ')' funct_defin
            | VOID ID '(' par_decl_list ')' funct_defin 
			;

const_decl : CONST type const_identifier_list SEMICOLON 
           ;

const_identifier_list : const_identifier_list ',' const_identifier_decl 
					  | const_identifier_decl 
					  ;

const_identifier_decl : ID const_literal 
					  ;        

const_literal : '=' VALUE 
		   ;

var_decl : identifier_list SEMICOLON 
         ;

identifier_list : identifier_list ',' ID identifier_decl 
   				| ID identifier_decl 
   				;

identifier_decl : '=' expression 
				| identifier_array
				| identifier_array '=' array_init
				|
				;

identifier_array : identifier_array '[' NUM ']'
		   		  | '[' NUM ']'
		          ;

array_init : '{' expression_list '}' 
		   | '{' '}' 
		   ;
expression_list : expression_list ',' expression
		   | expression
		   ;

VALUE : NUM
 	  | TRUE
 	  | FALSE
 	  | FLOAT_NUM
 	  | STRING_VALUE
 	  | SCIENTIFIC
 	  ;

funct_defin : SEMICOLON 
			| '{' statement '}'
		    ;

par_decl_list : par_decl_list ',' type ID par_decl 
			  | type ID par_decl 
			  |
			  ;

par_decl : identifier_array
		 | 
		 ;	  
	

type : INT
	 | FLOAT
	 | BOOL
	 | STRING
	 ;

statement : statement '{' statement '}'
		  | statement const_decl
		  | statement type var_decl
		  | statement simple_expression
		  | statement PRINT expression SEMICOLON 
		  | statement READ ID array SEMICOLON 
		  | statement READ ID SEMICOLON 
		  | statement func_invok
		  | statement ID '=' func_invok
		  | statement IF '(' expression ')' '{' statement '}' condition
		  | statement WHILE '(' expression ')' '{' statement '}'
		  | statement DO '{' statement '}' WHILE '(' expression ')' SEMICOLON 
		  | statement for
		  | statement RETURN expression SEMICOLON 
		  | statement BREAK SEMICOLON 
		  | statement CONTINUE SEMICOLON 
		  |
		  ;		
for : FOR '(' for_expression SEMICOLON for_expression SEMICOLON for_expression ')' '{' statement '}'
    | FOR '(' for_expression SEMICOLON SEMICOLON for_expression ')' '{' statement '}'
    | FOR '(' SEMICOLON for_expression SEMICOLON for_expression ')' '{' statement '}'
    | FOR '(' for_expression SEMICOLON for_expression SEMICOLON ')' '{' statement '}'
    | FOR '(' SEMICOLON for_expression SEMICOLON ')' '{' statement '}'
    | FOR '(' for_expression SEMICOLON SEMICOLON ')' '{' statement '}'
    | FOR '(' SEMICOLON  SEMICOLON for_expression ')' '{' statement '}'
    | FOR '(' SEMICOLON  SEMICOLON  ')' '{' statement '}'
    ;
for_expression : expression
			   | ID '=' expression
			   | ID array '=' expression
			   ; 
condition : ELSE '{' statement '}' 
		  |
	      ;
simple_expression : ID array '=' expression SEMICOLON 
                  | ID '=' expression SEMICOLON 
                  ;

array : array '[' expression ']'
	  | '[' expression ']'
      ;	
func_invok : ID '(' arg_list ')' SEMICOLON 
	       ;
arg_list : arg_list ',' expression
         | expression
         |
         ;

%%

int yyerror( char *msg )
{
  fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
  fprintf( stderr, "|--------------------------------------------------------------------------\n" );
  exit(-1);
}

int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	FILE *fp = fopen( argv[1], "r" );
	
	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	
	yyin = fp;
	yyparse();
	
	fprintf( stdout, "\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}