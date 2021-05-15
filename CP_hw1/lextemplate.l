%{
#define LIST { strncat(buf, yytext, sizeof(buf) - strlen(buf) - 1); }
#define token(t) { LIST; if (Opt_Token) printf("<%s>\n", #t); }
#define tokenString(t, s) { LIST; if (Opt_Token) printf("<%s:%s>\n", t, s); }
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
int Opt_Source = 1;
int Opt_Token = 1;
int Opt_Statistic = 1;
int linenum = 1;
char buf[MAX_LINE_LENGTH];
char str[MAX_LINE_LENGTH];
int j = 0;
typedef struct Id{
  char *id_name;
  int count;
  struct Id *next;
} Id;

Id *head;
Id * tail;
void searchId(char id_name[]);
%}
%x COMMENT PRAGMA

%%

"while"|"do"|"if"|"else"|"true"|"false"|"for"|"int"|"print"|"const"|"read"|"boolean"|"bool"|"void"|"ﬂoat"|"double"|"string"|"continue"|"break"|"return" {
	tokenString("KW", yytext); 
}
","|";"|"("|")"|"{"|"}"|"["|"]" {
	tokenString("delim", yytext);	
}	
[a-zA-Z\_][a-zA-Z0-9\_]* {	
	tokenString("id", yytext);
	if(Opt_Statistic)
		searchId(yytext);	
}
([1-9][0-9]*)|0 {	
	tokenString("integer", yytext);
}
([0-9]+)"."([0-9]+) {
	tokenString("float", yytext);
}
([0-9]+|[0-9]*"."[0-9]+)("E"|"e")("+"?|"-"?)([0-9]+) {
	tokenString("scientific", yytext);
}
\"(\\.|[^\\"])*\" {
	j = 0;
	for(int i = 1; i < yyleng-1; i++,j++)
	{
		if(yytext[i] == '\n')
		{
			fprintf(stderr, "Error at line %d: \n", linenum); 
			exit(1);
		}
		else if( (yytext[i] == '\\' && yytext[i+1] == '\\') || (yytext[i] == '\\' && yytext[i+1] == '\"') )
		{
			i++;
		}
		str[j] = yytext[i];
	}
	str[j]  = '\0';
	tokenString("string", str);
}
\t|" " {	LIST;	}

"//"(.)* {	LIST;	}

\n {
	LIST;
	if (Opt_Source)
		printf("%d:%s\n", linenum, buf);
	++linenum;
	buf[0] = '\0';
}




"/*" {	
	LIST;	
	BEGIN(COMMENT);
}
<COMMENT>"*/" {
	LIST;		
	BEGIN(INITIAL);	
}
<COMMENT>. {	LIST;	}
<COMMENT>\n	{	
	LIST;
	if (Opt_Source)
		printf("%d:%s\n", linenum, buf);
	++linenum;
	buf[0] = '\0';	
}

"+"		{	token("+");	}
"-"		{	token("-");	}
"*"		{	token("*");	}
"/"		{	token("/");	}
"%"		{	token("%");	}
"="		{	token("=");	}
"<"		{	token("<");	}
"<="	{	token("<=");	}
"!="	{	token("!=");	}
">="	{	token(">=");	}
">"		{	token(">");	}
"=="	{	token("==");	}
"&&"	{	token("&&");	}
"||"	{	token("||");	}
"!"		{	token("!");	}
<PRAGMA>[a-zA-Z0-9] {
	fprintf(stderr, "Error at line %d: %s\n", linenum, yytext); 
	exit(1);
}
<PRAGMA>\#|\&|\$|\'|\:|\@|\^|\`|\||\~|\\|\.|\? {
	fprintf(stderr, "Error at line %d: %s\n", linenum, yytext); 
	exit(1);
}

<PRAGMA>\+|\-|\*|\/|\%|\=|\<|\!|\>|\"|\_|\,|\;|\{|\}|\[|\]|\(|\) {
	fprintf(stderr, "Error at line %define: %s\n", linenum, yytext); 
	exit(1);
}

<PRAGMA>\t|" " {
	LIST;
}
<PRAGMA>"/*" {
	LIST;	
	BEGIN(COMMENT);
}
<PRAGMA>"//"(.)* {	LIST;	}
<PRAGMA>\n {	
	LIST;
	if (Opt_Source)
		printf("%d:%s\n", linenum, buf);
	++linenum;
	buf[0] = '\0';
	BEGIN(INITIAL);	
}


^"#pragma source on"	{	LIST;	Opt_Source = 1;	BEGIN(PRAGMA);	}
^"#pragma source off"	{	LIST;	Opt_Source = 0;	BEGIN(PRAGMA);	}
^"#pragma token on"		{	LIST;	Opt_Token = 1;	BEGIN(PRAGMA);	}
^"#pragma token off"		{	LIST;	Opt_Token = 0;	BEGIN(PRAGMA);	}
^"#pragma statistic on"		{	LIST;	Opt_Statistic = 1;	BEGIN(PRAGMA);	}
^"#pragma statistic off"	{	LIST;	Opt_Statistic = 0;	BEGIN(PRAGMA);	}

\#|\&|\$|\'|\:|\@|\^|\`|\||\~|\\|\.|\? {
	fprintf(stderr, "Error at line %d: %s\n", linenum, yytext); 
	exit(1);
}
\" {
	fprintf(stderr, "Error at line %d: \n", linenum); 
	exit(1);
}
%%
void initLinkList()
{
	head = NULL;
	tail = NULL;
}
void insertNode(char id_name[])
{
	if(head != NULL)
	{
		tail->next =  (Id *)malloc(sizeof(Id));
		tail = tail->next;

		tail->id_name = (char *)malloc((strlen(id_name)+1)*sizeof(char));
        strcpy(tail->id_name,id_name);

		tail->count = 1;
		tail->next = NULL;
	}
	else
	{
		head = (Id *)malloc(sizeof(Id));

		head->id_name = (char *)malloc((strlen(id_name)+1)*sizeof(char));
        strcpy(head->id_name,id_name);

		head->count = 1;
		head->next = NULL;
		tail = head;

	}
}
void searchId(char id_name[])
{
	Id *current = head;
	if(current == NULL)
	{
		insertNode(id_name);
		return;
	}
	else
	{
		while(current != NULL)
		{
			if(strcmp(current->id_name,id_name) == 0)
			{
				current->count++;
				return;
			}
			current = current->next;
		}
		insertNode(id_name);
	}
}

void freeIdName(Id *id)
{
    free(id->id_name);
}

void freeLinkList(Id *head)
{
    Id *current = head;
    while(current != NULL)
	{
		freeIdName(current);
		//printf("%s",current->id_name);
		Id *temp = current;
		current = current->next;
		free(temp);
	}

}

int main( int argc, char **argv )
{
	if (argc >= 2)
	{
		yyin = fopen( argv[1], "r" );
		if ( NULL == yyin ) {
			fprintf( stderr, "Cannot open: %s\n", argv[1] );
			exit(-1);
		}
	}
	else
	{
		yyin = stdin;
	}
	yylex();
	if (Opt_Statistic)
	{
		// Print frequency table
		
		if (Opt_Source)
			printf("%d:%s\n\n", linenum, buf);
			++linenum;
		buf[0] = '\0';
		printf("frequencies of identifiers:\n");
		Id * current = head;
		while(current != NULL)
		{
        	printf("%s\t%d\n",current->id_name,current->count);
			current = current->next;
		}
    	freeLinkList(head);
	}
	exit(0);
}

