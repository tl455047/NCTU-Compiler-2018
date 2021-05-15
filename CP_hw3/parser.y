%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int linenum;
extern FILE *yyin;
extern char *yytext;
extern char buf[256];
extern int Opt_Symbol;
int yylex();
int yyerror( char *msg );

typedef struct Symbol{
  struct Symbol *next;
  char *name;
  char *kind;
  int level;
  char *type;
  char *attribute;
} Symbol;
typedef struct Symbol_table{
  struct Symbol_table *ptr;
  struct Symbol *head;
  struct Symbol *tail;
  int level;
} Symbol_table;
typedef struct para_{
  struct para_ *next;
  char *name;
  char* type;
} para_;
para_ *para_head;
para_ *para_tail;
int level = -1;
Symbol_table *st_head;
Symbol *head;
Symbol *tail;

char* name;
char* type;
char* dim_type;
char* func_attri;
char* const_v;
char* para;
int fun_def;
void insertNodeTable();
void popTable();
void initLinkList();
void insertNode(char name[], char kind[], int level, char type[], char attribute[]);
int searchNodeFunc(char name[]);
int searchNode(char name[]);
void freeLinkList(Symbol *head);
void freeIdName(Symbol *s);
void freeKind(Symbol *s);
void freeType(Symbol *s);
void freeAttribute(Symbol *s);
void printTable();
void insertNodePara(char name[], char type[]);
void cleanPara();
void printPara();
void pushPara();
int searchPara(char name[]);
%}
%union  {
  int val;
  char* text;
}
%token  <text> ID
%token  <text> INT_CONST
%token  <text> FLOAT_CONST
%token  <text> SCIENTIFIC
%token  <text> STR_CONST

%token  LE_OP
%token  NE_OP
%token  GE_OP
%token  EQ_OP
%token  AND_OP
%token  OR_OP

%token  READ
%token  BOOLEAN
%token  WHILE
%token  DO
%token  IF
%token  ELSE
%token  <text> TRUE
%token  <text> FALSE
%token  FOR
%token  <text> INT
%token  PRINT
%token  <text> BOOL
%token  <text> VOID
%token  <text> FLOAT
%token  <text> DOUBLE
%token  <text> STRING
%token  CONTINUE
%token  BREAK
%token  RETURN
%token  CONST

%token  L_PAREN
%token  R_PAREN
%token  <text> COMMA
%token  SEMICOLON
%token  <text> ML_BRACE
%token  <text> MR_BRACE
%token  L_BRACE
%token  R_BRACE
%token  ADD_OP
%token  SUB_OP
%token  MUL_OP
%token  DIV_OP
%token  MOD_OP
%token  ASSIGN_OP
%token  LT_OP
%token  GT_OP
%token  NOT_OP

/*  Program 
    Function 
    Array 
    Const 
    IF 
    ELSE 
    RETURN 
    FOR 
    WHILE
*/
%type <text> literal_const
%type <text> scalar_type
%type <text> dim
%type <text> array_decl
%type <text> parameter_list
%start program

%%

program : PUSH_TABLE decl_list funct_def decl_and_def_list POP_TABLE 
        ;

decl_list : decl_list var_decl
          | decl_list const_decl
          | decl_list funct_decl
          |
          ;


decl_and_def_list : decl_and_def_list var_decl
                  | decl_and_def_list const_decl
                  | decl_and_def_list funct_decl
                  | decl_and_def_list funct_def
                  | 
                  ;

funct_def : scalar_type ID L_PAREN R_PAREN compound_statement {if(searchNodeFunc($2)){
                                                                  insertNode($2,"function",st_head->level,$1,"");}}
          | scalar_type ID L_PAREN parameter_list R_PAREN  compound_statement {if(searchNodeFunc($2)){
                                                                                  insertNode($2,"function",st_head->level,$1,$4);}}
          | VOID ID L_PAREN R_PAREN compound_statement {if(searchNodeFunc($2)){
                                                            insertNode($2,"function",st_head->level,$1,"");}}
          | VOID ID L_PAREN parameter_list R_PAREN compound_statement  {if(searchNodeFunc($2)){
                                                                                  insertNode($2,"function",st_head->level,$1,$4);}}
          ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON {insertNode($2,"function",st_head->level,$1,"");cleanPara();}
           | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON {insertNode($2,"function",st_head->level,$1,$4);cleanPara();}
           | VOID ID L_PAREN R_PAREN SEMICOLON {insertNode($2,"function",st_head->level,$1,"");cleanPara();}
           | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON {insertNode($2,"function",st_head->level,$1,$4);cleanPara();}
           ;

