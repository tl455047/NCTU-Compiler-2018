#include <stdio.h>
#include <stdlib.h>

extern int yyparse();
extern FILE* yyin;
extern int Opt_Statistic;
typedef struct ids{
	char id_name[256];
	int freq;
	struct ids *next;
} id;
extern id *id_head;
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
	yyparse();	/* primary procedure of parser */
	
 	if(Opt_Statistic){
        id *offset = id_head;
        while(offset){
            printf("%s\t%d\n",offset->id_name, offset->freq);
            offset = offset->next;
        }
    }
	fprintf( stdout, "\n|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}

