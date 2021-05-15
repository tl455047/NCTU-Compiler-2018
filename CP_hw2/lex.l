%{
#include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
#define MAX_STRING_LENGTH 257

#define LIST                strncat(buf, yytext, MAX_LINE_LENGTH)
#define token(t)            {LIST; if (Opt_Token) printf("<%s>\n", #t);}
#define tokenInteger(t, i)  {LIST; if (Opt_Token) printf("<%s:%d>\n", t, i);}
#define tokenString(t, s)   {LIST; if (Opt_Token) printf("<%s:%s>\n", t, s);}
int Opt_Source = 1;
int Opt_Token = 1;
int Opt_Statistic =1;
int linenum = 1;
int Last_State = 0;
char buf[MAX_LINE_LENGTH];
char strContent[MAX_STRING_LENGTH];
typedef struct ids{
	char id_name[MAX_ID_LENGTH];
	int freq;
	struct ids *next;
} id;
id *id_head;
void set(id **, char *);
id *new_id();
%}

%x PRAGMA
%x SOURCE
%x TOKEN
%x STATISTIC
%x OTHER
%x STR
%x STR_ESCAPE
%x COMMENT

%%
<INITIAL>[\t ]+	{
		LIST;
	}
^#pragma[\t ]+	{
		LIST;
		BEGIN PRAGMA;
	}
<PRAGMA>"source"[\t ]+	{
		LIST;
		BEGIN SOURCE;
	}
<PRAGMA>"token"[\t ]+	{
		LIST;
		BEGIN TOKEN;
	}
<PRAGMA>"statistic"[\t ]+	{
		LIST;
		BEGIN STATISTIC;
	}

<SOURCE>"on"[\t ]*	{
		LIST;
		Opt_Source = 1;
		BEGIN OTHER;
	}
<SOURCE>"off"[\t ]*	{
		LIST;
		Opt_Source = 0;
		BEGIN OTHER;
	}

<SOURCE>[^\t ]	{
		//printf("Error at source line %d: %s\n",linenum, yytext);
                  fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
        exit(1);
	}
<TOKEN>"on"[\t ]*	{
		LIST;
		Opt_Token = 1;
		BEGIN OTHER;
	}
<TOKEN>"off"[\t ]*	{
		LIST;
		Opt_Token = 0;
		BEGIN OTHER;
	}

<TOKEN>[^\t ]	{
                 fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
        exit(1);
	}

<STATISTIC>"on"[\t ]*	{
		LIST;
		Opt_Statistic = 1;
		BEGIN OTHER;
	}
<STATISTIC>"off"[\t ]*	{
		LIST;
		Opt_Statistic = 0;
		BEGIN OTHER;
	}

<STATISTIC>[^\t ]	{
                 fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
        exit(1);
	}
<OTHER>\/\/[^\n]*	{
		LIST;
		
	}
<OTHER>"/*"	{
		LIST;
        Last_State = OTHER;
		BEGIN COMMENT;
	}

<OTHER>\n		{
		LIST;
  	      if (Opt_Source)
  	        printf("%d:%s\n", linenum, buf);
  	      linenum++;
  	      buf[0] = '\0';
		  BEGIN INITIAL;
	}

<OTHER>[^\n]		{
                  fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
                exit(1);

	}

<PRAGMA>[^\t ]		{
                  fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
                exit(1);

	}
"("	{
		tokenString("delim", "(");
		return'(';
	}
")"	{
		tokenString("delim", ")");
		return ')';
	}
","	{
		tokenString("delim", ",");
		return ',';
	}
";"	{
		tokenString("delim", ";");
		return SEMICOLON;
	}
"["	{
		tokenString("delim", "[");
		return '[';
	}
"]"	{
		tokenString("delim", "]");
		return ']';
	}
"{"	{
		tokenString("delim", "{");
		return '{';
	}
"}"	{
		tokenString("delim", "}");
		return '}';
	}
"+"	{
		token("+");
		return '+';
	}
"-"	{
		token("-");
		return '-';
	}
"*"	{
		token("*");
		return '*';
	}
"/"	{
		token("/");
		return '/';
	}
"%"	{
		token("%");
		return '%';
	}
"="	{
		token("=");
		return '=';
	}
"<"	{
		token("<");
		return '<';
	}
"<="	{
		token("<=");
		return SMALL_EQUAL;
	}
"!="	{
		token("!=");
		return NOT_EQUAL;
	}
">="	{
		token(">=");
		return BIG_EQUAL;
	}
">"	{
		token(">");
		return '>';
	}
"=="	{
		token("==");
		return EQUAL;
	}
"&&"	{
		token("&&");
		return AND;
	}
"||"	{
		token("||");
		return OR;
	}
"!"	{
		token("!");
		return '!';
	}