parameter_list : parameter_list COMMA scalar_type ID { if(!searchPara($4))
                                                       {
                                                          printf("##########Error at Line #%d: %S redeclared.##########\n",linenum,$4);
                                                          $$ = $1;
                                                       }
                                                       else 
                                                       {
                                                          insertNodePara($4,$3); char* name_with_extension;
                                                          name_with_extension = malloc(1+strlen($1)+strlen($3)+strlen($2));
                                                          strcpy(name_with_extension, $1); 
                                                          strcat(name_with_extension, $2);
                                                          strcat(name_with_extension, $3);
                                                          $$ = strdup(name_with_extension);
                                                          free(name_with_extension);
                                                       }
                                                       }
               | parameter_list COMMA scalar_type array_decl { if(!searchPara($4))
                                                               {
                                                                    printf("##########Error at Line #%d: %S redeclared.##########\n",linenum,$4);
                                                                    $$ = $1;
                                                               }
                                                               else 
                                                               {
                                                                  insertNodePara($4,$3); char* name_with_extension;
                                                                  name_with_extension = malloc(1+strlen($1)+strlen(dim_type)+strlen($2));
                                                                  strcpy(name_with_extension, $1); 
                                                                  strcat(name_with_extension, $2);
                                                                  strcat(name_with_extension, dim_type);
                                                                  $$ = strdup(name_with_extension);
                                                                  free(name_with_extension);
                                                                }
                                                              }
               | scalar_type array_decl { if(!searchPara($2))
                                          {
                                              printf("##########Error at Line #%d: %S redeclared.##########\n",linenum,$2);
                                          }
                                          else 
                                          {
                                              insertNodePara($2,$1); $$ = strdup(dim_type);
                                          }
                                        }
               | scalar_type ID { if(!searchPara($2))
                                  {
                                      printf("##########Error at Line #%d: %S redeclared.##########\n",linenum,$2);
                                  }
                                  else 
                                  {
                                      insertNodePara($2,$1); $$ = strdup($1);
                                  }
                                }
               ;

var_decl : scalar_type identifier_list SEMICOLON 
         ;

identifier_list : identifier_list COMMA ID {insertNode($3,"variable",st_head->level,type,""); }
                | identifier_list COMMA ID ASSIGN_OP logical_expression {insertNode($3,"variable",st_head->level,type,""); }
                | identifier_list COMMA array_decl ASSIGN_OP initial_array { insertNode($3,"variable",st_head->level,dim_type,""); 
                                                                             dim_type = strdup(type);}
                | identifier_list COMMA array_decl {insertNode($3,"variable",st_head->level,dim_type,""); dim_type = strdup(type);}
                | array_decl ASSIGN_OP initial_array {insertNode($1,"variable",st_head->level,dim_type,""); dim_type = strdup(type);}
                | array_decl {insertNode($1,"variable",st_head->level,dim_type,""); dim_type = strdup(type);}
                | ID ASSIGN_OP logical_expression {insertNode($1,"variable",st_head->level,type,""); }
                | ID {insertNode($1,"variable",st_head->level,type,""); }
                ;

initial_array : L_BRACE literal_list R_BRACE
              ;

literal_list : literal_list COMMA logical_expression
             | logical_expression
             | 
             ;

const_decl : CONST scalar_type const_list SEMICOLON;

const_list : const_list COMMA ID ASSIGN_OP literal_const {insertNode($3,"constant",st_head->level,type,$5);}
           | ID ASSIGN_OP literal_const {insertNode($1,"constant",st_head->level,type,$3);}
           ;

array_decl : ID dim { char* name_with_extension;name_with_extension = malloc(strlen(type)+strlen($2));
                      strcpy(name_with_extension, type); strcat(name_with_extension, $2);dim_type = strdup(name_with_extension);
                      $$ = strdup($1); free(name_with_extension);}
           ;

