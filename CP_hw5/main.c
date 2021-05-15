#include <stdio.h>
#include <stdlib.h>
#include "header.h"
#include "symtab.h"
#include <string.h>
extern int yyparse();
extern FILE* yyin;

extern struct SymTable *symbolTable;
extern struct PType *funcReturn;
extern char fileName[256];

extern __BOOLEAN semError; 
FILE *outfile;
int  main( int argc, char **argv )
{
	if( argc == 1 )
	{
		yyin = stdin;
	}
	else if( argc == 2 )
	{
		FILE *fp = fopen( argv[1], "r" );
		if( fp == NULL ) {
				fprintf( stderr, "Open file error\n" );
				exit(-1);
		}
		yyin = fp;
	}
	else
	{
	  	fprintf( stderr, "Usage: ./parser [filename]\n" );
   		exit(0);
 	} 

 	char* startpos = strrchr(argv[1], '/');
	size_t fileNamelen;
	if( startpos )
	{
		strcpy(fileName, startpos+1);
	}
	else
	{
		strcpy(fileName, argv[1]);
	}
	fileNamelen = strlen(fileName);

	fileName[fileNamelen-2] = '\0';

	char outfileName[64];
	strcpy(fileName,"output");
	snprintf(outfileName,sizeof(outfileName),"%s.j",fileName);

	outfile = fopen(outfileName,"w");

	symbolTable = (struct SymTable *)malloc(sizeof(struct SymTable));
	initSymTab( symbolTable );

	// initial function return recoder

	yyparse();	/* primary procedure of parser */

	if(semError == __TRUE){	
		fprintf( stdout, "\n|--------------------------------|\n" );
		fprintf( stdout, "|  There is no syntactic error!  |\n" );
		fprintf( stdout, "|--------------------------------|\n" );
	}
	else{
		fprintf( stdout, "\n|-------------------------------------------|\n" );
		fprintf( stdout, "| There is no syntactic and semantic error! |\n" );
		fprintf( stdout, "|-------------------------------------------|\n" );
	}
	fclose(outfile);
	exit(0);
}