read |
boolean |
while |
do |
if |
else |
true | 
false | 
for | 
const | 
int | 
print |
bool | 
void | 
float | 
double | 
string |
continue | 
break | 
return	{
		tokenString("KW", yytext);
		if(strcmp(yytext, "int") == 0)
			return INT;
		else if(strcmp(yytext, "const") == 0)
			return CONST;
		else if(strcmp(yytext, "void") == 0)
			return VOID;
		else if(strcmp(yytext, "read") == 0)
			return READ;
		else if(strcmp(yytext, "boolean") == 0)
			return BOOLEAN;
		else if(strcmp(yytext, "while") == 0)
		 	return WHILE;
		else if(strcmp(yytext, "do") == 0)
			return DO;
		else if(strcmp(yytext, "if") == 0)
			return IF;	
		else if(strcmp(yytext, "else") == 0)
			return ELSE;
		else if(strcmp(yytext, "true") == 0)
			return TRUE;
		else if(strcmp(yytext, "false") == 0)
			return FALSE;
		else if(strcmp(yytext, "for") == 0)
			return FOR;
		else if(strcmp(yytext, "print") == 0)
			return PRINT;
		else if(strcmp(yytext, "bool") == 0)
			return BOOL;
		else if(strcmp(yytext, "float") == 0)
			return FLOAT;
		else if(strcmp(yytext, "double") == 0)
			return DOUBLE;
		else if(strcmp(yytext, "string") == 0)
			return STRING;
		else if(strcmp(yytext, "continue") == 0)
			return CONTINUE;
		else if(strcmp(yytext, "break") == 0)
			return BREAK;
		else if(strcmp(yytext, "return") == 0)
			return RETURN;
	}

0 |
[1-9][0-9]* {
		tokenString("integer", yytext);
		return NUM;
	}
[0-9]+\.[0-9]+	{
		tokenString("float", yytext);
		return FLOAT_NUM;
	}

([0-9]+|([0-9]*\.[0-9]+))([eE][-+]?[0-9]+)	{
		tokenString("scientific", yytext);
		return SCIENTIFIC;
	}
"\""	{ 
		LIST;
                strContent[0] = '\0';
		BEGIN STR;
	}
<STR>"\\"	{
		LIST;
		BEGIN STR_ESCAPE;
	}
<STR_ESCAPE>\"	{
		LIST;
		strncat (strContent, "\"", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>n	{
		LIST;
		strncat( strContent, "\\n", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>t	{
		LIST;
		strncat( strContent, "\\t", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>\\	{
		LIST;
		strncat( strContent, "\\", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>\n  {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}
<STR_ESCAPE>[^\"nt\\]	{
		LIST;
		strncat( strContent, "\\", MAX_STRING_LENGTH);
		strncat( strContent, yytext, MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR>"\n"	{
                 fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);

		exit(1);
	}

<STR>\"	{
		tokenString("string", strContent);
		BEGIN INITIAL;
		return STRING_VALUE;
		
	}
<STR>[^\\\n\"]	{
		LIST;
		strncat( strContent, yytext, MAX_STRING_LENGTH);
	}

"/*"	{
		LIST;
        Last_State = INITIAL;
		BEGIN COMMENT;
	}
<COMMENT>"\n"	{
		LIST;
		if(Last_State == OTHER)Last_State = INITIAL;
		if (Opt_Source)
  	        printf("%d:%s\n", linenum, buf);
		linenum++;
                buf[0] = '\0';
	}

			
<COMMENT>.	{
		LIST;
	}

<COMMENT>"*/"	{
		LIST;
		BEGIN Last_State;
	}

\/\/.*	{
		LIST;
	}

\n	{
  	      LIST;
  	      if (Opt_Source)
  	        printf("%d:%s\n", linenum, buf);
  	      linenum++;
  	      buf[0] = '\0';
        }

[a-zA-Z_][a-zA-Z0-9_]{0,255}	{
		if(Opt_Statistic){
			set(&id_head,yytext);
		}
		tokenString("id",yytext);
		return ID;
	}

.	{
		//printf("Error at wee line %d: %s\n",linenum, yytext);
                 fprintf(stderr,"Error at line %d: %s\n",linenum, yytext);
                 printf("s\n");
		exit(1);
	}
%%
int yywrap()
{
LIST;
	if (Opt_Source)
		printf("%d:%s\n", linenum, buf);
	++linenum;
	buf[0] = '\0';
	return 1;
}
void set(id **head, char *yytext)
{
	id *offset = *head;
	id *prev = NULL;	
	if(offset == NULL){
		*head = new_id();
		strncpy((*head)->id_name, yytext,strlen(yytext));
		(*head)->freq = 1;
	}else{
		while(offset){
			if(!strncmp(offset->id_name, yytext, (strlen(yytext)>=strlen(offset->id_name)?strlen(yytext):strlen(offset->id_name)))){
				offset->freq+=1;
				break;
			}
			prev = offset;
			offset = offset -> next;
		}
		if(!offset){
			prev->next = new_id();
			strncpy(prev->next->id_name, yytext, strlen(yytext));
			prev->next->freq+=1;
		}
	}
}
id *new_id()
{
	id *temp = (id *)malloc(sizeof(id));
	temp->next = NULL;
	memset(temp->id_name, 0, 256);
	temp->freq = 0;
	return temp;
}
			