dim : dim ML_BRACE INT_CONST MR_BRACE { char* name_with_extension;name_with_extension = malloc(strlen($4)+1+strlen($1)+strlen($2)+strlen($3)); 
                                        strcpy(name_with_extension, $1); strcat(name_with_extension, $2); strcat(name_with_extension, $3);
                                        strcat(name_with_extension, $4); $$ = strdup(name_with_extension); free(name_with_extension);}
    | ML_BRACE INT_CONST MR_BRACE { char* name_with_extension;name_with_extension = malloc(strlen($1)+1+strlen($2)+strlen($3)); 
                                        strcpy(name_with_extension, $1);  strcat(name_with_extension, $2);
                                        strcat(name_with_extension, $3); $$ = strdup(name_with_extension);  free(name_with_extension);}
    ;

compound_statement : L_BRACE PUSH_TABLE var_const_stmt_list R_BRACE POP_TABLE
                   ;

PUSH_TABLE : {  insertNodeTable(); pushPara();cleanPara();}
           ;
POP_TABLE : {if(Opt_Symbol) {printTable();}popTable();}
          ;
var_const_stmt_list : var_const_stmt_list statement 
                    | var_const_stmt_list var_decl
                    | var_const_stmt_list const_decl
                    |
                    ;

statement : compound_statement
          | simple_statement
          | conditional_statement
          | while_statement
          | for_statement
          | function_invoke_statement
          | jump_statement
          ;     

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON
                 | PRINT logical_expression SEMICOLON
                 | READ variable_reference SEMICOLON
                 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN L_BRACE  PUSH_TABLE var_const_stmt_list R_BRACE POP_TABLE
                      | IF L_PAREN logical_expression R_PAREN 
                            L_BRACE PUSH_TABLE var_const_stmt_list R_BRACE POP_TABLE
                        ELSE
                            L_BRACE PUSH_TABLE var_const_stmt_list R_BRACE POP_TABLE
                      ;
while_statement : WHILE L_PAREN logical_expression R_PAREN
                    L_BRACE PUSH_TABLE var_const_stmt_list R_BRACE POP_TABLE
                | DO L_BRACE PUSH_TABLE
                    var_const_stmt_list
                  R_BRACE POP_TABLE WHILE L_PAREN logical_expression R_PAREN SEMICOLON
                ;

for_statement : FOR L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
                    L_BRACE PUSH_TABLE var_const_stmt_list R_BRACE POP_TABLE
              ;

initial_expression_list : initial_expression
                        |
                        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | initial_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression

control_expression_list : control_expression
                        |
                        ;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | control_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression
                   ;

increment_expression_list : increment_expression 
                          |
                          ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression
                     | increment_expression COMMA logical_expression
                     | logical_expression
                     | variable_reference ASSIGN_OP logical_expression
                     ;

function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
                          | ID L_PAREN R_PAREN SEMICOLON
                          ;

jump_statement : CONTINUE SEMICOLON
               | BREAK SEMICOLON
               | RETURN logical_expression SEMICOLON
               ;

variable_reference : array_list
                   | ID
                   ;


logical_expression : logical_expression OR_OP logical_term
                   | logical_term
                   ;

logical_term : logical_term AND_OP logical_factor
             | logical_factor
             ;

logical_factor : NOT_OP logical_factor
               | relation_expression
               ;

relation_expression : relation_expression relation_operator arithmetic_expression
                    | arithmetic_expression
                    ;

relation_operator : LT_OP
                  | LE_OP
                  | EQ_OP
                  | GE_OP
                  | GT_OP
                  | NE_OP
                  ;

arithmetic_expression : arithmetic_expression ADD_OP term
                      | arithmetic_expression SUB_OP term
                      | term
                      ;

term : term MUL_OP factor
     | term DIV_OP factor
     | term MOD_OP factor
     | factor
     ;

factor : SUB_OP factor
       | literal_const
       | variable_reference
       | L_PAREN logical_expression R_PAREN
       | ID L_PAREN logical_expression_list R_PAREN
       | ID L_PAREN R_PAREN
       ;

logical_expression_list : logical_expression_list COMMA logical_expression
                        | logical_expression
                        ;

array_list : ID dimension
           ;

dimension : dimension ML_BRACE logical_expression MR_BRACE         
          | ML_BRACE logical_expression MR_BRACE
          ;



scalar_type : INT { $$ = strdup($1); type = strdup($1);}
            | DOUBLE { $$ = strdup($1); type = strdup($1);}
            | STRING { $$ = strdup($1); type = strdup($1);}
            | BOOL { $$ = strdup($1); type = strdup($1);}
            | FLOAT { $$ = strdup($1); type = strdup($1);}
            ;
 
literal_const : INT_CONST { $$ = strdup($1);}
              | FLOAT_CONST { $$ = strdup($1);}
              | SCIENTIFIC { $$ = strdup($1);}
              | STR_CONST { $$ = strdup($1);}
              | TRUE { $$ = strdup($1);}
              | FALSE { $$ = strdup($1);}
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
    //  fprintf( stderr, "%s\t%d\t%s\t%s\n", "Error found in Line ", linenum, "next token: ", yytext );
}

void insertNodeTable()
{
  if(st_head != NULL)
  {
    Symbol_table *st  =  (Symbol_table *)malloc(sizeof(Symbol_table));

    st->ptr = st_head;

    st->head = NULL;

    st->tail = NULL;

    level++;

    st->level = level;

    st_head = st;
  }
  else
  {
    Symbol_table *st  =  (Symbol_table *)malloc(sizeof(Symbol_table));

    st->ptr = NULL;

    st->head = NULL;

    st->tail = NULL;

    level++;

    st->level = level;

    st_head = st;

  }
}
void popTable()
{
  if(st_head != NULL)
  {
    freeLinkList(st_head->head);
    Symbol_table * cur = st_head;
    st_head = st_head->ptr;
    free(cur);
  }
  level--;
}
void initLinkList()
{
  st_head = NULL;
}
int searchNodeFunc(char name[])
{
  Symbol* current = st_head->head;
  while(current != NULL)
  {
    if(strcmp(current->name,name) == 0 && strcmp(current->kind,"function") == 0)
    {
      return 0;
    }
    current = current->next;
  }
  return 1;
}
void insertNode(char name[], char kind[], int level, char type[], char attribute[])
{

  if(st_head->head != NULL)
  {
    if(!searchNode(name))
    {
        printf("##########Error at Line #%d: %S redeclared.##########\n",linenum,name);
        return;
    }
    st_head->tail->next = (Symbol *)malloc(sizeof(Symbol));
    st_head->tail = st_head->tail->next;

    st_head->tail->name = (char *)malloc((strlen(name)+1)*sizeof(char));
        strcpy(st_head->tail->name,name);

        st_head->tail->kind = (char *)malloc((strlen(kind)+1)*sizeof(char));
        strcpy(st_head->tail->kind,kind);

        st_head->tail->level = level;

        st_head->tail->type = (char *)malloc((strlen(type)+1)*sizeof(char));
        strcpy(st_head->tail->type,type);

        st_head-> tail->attribute = (char *)malloc((strlen(attribute)+1)*sizeof(char));
        strcpy(st_head->tail->attribute,attribute);

    st_head->tail->next = NULL;
  }
  else
  {
    st_head->tail = (Symbol *)malloc(sizeof(Symbol));

    st_head->tail->name = (char *)malloc((strlen(name)+1)*sizeof(char));
        strcpy(st_head->tail->name,name);

        st_head->tail->kind = (char *)malloc((strlen(kind)+1)*sizeof(char));
        strcpy(st_head->tail->kind,kind);

        st_head->tail->level = level;

        st_head->tail->type = (char *)malloc((strlen(type)+1)*sizeof(char));
        strcpy(st_head->tail->type,type);

        st_head->tail->attribute = (char *)malloc((strlen(attribute)+1)*sizeof(char));
        strcpy(st_head->tail->attribute,attribute);

    st_head->tail->next = NULL;
    st_head->head = st_head->tail;

  }
}
void freeLinkList(Symbol *head)
{
    Symbol *current = head;
    Symbol *temp = current;
    while(current != NULL)
  {
    temp = current;
    current = current->next;
    freeIdName(temp);
    freeKind(temp);
    freeType(temp);
    freeAttribute(temp);
    //printf("%s",current->id_name);

    free(temp);
  }

}
void freeIdName(Symbol *s)
{
    free(s->name);
}
void freeKind(Symbol *s)
{
  free(s->kind);
}
void freeType(Symbol *s)
{
  free(s->type);
}
void freeAttribute(Symbol *s)
{
  free(s->attribute);
}
void printTable()
{
  Symbol *current = st_head->head;
   printf("=======================================================================================\n"); 
       printf("Name");printf("%*c", 29, ' ');
       printf("Kind");printf("%*c", 7, ' ');       
       printf("Level");printf("%*c", 7, ' ');                                 
       printf("Type");printf("%*c", 15, ' ');  
       printf("Attribute");printf("%*c", 15, ' ');
       printf("\n");   
       printf("---------------------------------------------------------------------------------------\n");
  while(current != NULL)
  {
       printf("%-33.32s",current->name);//printf("%*c", 29, ' ');
       printf("%-11s",current->kind);//printf("%*c", 7, ' ');    
       //printf("%d",current->level);
       if(current->level == 0)
       {
          char c1[10] = {'(','g','l','o','b','a','l',')'};
          char c2[10];
          sprintf(c2,"%d",current->level); 
          char *ex = malloc(strlen(c1) + strlen(c2) + 1);
          strcpy(ex,c2);
          strcat(ex,c1);
          printf("%-12s",ex);
       }
       else
       {
          char c1[10] = {'(','l','o','c','a','l',')'};
          char c2[10];
          sprintf(c2,"%d",current->level); 
          char *ex = malloc(strlen(c1) + strlen(c2) + 1);
          strcpy(ex,c2);
          strcat(ex,c1);
          printf("%-12s",ex);
       }
       //printf("%*c", 7, ' ');  
       printf("%-19s",current->type);//printf("%*c", 15, ' '); 
       printf("%-24s",current->attribute);//printf("%*c", 15, ' '); 
       printf("\n");
    current = current->next;
  }
  printf("======================================================================================\n");
  //printf("Name                             Kind       Level       Type               Attribute               \n");
}
void insertNodePara(char name[], char type[])
{
  if(para_head != NULL)
  { 
    para_tail->next = (para_ *)malloc(sizeof(para_));
    para_tail = para_tail->next;

    para_tail->name = (char *)malloc((strlen(name)+1)*sizeof(char));
        strcpy(para_tail->name,name);

        para_tail->type = (char *)malloc((strlen(type)+1)*sizeof(char));
        strcpy(para_tail->type,type);

    para_tail->next = NULL;
  }
  else
  {
    para_tail = (para_ *)malloc(sizeof(para_));

    para_tail->name = (char *)malloc((strlen(name)+1)*sizeof(char));
        strcpy(para_tail->name,name);

        para_tail->type = (char *)malloc((strlen(type)+1)*sizeof(char));
        strcpy(para_tail->type,type);

    para_tail->next = NULL;
    para_head = para_tail;

  }
}
void cleanPara()
{
  para_ * cur = para_head;
  while(cur != NULL)
  {
    free(cur->name);
    free(cur->type);
    cur = cur->next;
  }
  para_head = NULL;
  para_tail = NULL;
}
void printPara()
{
  para_ *current = para_head;
  while(current != NULL)
  {
        printf("name:%s, type:%s\n",current->name,current->type);
    current = current->next;
  }
}
void pushPara(){
  para_ *cur = para_head;
  while(cur != NULL)
  {
    insertNode(cur->name,"parameter",st_head->level,cur->type,"");
    cur = cur->next;
  }
}
int searchPara(char name[]){
  para_ *cur = para_head;
   while(cur != NULL)
  {
    if(strcmp(cur->name,name) == 0)
      {
        return 0;
      }
    cur = cur->next;
  }
  return 1;
}
int searchNode(char name[]) {
    Symbol* current = st_head->head;
    while(current != NULL)
   {
      if(strcmp(current->name,name) == 0)
      {
        return 0;
      }
      current = current->next;
    }
  return 1;
}