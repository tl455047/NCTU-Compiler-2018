%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include"datatype.h"
#include"symtable.h"
int yylex();
extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_SymTable;//declared in lex.l
int scope = 0;//default is 0(global)
struct SymTableList *symbolTableList;//create and initialize in main.c
struct ExtType *funcReturnType;
struct checkinfo{
	struct ExtType* type;
	int typevalid;
	int valuevalid;
	union{
		int	integerVal;
		float	floatVal;
		double	doubleVal;
		bool	boolVal;
		char*	stringVal;
	}value;
};
struct checkinfonode{
	struct checkinfo* info;
	struct checkinfonode* next;
};
struct checkinfolist{
	int size;
	struct checkinfonode* head;
	struct checkinfonode* tail;
};
struct declarelist{
	char 			name[33];//less than 33 character
	struct declarelist* 	next;
	int isDefined;	
	int isDeclared;
};
struct declarelist * declare_list;
int NameRedeclared(struct SymTable *table, struct SymTableNode* node);

struct checkinfo* createCheckInfoConst(struct Attribute * attribute);
struct ExtType* copyExtType(struct ExtType *e_);
int compareExtType(struct ExtType *e1, struct ExtType *e2);
struct checkinfo* createCheckInfoType(struct ExtType * e);
struct checkinfo * minusCheckInfo(struct checkinfo * info);
struct checkinfo* FuncCall(struct SymTable* table, char* name, struct checkinfo* info_);
struct checkinfo* FuncCallNoPar(struct SymTable* table, char* name);
struct checkinfo* copyCheckInfo(struct checkinfo* info_);
struct checkinfo* combineMod(struct checkinfo*info1, struct checkinfo*info2);
int ExtTypeCon(struct checkinfo *info1, struct checkinfo *info2);
struct checkinfo* combineMul(struct checkinfo*info1, struct checkinfo*info2);
struct checkinfo* combineDiv(struct checkinfo*info1, struct checkinfo*info2);
struct checkinfo* combineAdd(struct checkinfo*info1, struct checkinfo*info2);
struct checkinfo* combineSub(struct checkinfo*info1, struct checkinfo*info2);
int ReOpSelect(char* op);
struct checkinfo* combineRe(struct checkinfo*info1, int op, struct checkinfo*info2);
struct checkinfo* notBoolCheckInfo(struct checkinfo *info );
struct checkinfo* andBoolCheckInfo(struct checkinfo *info1,  struct checkinfo *info2);
struct checkinfo* orBoolCheckInfo(struct checkinfo *info1,  struct checkinfo *info2);
struct ExtType* searchIdType(struct SymTableList * tablelist, char *name);
void printCheckInfo(struct checkinfo* info);
void freeCheckInfo(struct checkinfo * info);
struct ExtType * searchArrayType(struct SymTableList * tablelist, char* name);
int checkArrayIndex(struct checkinfo* info);
int checkArrayDim(struct checkinfo* info, struct ExtType *e);
int checkVariableIsConst(struct SymTableList *tablelist, char* name);
int checkDeclArrayIndex(struct Variable	*v);
struct checkinfolist* connectCheckInfoList(struct checkinfolist* list, struct checkinfo* info);
struct checkinfolist* createCheckInfoList(struct checkinfo* info);
int checkInitialArray(struct Variable* v, struct checkinfolist* list);
int ExtTypeConE(BTYPE B,struct ExtType *e1);
void printTypeInfo(struct ExtType *e);
int ExtTypeConAs(struct checkinfo *info1, struct checkinfo* info2);
struct checkinfolist* createCheckInfoListNull();
int isDefined(struct declarelist* list, struct SymTableNode* node);
int isDeclared(struct declarelist* list, struct SymTableNode* node);
struct declarelist* connectDeclareList(struct declarelist* list, struct SymTableNode* node, int op);
void setDefined(struct declarelist* list, struct SymTableNode* node);
struct checkinfo* createCheckInfoNULL();
int searchIsArrayType(struct SymTableList * tablelist, char *name);
int in_loop = 0, in_fun = 0;
BTYPE fun_return;
int is_return = 0;
%}
%union{
	int 			intVal;
	float 			floatVal;
	double 			doubleVal;
	char			*stringVal;
	char			*idName;
	//struct ExtType 		*extType;
	struct Variable		*variable;
	struct VariableList	*variableList;
	struct ArrayDimNode	*arrayDimNode;
	//struct ConstAttr	*constAttr;
	struct FuncAttrNode	*funcAttrNode;
	//struct FuncAttr		*funcAttr;
	struct Attribute	*attribute;
	struct SymTableNode	*symTableNode;
	//struct SymTable		*symTable;
	BTYPE			bType;
	char* op;
	struct checkinfo *checkinfo;
	struct checkinfolist *checkinfolist;
};

%token <idName> ID
%token <intVal> INT_CONST
%token <floatVal> FLOAT_CONST
%token <doubleVal> SCIENTIFIC
%token <stringVal> STR_CONST



%type <variable> array_decl
%type <variableList> identifier_list
%type <arrayDimNode> dim
%type <funcAttrNode> parameter_list
%type <attribute> literal_const 
%type <symTableNode> const_list
%type <bType> scalar_type

%type <checkinfo> factor logical_expression term relation_expression arithmetic_expression logical_factor logical_term
%type <checkinfo> variable_reference  dimension array_list
%type <op> relation_operator
%type <checkinfolist> literal_list initial_array control_expression initial_expression increment_expression logical_expression_list

%token <op>	LE_OP
%token <op>	NE_OP
%token <op> GE_OP
%token <op>	EQ_OP
%token 	AND_OP
%token	OR_OP

%token	READ
%token	BOOLEAN
%token	WHILE
%token	DO
%token	IF
%token	ELSE
%token	TRUE
%token	FALSE
%token	FOR
%token	INT
%token	PRINT
%token	BOOL
%token	VOID
%token	FLOAT
%token	DOUBLE
%token	STRING
%token	CONTINUE
%token	BREAK
%token	RETURN
%token  CONST

%token	L_PAREN
%token	R_PAREN
%token	COMMA
%token	SEMICOLON
%token	ML_BRACE
%token	MR_BRACE
%token	L_BRACE
%token	R_BRACE
%token	ADD_OP
%token	SUB_OP
%token	MUL_OP
%token	DIV_OP
%token	MOD_OP
%token	ASSIGN_OP
%token	<op> LT_OP
%token	<op> GT_OP
%token	NOT_OP

/*	Program 
	Function 
	Array 
	Const 
	IF 
	ELSE 
	RETURN 
	FOR 
	WHILE
*/
%start program
%%

program :  decl_list funct_def decl_and_def_list
	{
		struct declarelist* list = declare_list;
		while(list != NULL)
		{
			if(list->isDeclared == 1 && list->isDefined == 0)
			{
				printf("##########Error at Line #%d: FUNCTION %s DECLARED BUT NO DEFINITION.##########\n",linenum,list->name);
			}
			//printf("name: %s,isDeclared: %d, isDefined: %d\n",list->name,list->isDeclared,list->isDefined);
			list = list->next;
		}
		if(Opt_SymTable == 1)
			printSymTable(symbolTableList->global);
		deleteLastSymTable(symbolTableList);
	}
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

funct_def : scalar_type ID L_PAREN R_PAREN 
			{
				funcReturnType = createExtType($1,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
					insertTableNode(symbolTableList->global,newNode);
					declare_list = connectDeclareList(declare_list,newNode,1);
				}
				else
				{
					if(isDefined(declare_list,node) == 1)
					{
						printf("##########Error at Line #%d: FUNCTION REDEFINITION.##########\n",linenum);
						if(node->attr != NULL)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);			
						}
						if($1 != node->type->baseType)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
						}
					}
					else
					{
						if(node->attr != NULL)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
							if($1 != node->type->baseType)
							{
								printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
							}
						}
						else
						{
							if($1 == node->type->baseType)
							{
								setDefined(declare_list,node);
							}
							else
							{
								printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
							}
						}
						
					}
				}
				free($2);
				in_fun = 1;
				is_return = 0;
				fun_return = $1;
			} compound_statement {in_fun = 0; 
			if(is_return == 0 && fun_return != VOID_t)
				{
					printf("##########Error at Line #%d: DO NOT HAVE ANY RETURN STATEMENT IN FUNCTION.##########\n",linenum);
				}}
		  | scalar_type ID L_PAREN parameter_list R_PAREN 
		{
				funcReturnType = createExtType($1,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct FuncAttrNode *fun = $4;
					struct FuncAttrNode *temp;
					while(fun->next != NULL)
					{
						temp = fun->next;
						while(temp != NULL)
						{
							if(strcmp(fun->name,temp->name) == 0)
							{
								printf("##########Error at Line #%d: PARAMETER REDLARED.##########\n",linenum);
							}
							temp = temp->next;
						}
						fun = fun->next;
					}
				
					struct Attribute *attr = createFunctionAttribute($4);
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
					insertTableNode(symbolTableList->global,newNode);
					declare_list = connectDeclareList(declare_list,newNode,1);
					
				}
				else
				{
					if(isDefined(declare_list,node) == 1)
					{
						printf("##########Error at Line #%d: FUNCTION REDEFINITION.##########\n",linenum);
						if(node->attr != NULL)
						{
							struct FuncAttrNode *sym = node->attr->funcParam->head;
							struct FuncAttrNode *par = $4;
							while(sym != NULL)
							{
								
								if(par == NULL)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									break;
								}
								else if(strcmp(sym->name,par->name) != 0 || compareExtType(sym->value,par->value) == 0)
								{

									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									break;
								}

								sym = sym->next;
								par = par->next;
							}
						}
						else
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
						}
						if($1 != node->type->baseType)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
						}
					}
					else
					{
						bool flag = true;
						if(node->attr != NULL)
						{
							struct FuncAttrNode *sym = node->attr->funcParam->head;
							struct FuncAttrNode *par = $4;
							while(sym != NULL)
							{
								
								if(par == NULL)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									flag = false;
									break;
								}
								else if(strcmp(sym->name,par->name) != 0 || compareExtType(sym->value,par->value) == 0)
								{

									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									flag = false;
									break;
								}

								sym = sym->next;
								par = par->next;
							}
							if(flag == true)
							{
								if($1 != node->type->baseType)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM DECLARATION.##########\n",linenum);
								}
								else 
								{
									setDefined(declare_list,node);
								}
							}
							else
							{
								if($1 != node->type->baseType)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM DECLARATION.##########\n",linenum);
								}
							}
						}
						else
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
							if($1 != node->type->baseType)
							{
								printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM DECLARATION.##########\n",linenum);
							} 
						}	
					}
					struct FuncAttrNode *fun = $4;
					struct FuncAttrNode *temp;
					while(fun->next != NULL)
					{
						temp = fun->next;
						while(temp != NULL)
						{
							if(strcmp(fun->name,temp->name) == 0)
							{
								printf("##########Error at Line #%d: PARAMETER REDLARED.##########\n",linenum);
							
							}
							temp = temp->next;
						}
						fun = fun->next;
					}
				}
				fun_return = $1;
		}
		L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
				//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL)
				{
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
				in_fun = 1;
				is_return = 0;
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
				in_fun  = 0;
				if(is_return == 0 && fun_return != VOID_t)
				{
					printf("##########Error at Line #%d: DO NOT HAVE ANY RETURN STATEMENT IN FUNCTION.##########\n",linenum);
				}
			}
		  | VOID ID L_PAREN R_PAREN
		 {
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
					insertTableNode(symbolTableList->global,newNode);
					declare_list = connectDeclareList(declare_list,newNode,1);
				}
				else
				{
					if(isDefined(declare_list,node) == 1)
					{
						printf("##########Error at Line #%d: FUNCTION REDEFINITION.##########\n",linenum);
						if(node->attr != NULL)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);			
						}
						if(node->type->baseType != VOID_t)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
						}
					}
					else
					{
						if(node->attr != NULL)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
							if(node->type->baseType != VOID_t)
							{
								printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
							}
						}
						else
						{
							if(node->type->baseType == VOID_t)
							{
								setDefined(declare_list,node);
							}
							else
							{
								printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
							}
						}
						
					}
				}		
				free($2);
				in_fun = 1;
				is_return = 0;
				fun_return = VOID_t;
		}
		  compound_statement { in_fun = 0;
		  if(is_return == 0 && fun_return != VOID_t)
				{
					printf("##########Error at Line #%d: DO NOT HAVE ANY RETURN STATEMENT IN FUNCTION.##########\n",linenum);
				}}
		  | VOID ID L_PAREN parameter_list R_PAREN
		{
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct FuncAttrNode *fun = $4;
					struct FuncAttrNode *temp;
					while(fun->next != NULL)
					{
						temp = fun->next;
						while(temp != NULL)
						{
							if(strcmp(fun->name,temp->name) == 0)
							{
								printf("##########Error at Line #%d: PARAMETER REDLARED.##########\n",linenum);
							}
							temp = temp->next;
						}
						fun = fun->next;
					}
			
					struct Attribute *attr = createFunctionAttribute($4);
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
					insertTableNode(symbolTableList->global,newNode);
					declare_list = connectDeclareList(declare_list,newNode,1);
					
				}
				else
				{
					if(isDefined(declare_list,node) == 1)
					{
						printf("##########Error at Line #%d: FUNCTION REDEFINITION.##########\n",linenum);
						if(node->attr != NULL)
						{
							struct FuncAttrNode *sym = node->attr->funcParam->head;
							struct FuncAttrNode *par = $4;
							while(sym != NULL)
							{
								
								if(par == NULL)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									break;
								}
								else if(strcmp(sym->name,par->name) != 0 || compareExtType(sym->value,par->value) == 0)
								{

									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									break;
								}

								sym = sym->next;
								par = par->next;
							}
						}
						else
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
						}
						if(node->type->baseType != VOID_t)
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM 	DECLARATION.##########\n",linenum);
						}
					}
					else
					{
						bool flag = true;
						if(node->attr != NULL)
						{
							struct FuncAttrNode *sym = node->attr->funcParam->head;
							struct FuncAttrNode *par = $4;
							while(sym != NULL)
							{
								
								if(par == NULL)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									flag = false;
									break;
								}
								else if(strcmp(sym->name,par->name) != 0 || compareExtType(sym->value,par->value) == 0)
								{

									printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
									flag = false;
									break;
								}

								sym = sym->next;
								par = par->next;
							}
							if(flag == true)
							{
								if(node->type->baseType != VOID_t)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM DECLARATION.##########\n",linenum);
								}
								else
								{
										setDefined(declare_list,node);
								}
							}
							else
							{
								if(node->type->baseType != VOID_t)
								{
									printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM DECLARATION.##########\n",linenum);
								}
							}
						}
						else
						{
							printf("##########Error at Line #%d: FUNCTION DEFINITION PARAMETER IS DIFFERENT FROM DECLARATION.##########\n",linenum);
							if(node->type->baseType != VOID_t)
							{
								printf("##########Error at Line #%d: FUNCTION DEFINITION RETURN TYPE IS DIFFERENT FROM DECLARATION.##########\n",linenum);
							} 
						}	
					}
					struct FuncAttrNode *fun = $4;
					struct FuncAttrNode *temp;
					
					while(fun->next != NULL)
					{
						temp = fun->next;
						while(temp != NULL)
						{
							if(strcmp(fun->name,temp->name) == 0)
							{
								printf("##########Error at Line #%d: PARAMETER REDLARED.##########\n",linenum);
							}
							temp = temp->next;
						}
						fun = fun->next;
					}
				}
				fun_return = VOID_t;
		}
		L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
			//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL)
				{
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
				in_fun = 1;
				is_return = 0;
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
				in_fun = 0;
				if(is_return == 0 && fun_return != VOID_t)
				{
					printf("##########Error at Line #%d: DO NOT HAVE ANY RETURN STATEMENT IN FUNCTION.##########\n",linenum);
				}
			}
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
		{
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node==NULL)//no declaration yet
			{
				funcReturnType = createExtType($1,0,NULL);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
				insertTableNode(symbolTableList->global,newNode);
				declare_list = connectDeclareList(declare_list,newNode,0);
			}
			else
			{
				if(isDeclared(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION REDLARED.##########\n",linenum);
				}
				if(isDefined(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION DECLARATION AFTER DEFINITION.##########\n",linenum);
				}
			}
			free($2);
		}
	 	   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
		{
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node==NULL)//no declaration yet
			{
				
				funcReturnType = createExtType($1,0,NULL);
				struct Attribute *attr = createFunctionAttribute($4);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
				insertTableNode(symbolTableList->global,newNode);
				declare_list = connectDeclareList(declare_list,newNode,0);	
			}
			else
			{
				if(isDeclared(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION REDLARED.##########\n",linenum);
				}
				if(isDefined(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION DECLARATION AFTER DEFINITION.##########\n",linenum);
				}
			}
			struct FuncAttrNode *fun = $4;
				struct FuncAttrNode *temp;
				while(fun->next != NULL)
				{
					temp = fun->next;
					while(temp != NULL)
					{
						if(strcmp(fun->name,temp->name) == 0)
						{
							printf("##########Error at Line #%d: PARAMETER REDLARED.##########\n",linenum);
						}
						temp = temp->next;
					}
					fun = fun->next;
				}
			free($2);
		}
		   | VOID ID L_PAREN R_PAREN SEMICOLON
		{
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node==NULL)//no declaration yet
			{
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
				insertTableNode(symbolTableList->global,newNode);
				declare_list = connectDeclareList(declare_list,newNode,0);
			}
			else
			{
				if(isDeclared(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION REDLARED.##########\n",linenum);
				}
				if(isDefined(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION DECLARATION AFTER DEFINITION.##########\n",linenum);
				}
			}
			free($2);
		}
		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
		{
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node==NULL)//no declaration yet
			{
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct Attribute *attr = createFunctionAttribute($4);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
				insertTableNode(symbolTableList->global,newNode);
				declare_list = connectDeclareList(declare_list,newNode,0);
			}
			else
			{
				if(isDeclared(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION REDLARED.##########\n",linenum);
				}
				if(isDefined(declare_list,node) == 1)
				{
					printf("##########Error at Line #%d: FUNCTION DECLARATION AFTER DEFINITION.##########\n",linenum);
				}
			}
			struct FuncAttrNode *fun = $4;
				struct FuncAttrNode *temp;
				while(fun->next != NULL)
				{
					temp = fun->next;
					while(temp != NULL)
					{
						if(strcmp(fun->name,temp->name) == 0)
						{
							printf("##########Error at Line #%d: PARAMETER REDLARED.##########\n",linenum);
						}
						temp = temp->next;
					}
					fun = fun->next;
				}
			free($2);
		}
		   ;

parameter_list : parameter_list COMMA scalar_type ID
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = createExtType($3,0,NULL);
			newNode->name = strdup($4);
			free($4);
			newNode->next = NULL;
			connectFuncAttrNode($1,newNode);
			$$ = $1;
		}
			   | parameter_list COMMA scalar_type array_decl
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = $4->type;//use pre-built ExtType(type is unknown)
			newNode->value->baseType = $3;//set correct type
			newNode->name = strdup($4->name);
			newNode->next = NULL;
			free($4->name);
			free($4);
			connectFuncAttrNode($1,newNode);
			$$ = $1;

		}
			   | scalar_type array_decl
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = $2->type;//use pre-built ExtType(type is unknown)
			newNode->value->baseType = $1;//set correct type
			newNode->name = strdup($2->name);
			newNode->next = NULL;
			free($2->name);
			free($2);
			$$ = newNode;
		}
			   | scalar_type ID
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = createExtType($1,0,NULL);
			newNode->name = strdup($2);
			free($2);
			newNode->next = NULL;
			$$ = newNode;
		}
		;

var_decl : scalar_type identifier_list SEMICOLON
		{
			struct Variable* listNode = $2->head;
			struct SymTableNode *newNode;
			while(listNode!=NULL)
			{
				if(listNode->type->baseType != VOID_t && ExtTypeConE($1,listNode->type) == 0)
				{
					printf("##########Error at Line #%d: INCONSISTENT TYPE FOR VARIABLE INITIALIZATION.##########\n",linenum);
				}
				if(listNode->type->reference != -1 && listNode->type->baseType == VOID_t || listNode->type->reference != -1 && ExtTypeConE($1,listNode->type) == 1 )
				{
					newNode = createVariableNode(listNode->name,scope,listNode->type);
					newNode->type->baseType = $1;
					if(NameRedeclared(symbolTableList->tail,newNode) == 0)
					insertTableNode(symbolTableList->tail,newNode);
					else
					printf("##########Error at Line #%d: VARIABLE NAME REDECLARED.##########\n",linenum);
				}
				listNode = listNode->next;
			}
			deleteVariableList($2);
		}
		 ;

identifier_list : identifier_list COMMA ID
		{
			struct ExtType *type = createExtType(VOID_t,false,NULL);//type unknown here
			struct Variable *newVariable = createVariable($3,type);
			free($3);
			connectVariableList($1,newVariable);
			$$ = $1;
		}
		| identifier_list COMMA ID ASSIGN_OP logical_expression
		{
			
			struct ExtType *type = createExtType(VOID,false,NULL);//type unknown here
			if($5->typevalid == 1)
			{
				type->baseType = $5->type->baseType;
			}
			else
			{
				type->baseType = INVALID_t;
			}
			struct Variable *newVariable = createVariable($3,type);
			free($3);
			connectVariableList($1,newVariable);
			$$ = $1;
			freeCheckInfo($5);
		}
		| identifier_list COMMA array_decl ASSIGN_OP initial_array
		{
			connectVariableList($1,$3);
			if(checkInitialArray($3,$5) == 0)
			{
				printf("##########Error at Line #%d: INVALID ARRAY INITIALIZER.##########\n",linenum);
				//$1->tail->type->reference = -1;
				$5->head->info->type->baseType = INVALID_t;
			}
			if(checkDeclArrayIndex($3) == 0)
			{
				printf("##########Error at Line #%d: INVALID INDEX FOR ARRAY INITIALIZATION.##########\n",linenum);
				$3->type->reference = -1;
			}	
			$$ = $1;
			if($5 != NULL)
			{
				$3->type->baseType = $5->head->info->type->baseType;	
				freeCheckInfoList($5);
			}
			else
			{
				$3->type->baseType = VOID_t;
			}	
		}
		| identifier_list COMMA array_decl
		{
			connectVariableList($1,$3);
			if(checkDeclArrayIndex($3) == 0)
			{
				printf("##########Error at Line #%d: INVALID INDEX FOR ARRAY INITIALIZATION.##########\n",linenum);
				$3->type->reference = -1;
			}
			$$ = $1;
		}
		| array_decl ASSIGN_OP initial_array
		{
			$$ = createVariableList($1);
			if(checkInitialArray($1,$3) == 0)
			{
				printf("##########Error at Line #%d: INVALID ARRAY INITIALIZER.##########\n",linenum);
				//$$->head->type->reference = -1;
				$3->head->info->type->baseType = INVALID_t;
			}
			if(checkDeclArrayIndex($1) == 0)
			{
				printf("##########Error at Line #%d: INVALID ARRAY INITIALIZER.##########\n",linenum);
				$$->head->type->reference = -1;
			}
			if($3 != NULL)
			{
				$1->type->baseType = $3->head->info->type->baseType;
				freeCheckInfoList($3);		
			}
			else
			{
				$1->type->baseType = VOID_t;
			}
		}
		| array_decl
		{
			$$ = createVariableList($1);
			if(checkDeclArrayIndex($1) == 0)
			{
				printf("##########Error at Line #%d: INVALID INDEX FOR ARRAY INITIALIZATION.##########\n",linenum);
				$$->head->type->reference = -1;
			}
		}
		| ID ASSIGN_OP logical_expression
		{	
			struct ExtType *type = createExtType(VOID,false,NULL);//type unknown here
			if($3->typevalid == 1)
			{
				type->baseType = $3->type->baseType;
			}
			else
			{
				type->baseType = INVALID_t;
			}
			struct Variable *newVariable = createVariable($1,type);
			$$ = createVariableList(newVariable);
			free($1);
			freeCheckInfo($3);
		}
		| ID
		{
			struct ExtType *type = createExtType(VOID_t,false,NULL);//type unknown here
			struct Variable *newVariable = createVariable($1,type);
			$$ = createVariableList(newVariable);
			free($1);
		}
				;

initial_array : L_BRACE literal_list R_BRACE { $$ = $2;}
			  ;

literal_list : literal_list COMMA logical_expression { $$ = connectCheckInfoList($1,$3); }
			 | logical_expression { $$ = createCheckInfoList($1); }
                         |  {$$ = NULL;}
			 ;

const_decl : CONST scalar_type const_list SEMICOLON
	{
		struct SymTableNode *list = $3;//symTableNode base on initailized data type, 
		struct SymTableNode *ptr = list,*aft = list->next,*d;
		while(aft != NULL)
		{
			if(NameRedeclared(symbolTableList->tail,ptr) == 0)
			{
		
				if($2 == aft->type->baseType || ExtTypeConE($2,aft->type) == 1)
				{
					aft = aft->next;
					ptr = ptr->next;
				}
				else
				{
					printf("##########Error at Line #%d: INCONSISTENT TYPE FOR VARIABLE INITIALIZATION.##########\n",linenum);
					if(aft->next != NULL)
					{
						ptr->next = aft->next;
					}
					else
					{
						ptr->next = NULL;
					}
					d = aft;
					aft = aft->next;
					free(d);
				}
			}
			else
			{
				printf("##########Error at Line #%d: CONST NAME REDECLARED.##########\n",linenum);
				if($2 == aft->type->baseType || ExtTypeConE($2,aft->type) == 1)
				{
				}
				else
				{
					printf("##########Error at Line #%d: INCONSISTENT TYPE FOR VARIABLE INITIALIZATION.##########\n",linenum);
				}
				if(aft->next != NULL)
				{
					ptr->next = aft->next;
				}
				else
				{
					ptr->next = NULL;
				}
				d = aft;
				aft = aft->next;
				free(d);
			}
		}
		if(NameRedeclared(symbolTableList->tail,list) == 0)
		{	
			if($2 == list->type->baseType || ExtTypeConE($2,list->type) == 1)
			{
				
			}
			else
			{
				printf("##########Error at Line #%d: INCONSISTENT TYPE FOR VARIABLE INITIALIZATION.##########\n",linenum);
				ptr = list;
				list = list->next;
				free(ptr);
			}
		}
		else
		{	
			printf("##########Error at Line #%d: CONST NAME REDECLARED.##########\n",linenum);
			if($2 == list->type->baseType || ExtTypeConE($2,list->type) == 1)
			{
				
			}
			else
			{
				printf("##########Error at Line #%d: INCONSISTENT TYPE FOR VARIABLE INITIALIZATION.##########\n",linenum);		
			}
			ptr = list;
			list = list->next;
			free(ptr);
		}
		while(list!=NULL)
		{
			insertTableNode(symbolTableList->tail,list);
			list = list->next;
		}
		//printf("local:");printSymTable(symbolTableList->tail);
	}
;

const_list : const_list COMMA ID ASSIGN_OP literal_const
		{
			struct ExtType *type = createExtType($5->constVal->type,false,NULL);
			struct SymTableNode *temp = $1;
			while(temp->next!=NULL)
			{
				temp = temp->next;
			}
			temp->next = createConstNode($3,scope,type,$5);	
			free($3);
		}
		   | ID ASSIGN_OP literal_const
                {
			struct ExtType *type = createExtType($3->constVal->type,false,NULL);
			$$ = createConstNode($1,scope,type,$3);	
			free($1);
		}    
		   ;

array_decl : ID dim
	{
		struct ExtType *type = createExtType(VOID_t,true,$2);//type unknown here
		struct Variable *newVariable = createVariable($1,type);
		free($1);
		$$ = newVariable;
	}
		   ;

dim : dim ML_BRACE INT_CONST MR_BRACE
	{
	  	connectArrayDimNode($1,createArrayDimNode($3));
		$$ = $1;
	}
	| ML_BRACE INT_CONST MR_BRACE
	{
		$$ = createArrayDimNode($2);
	}
	;

compound_statement : L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
			}
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

simple_statement :variable_reference ASSIGN_OP logical_expression SEMICOLON {	
													
													if($1->type->reference == 3)
													{
														printf("##########Error at Line #%d: CAN'T RE-ASSIGN TO CONST.##########\n",linenum);
													}
													if($1->typevalid == 1 && $3->typevalid == 1 && $3->type->isArray == false && $1->type->isArray == false)
													{
														if($1->type->baseType == $3->type->baseType || ExtTypeConAs($1,$3) == 1)
														{

														}
														else
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
														}
													}
													else
													{

														if($1->type != NULL && $1->type->isArray == true || $3->type != NULL && $3->type->isArray == true)
														{
															printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ASSIGNMENT.##########\n",linenum);
														}
														if($1->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID VARIABLE REFERENCE .##########\n",linenum);
														}
														if($3->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
														}
													}
													freeCheckInfo($1);
													freeCheckInfo($3);}
				 | PRINT logical_expression SEMICOLON { if($2->typevalid == 1 && $2->type->isArray == false)
				 										{

				 										}
				 										else
				 										{
				 											printf("##########Error at Line #%d: INVALID TYPE FOR RPINT .##########\n",linenum);
				 										}}
				 | READ variable_reference SEMICOLON { if($2->typevalid == 1 && $2->type->isArray == false)
				 										{

				 										}
				 										else
				 										{
				 											printf("##########Error at Line #%d: INVALID TYPE FOR READ .##########\n",linenum);
				 										}

				 										}
				 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN { 
			if($3->typevalid == 1)
			{
				if($3->type->baseType == BOOL_t && $3->type->isArray == false)
				{

				}
				else
				{
					printf("##########Error at Line #%d: INVALID TYPE FOR IF CONDITION.##########\n",linenum);
				}
			}
			else
			{
				printf("##########Error at Line #%d: INVALID TYPE FOR IF CONDITION.##########\n",linenum);
			}
		} compound_statement else_state
					  ;

else_state : ELSE compound_statement	
		   |
		   ;
while_statement : WHILE
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
		}
		L_PAREN logical_expression {if($4->typevalid == 1)
									{
										if($4->type->baseType == BOOL_t && $4->type->isArray == false)
										{
										}
										else
										{
											printf("##########Error at Line #%d: INVALID TYPE FOR WHILE CONDITION.##########\n",linenum);
										}
									}
									else
									{
										printf("##########Error at Line #%d: INVALID TYPE FOR WHILE CONDITION.##########\n",linenum);
									}	} R_PAREN
		L_BRACE {in_loop = 1;}var_const_stmt_list R_BRACE
		{	
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			in_loop = 0;
		}
		| DO L_BRACE
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
			in_loop = 1;
		}
		var_const_stmt_list
		 R_BRACE WHILE L_PAREN logical_expression R_PAREN SEMICOLON
		{
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			in_loop = 0;
			if($8->typevalid == 1)
			{
				if($8->type->baseType == BOOL_t && $8->type->isArray == false)
				{
				}
				else
				{
					printf("##########Error at Line #%d: INVALID TYPE FOR DO-WHILE CONDITION.##########\n",linenum);
				}
			}
			else
			{
				printf("##########Error at Line #%d: INVALID TYPE FOR DO-WHILE CONDITION.##########\n",linenum);
			}
		}
		;

for_statement : FOR
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
		}
		L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
					L_BRACE {in_loop = 1;} var_const_stmt_list R_BRACE
		{
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			in_loop = 0;
		}
		;

initial_expression_list : initial_expression {
										struct checkinfonode * node = $1->head;
										while(node != NULL)
										{
											if(node->info->typevalid == 0 || node->info->type != NULL && node->info->type->isArray == true)
											{
												printf("##########Error at Line #%d: INVALID TYPE FOR FOR_INCREMENT_EXPRESSION.##########\n",linenum);
												break;
											}
											node = node->next;
										}
										freeCheckInfoList($1);	
									}
				  	    |
				        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression {

													if($3->type != NULL && $3->type->reference == 3)
													{
														printf("##########Error at Line #%d: CAN'T RE-ASSIGN TO CONST.##########\n",linenum);
														$3->typevalid = 0;
													}
													if($3->typevalid == 1 && $5->typevalid == 1 && $3->type->isArray == false && $5->type->isArray == false)
													{

														if($3->type->baseType == $5->type->baseType || ExtTypeConAs($3,$5) == 1)
														{

														}
														else
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$3->typevalid = 0;
														}
													}
													else
													{

														if($3->type != NULL && $3->type->isArray == true || $5->type != NULL && $5->type->isArray == true)
														{
															printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ASSIGNMENT.##########\n",linenum);
															$3->typevalid = 0;
														}
														if($5->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID VARIABLE REFERENCE .##########\n",linenum);
															$3->typevalid = 0;
														}
														if($3->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
														}

													}
													$$ = connectCheckInfoList($1,$3);
												}
				   | initial_expression COMMA logical_expression {  $$ = connectCheckInfoList($1,$3); }
				   | logical_expression { $$ = createCheckInfoList($1); }
				   |variable_reference ASSIGN_OP logical_expression {

				   									if($1->type != NULL && $1->type->reference == 3)
													{
														printf("##########Error at Line #%d: CAN'T RE-ASSIGN TO CONST.##########\n",linenum);
														$1->typevalid = 0;
													}

													if($1->typevalid == 1 && $3->typevalid == 1 && $1->type->isArray == false && $3->type->isArray == false)
													{
					
														if($1->type->baseType == $3->type->baseType || ExtTypeConAs($1,$3) == 1)
														{

														}
														else
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$1->typevalid = 0;
														}
													}
													else
													{

														if($1->type != NULL && $1->type->isArray == true || $3->type != NULL && $3->type->isArray == true)
														{
															printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ASSIGNMENT.##########\n",linenum);
															$1->typevalid = 0;
														}
														if($1->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID VARIABLE REFERENCE .##########\n",linenum);
															
														}
														if($3->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$1->typevalid = 0;
														}

													}

													$$ = createCheckInfoList($1);
				   									}
				   ;
control_expression_list : control_expression { 
										struct checkinfonode * node = $1->head;
										while(node != NULL)
										{
											if(node->info->typevalid == 0 || node->info->type != NULL && node->info->type->baseType != BOOL_t || node->info->type != NULL && node->info->type->isArray == true)
											{
												printf("##########Error at Line #%d: INVALID TYPE FOR FOR_CONTROL_EXPRESSION.##########\n",linenum);
												break;
											}
											node = node->next;
										}
										freeCheckInfoList($1);
									}
										
				  		| { }
				  		;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression {
													if($3->type != NULL && $3->type->reference == 3)
													{
														printf("##########Error at Line #%d: CAN'T RE-ASSIGN TO CONST.##########\n",linenum);
														$3->typevalid = 0;
													}
													if($3->typevalid == 1 && $5->typevalid == 1 && $3->type->isArray == false && $5->type->isArray == false)
													{
														if($3->type->baseType == $5->type->baseType || ExtTypeConAs($3,$5) == 1)
														{

														}
														else
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$3->typevalid = 0;
														}
													}
													else
													{

														if($3->type != NULL && $3->type->isArray == true || $5->type != NULL && $5->type->isArray == true)
														{
															printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ASSIGNMENT.##########\n",linenum);
															$3->typevalid = 0;
														}
														if($5->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID VARIABLE REFERENCE .##########\n",linenum);
															$3->typevalid = 0;
														}
														if($3->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
														}

													}
														$$ = connectCheckInfoList($1,$3);
													}
				   | control_expression COMMA logical_expression { $$ = connectCheckInfoList($1,$3);}
				   | logical_expression { $$ = createCheckInfoList($1); }
				   |variable_reference ASSIGN_OP logical_expression {
				   									if($1->type != NULL && $1->type->reference == 3)
													{
														printf("##########Error at Line #%d: CAN'T RE-ASSIGN TO CONST.##########\n",linenum);
														$1->typevalid = 0;
													}
													if($1->typevalid == 1 && $3->typevalid == 1 && $1->type->isArray == false && $3->type->isArray == false)
													{
														if($1->type->baseType == $3->type->baseType || ExtTypeConAs($1,$3) == 1)
														{

														}
														else
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$1->typevalid = 0;
														}
													}
													else
													{

														if($1->type != NULL && $1->type->isArray == true || $3->type != NULL && $3->type->isArray == true)
														{
															printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ASSIGNMENT.##########\n",linenum);
															$1->typevalid = 0;
														}
														if($1->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID VARIABLE REFERENCE .##########\n",linenum);
															
														}
														if($3->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$1->typevalid = 0;
														}

													}
													$$ = createCheckInfoList($1);
												
												}
				   ;

increment_expression_list : increment_expression {
										struct checkinfonode * node = $1->head;
										while(node != NULL)
										{
											if(node->info->typevalid == 0 || node->info->type != NULL && node->info->type->isArray == true)
											{
												printf("##########Error at Line #%d: INVALID TYPE FOR FOR_INCREMENT_EXPRESSION.##########\n",linenum);
												break;
											}
											node = node->next;
										}
										freeCheckInfoList($1);	
									}
						  |
						  ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression {
													if($3->type != NULL && $3->type->reference == 3)
													{
														printf("##########Error at Line #%d: CAN'T RE-ASSIGN TO CONST.##########\n",linenum);
														$3->typevalid = 0;
													}
													if($3->typevalid == 1 && $5->typevalid == 1 && $3->type->isArray == false && $5->type->isArray == false)
													{
														if($3->type->baseType == $5->type->baseType || ExtTypeConAs($3,$5) == 1)
														{

														}
														else
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$3->typevalid = 0;
														}
													}
													else
													{

														if($3->type != NULL && $3->type->isArray == true || $5->type != NULL && $5->type->isArray == true)
														{
															printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ASSIGNMENT.##########\n",linenum);
															$3->typevalid = 0;
														}
														if($5->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID VARIABLE REFERENCE .##########\n",linenum);
															$3->typevalid = 0;
														}
														if($3->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
														}

													}
													$$ = connectCheckInfoList($1,$3);
												}
					 | increment_expression COMMA logical_expression { $$ = connectCheckInfoList($1,$3); }
					 | logical_expression {$$ = createCheckInfoList($1);}
					 |variable_reference ASSIGN_OP logical_expression {
					 								if($1->type != NULL && $1->type->reference == 3)
													{
														printf("##########Error at Line #%d: CAN'T RE-ASSIGN TO CONST.##########\n",linenum);
														$1->typevalid = 0;
													}
													if($1->typevalid == 1 && $3->typevalid == 1 && $1->type->isArray == false && $3->type->isArray == false)
													{
														if($1->type->baseType == $3->type->baseType || ExtTypeConAs($1,$3) == 1)
														{

														}
														else
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$1->typevalid = 0;
														}
													}
													else
													{

														if($1->type != NULL && $1->type->isArray == true || $3->type != NULL && $3->type->isArray == true)
														{
															printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ASSIGNMENT.##########\n",linenum);
															$1->typevalid = 0;
														}
														if($1->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID VARIABLE REFERENCE .##########\n",linenum);
															
														}
														if($3->typevalid == 0)
														{
															printf("##########Error at Line #%d: INVALID TYPE FOR VARIABLE ASSIGNMENT .##########\n",linenum);
															$1->typevalid = 0;
														}

													}
													$$ = createCheckInfoList($1);
											 }
					 ;

function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON{
											struct SymTableNode *node;
											node = findFuncDeclaration(symbolTableList->global,$1);
											if(node==NULL)//no declaration yet
											{
												printf("##########Error at Line #%d: UNKNOWN FUNCTION INVOKATION.##########\n",linenum);
											}
											else
											{
												if(node->attr != NULL)
												{
													if($3->size != node->attr->funcParam->paramNum)
													{
														printf("##########Error at Line #%d: FUNCTION INVOKATION HAS DIFFERENT NUMBER OF PARAMETERS WITH FUNCTION DECARATION/DEFINITION.##########\n",linenum);
													}
													else
													{
														struct FuncAttrNode *fun = node->attr->funcParam->head;
														struct checkinfonode * infonode = $3->head; 
														while(fun != NULL)
														{
															
															if(infonode == NULL)
															{
																printf("##########Error at Line #%d: FUNCTION INVOKATION HAS DIFFERENT NUMBER OF PARAMETERS WITH FUNCTION DECARATION/DEFINITION.##########\n",linenum);
																break;
															}
															else if(infonode->info->typevalid == 0)
															{
																printf("##########Error at Line #%d: INVALID PARAMETER TYPE FOR FUNCTION INVOKATION.##########\n",linenum);
															}
															else if(ExtTypeConE(infonode->info->type->baseType,fun->value) == 1 && fun->value->isArray == false && infonode->info->type->isArray == false)
															{
																
															}
															else if(fun->value->isArray == true && infonode->info->type->isArray == true && fun->value->dim == infonode->info->type->dim)
															{

															}
															else
															{
																printf("##########Error at Line #%d: INVALID PARAMETER TYPE FOR FUNCTION INVOKATION.##########\n",linenum);
															}

															fun = fun->next;
															infonode = infonode->next;
														}
													}
												}
												else
												{
													printf("##########Error at Line #%d: PARAMETER DIFFERENT FROM FUNCTION DECLARATION/DEFINITION.##########\n",linenum);
												}
											}

											free($1);}
						  | ID L_PAREN R_PAREN SEMICOLON{
						  					struct SymTableNode *node;
											node = findFuncDeclaration(symbolTableList->global,$1);
											if(node==NULL)//no declaration yet
											{
												printf("##########Error at Line #%d: UNKNOWN FUNCTION INVOKATION.##########\n",linenum);
											}
											else
											{
												if(node->attr != NULL)
												{
													printf("##########Error at Line #%d: PARAMETER DIFFERENT FROM FUNCTION DECLARATION/DEFINITION.##########\n",linenum);
												}
												else
												{

												}
											}
						  					free($1);}
						  ;

jump_statement : CONTINUE SEMICOLON { if(in_loop != 1) { printf("##########Error at Line #%d: CONTINUE STATEMENT NOT IN LOOP.##########\n",linenum);}}
			   | BREAK SEMICOLON { if(in_loop != 1) {printf("##########Error at Line #%d: BREAK STATEMENT NOT IN LOOP.##########\n",linenum);}}
			   | RETURN logical_expression SEMICOLON {	
			   								if($2->typevalid == 1)
			   								{
			   										if(ExtTypeConE(fun_return, $2->type) == 1 && $2->type->isArray == false)
			   										{

			   										}
			   										else
			   										{
			   											printf("##########Error at Line #%d: INVALID RETURN TYPE FOR RETURN STATEMENT.##########\n",linenum);
			   										}
			   								}
			   								else
			   								{
			   									printf("##########Error at Line #%d: INVALID RETURN TYPE FOR RETURN STATEMENT.##########\n",linenum);
			   								}
			   								if(in_fun == 0)
			   								{
			   									printf("##########Error at Line #%d: RETURN STATEMENT NOT IN FUNCTION.##########\n",linenum);
			   								}
			   								if(fun_return == VOID_t)
			   								{
			   									printf("##########Error at Line #%d: FUNCTION RETURN IS VOID, SHOULDN'T HAVE RETURN STATEMENT.##########\n",linenum);
			   								}
			   								is_return = 1;
			   							}
			   ;

variable_reference : array_list {	$$ = $1;}
				   | ID {	$$ = createCheckInfoType(searchIdType(symbolTableList,$1)); 
				   			if(checkVariableIsConst(symbolTableList,$1) == 1)
								$$->type->reference = 3;
							free($1);}
				   ;


logical_expression : logical_expression OR_OP logical_term { $$ = orBoolCheckInfo($1,$3);  freeCheckInfo($1);
															freeCheckInfo($3);}
				   | logical_term { $$ = $1; }
				   ;

logical_term : logical_term AND_OP logical_factor { $$ = andBoolCheckInfo($1,$3); freeCheckInfo($1); freeCheckInfo($3);}
			 | logical_factor { $$ = $1; }
			 ;

logical_factor : NOT_OP logical_factor	{ $$ = notBoolCheckInfo($2); }
			   | relation_expression { $$ = $1;}
			   ;

relation_expression : arithmetic_expression relation_operator arithmetic_expression { int op = ReOpSelect($2); 
																						$$ = combineRe($1,op,$3);freeCheckInfo($1); freeCheckInfo($3);}
					| arithmetic_expression {$$ = $1;}
					;

relation_operator : LT_OP { $$ = $1;}
				  | LE_OP { $$ = $1;}
				  | EQ_OP { $$ = $1;}
				  | GE_OP { $$ = $1;}
				  | GT_OP { $$ = $1;}
				  | NE_OP { $$ = $1;}
				  ;

arithmetic_expression : arithmetic_expression ADD_OP term { $$ = combineAdd($1,$3); freeCheckInfo($1); freeCheckInfo($3);}
		   | arithmetic_expression SUB_OP term { $$ = combineSub($1,$3); freeCheckInfo($1); freeCheckInfo($3);}
                   | relation_expression { $$ = $1;}
		   | term { $$ = $1;}
		   ;

term : term MUL_OP factor { $$ = combineMul($1,$3); freeCheckInfo($1); freeCheckInfo($3);}
     | term DIV_OP factor { $$ = combineDiv($1,$3); freeCheckInfo($1); freeCheckInfo($3);}
	 | term MOD_OP factor { $$ = combineMod($1,$3); freeCheckInfo($1); freeCheckInfo($3);}
	 | factor  { $$ = $1;}
	 ;

factor :variable_reference { $$ = $1;}
	   | SUB_OP factor {	$$ = minusCheckInfo($2);}
	   | L_PAREN logical_expression R_PAREN { 	$$ = $2;	}
	   | ID L_PAREN logical_expression_list R_PAREN{	
	   										struct SymTableNode *node;
											node = findFuncDeclaration(symbolTableList->global,$1);
											if(node==NULL)//no declaration yet
											{
												printf("##########Error at Line #%d: UNKNOWN FUNCTION INVOKATION.##########\n",linenum);
												$$ = createCheckInfoNULL();
											}
											else
											{
												if(node->attr != NULL)
												{
													if($3->size != node->attr->funcParam->paramNum)
													{
														printf("##########Error at Line #%d: FUNCTION INVOKATION HAS DIFFERENT NUMBER OF PARAMETERS WITH FUNCTION DECARATION/DEFINITION.##########\n",linenum);
														$$ = createCheckInfoNULL();
													}
													else
													{
														bool flag = true;
														struct FuncAttrNode *fun = node->attr->funcParam->head;
														struct checkinfonode * infonode = $3->head; 
														while(fun != NULL)
														{
															if(infonode == NULL)
															{
																printf("##########Error at Line #%d: FUNCTION INVOKATION HAS DIFFERENT NUMBER OF PARAMETERS WITH FUNCTION DECARATION/DEFINITION.##########\n",linenum);
																flag = false;
																printf("1\n");
																break;
															}
															else if(infonode->info->typevalid == 0)
															{
																printf("##########Error at Line #%d: INVALID PARAMETER TYPE FOR FUNCTION INVOKATION.##########\n",linenum);
																flag = false;
															}
															else if(ExtTypeConE(infonode->info->type->baseType,fun->value) == 1 && fun->value->isArray == false && infonode->info->type->isArray == false)
															{
																
															}
															else if(fun->value->isArray == true && infonode->info->type->isArray == true && fun->value->dim == infonode->info->type->dim)
															{
																
															}
															else
															{
																printf("##########Error at Line #%d: INVALID PARAMETER TYPE FOR FUNCTION INVOKATION.##########\n",linenum);
																flag = false;
															}
															if(flag == true)
																printf("true\n");
															else
																printf("false\n");
															fun = fun->next;
															infonode = infonode->next;
														}

														if(flag == true)
														{
															$$ = createCheckInfoType(node->type);
															
														}
														else
														{
															$$ = createCheckInfoNULL();	
														}
													}
												}
												else
												{
													printf("##########Error at Line #%d: PARAMETER DIFFERENT FROM FUNCTION DECLARATION/DEFINITION.##########\n",linenum);
													$$ = createCheckInfoNULL();
												}
											}
free($1);}
	   | ID L_PAREN R_PAREN{	
	   		struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$1);
			if(node==NULL)//no declaration yet
			{
				printf("##########Error at Line #%d: UNKNOWN FUNCTION INVOKATION.##########\n",linenum);
				$$ = createCheckInfoNULL();
			}
			else
			{
				if(node->attr != NULL)
				{
					printf("##########Error at Line #%d: PARAMETER DIFFERENT FROM FUNCTION DECLARATION/DEFINITION.##########\n",linenum);
					$$ = createCheckInfoNULL();
				}
				else
				{
					$$ = createCheckInfoType(node->type);
				}
			}
			free($1);}
	   | literal_const
	   {
	   	$$ = createCheckInfoConst($1);
		killAttribute($1);
	   }
	   ;

logical_expression_list : logical_expression_list COMMA logical_expression {$$ = connectCheckInfoList($1,$3); }
						| logical_expression { $$ = createCheckInfoList($1);}
						;

array_list : ID dimension{ 
						if($2->typevalid == 1)
						{
							struct ExtType *e = searchArrayType(symbolTableList,$1);
							if(e->isArray == true)
							{
								if(checkArrayDim($2,e) == 1)
								{
									$2->type->isArray = false;
									$2->type->dim = 0;
								}
								else if(checkArrayDim($2,e) == 0)
								{
									$2->type->isArray = true;
									$2->type->dim = e->dim - $2->type->dim;
								}
								else
								{
									printf("##########Error at Line #%d: INVALID DIMENSION FOR ARRAY REFERENCE.##########\n",linenum);
									$2->typevalid = 0;
								}
								$2->type->baseType = e->baseType;
							}
							else
							{	
								printf("##########Error at Line #%d: ID IS NOT ARRAY.##########\n",linenum);
								$2->typevalid = 0;
								$2->type->isArray = false;
							} 
						}
						else
						{
							struct ExtType *e = searchArrayType(symbolTableList,$1);
							if(e->isArray == true)
							{
								if(checkArrayDim($2,e) == 1)
								{
									$2->type->isArray = false;
									$2->type->dim = 0;
								}
								else if(checkArrayDim($2,e) == 0)
								{
									$2->type->isArray = true;
									$2->type->dim = e->dim - $2->type->dim;
								}
								else
								{
									printf("##########Error at Line #%d: INVALID DIMENSION FOR ARRAY REFERENCE.##########\n",linenum);
									$2->typevalid = 0;
								}
							}
							printf("##########Error at Line #%d: INVALID TYPE FOR ARRAY REFERENCE.##########\n",linenum);
						}
					
						$$ = $2;
						free($1);
					}
		   ;

dimension : dimension ML_BRACE logical_expression MR_BRACE	{
													if($1->typevalid == 1 && $3->typevalid == 1)
													{
														$1->type->dim++;
														struct ArrayDimNode* aDim = $1->type->dimArray;
		  												while(aDim != NULL)
		  												{
		  													if(aDim->next != NULL)
		  													{
		  														aDim = aDim->next;
		  													}
		  													else
		  														break;
		  												}
		  										   		aDim->next = (struct ArrayDimNode*)malloc(sizeof(struct ArrayDimNode));
		  										  		aDim = aDim->next;
		  										  		aDim->next = NULL; 
		  										    	if($3->valuevalid == 1 && $3->type->baseType == INT_t)
		  										   		{	
		  										   			if($3->value.integerVal < 0)
		  													{
		  														printf("##########Error at Line #%d: ARRAY DIMENSION LESS THAN ZERO.##########\n",linenum);
		  														$1->typevalid = 0;
		  													}
		  												}
		  												else if($3->valuevalid == 0 && $3->type->baseType == INT_t)
		  										  		{
		  										  				
		  												}
		  												else 
		  												{
		  													printf("##########Error at Line #%d: INVALID TYPE FOR ARRAY INDEX.##########\n",linenum);
		  													$1->typevalid = 0;
		  												}	
		  										  		
													}
													else
													{
														$1->type->dim++;
														printf("##########Error at Line #%d: INVALID TYPE FOR ARRAY INDEX.##########\n",linenum);
													}  	
		  											
		  											$$ = $1;
		  										}	   
		  | ML_BRACE logical_expression MR_BRACE {  
													if($2->typevalid == 1)
													{
														$2->type->isArray = true; $2->type->dim = 1;
														 $2->type->dimArray = (struct ArrayDimNode*)malloc(sizeof(struct ArrayDimNode));
		  										    	$2->type->dimArray->next = NULL;
		  										    	if($2->valuevalid == 1 && $2->type->baseType == INT_t)
		  										   		{	
		  										   			if($2->value.integerVal < 0)
		  													{
		  														printf("##########Error at Line #%d: ARRAY DIMENSION LESS THAN ZERO.##########\n",linenum);
		  														$2->typevalid = 0;
		  													}
		  												}
		  												else if($2->valuevalid == 0 && $2->type->baseType == INT_t)
		  										  		{
		  										  				
		  												}
		  												else 
		  												{
		  													printf("##########Error at Line #%d: INVALID TYPE FOR ARRAY INDEX.##########\n",linenum);
		  													$2->typevalid = 0;
		  												}	
		  										  		
													}
													else
													{
														$2->type->isArray = true; $2->type->dim = 1;
														printf("##########Error at Line #%d: INVALID TYPE FOR ARRAY INDEX.##########\n",linenum);
													}  	
		  											
		  											$$ = $2;
		  										}
		  ;



scalar_type : INT
		{
			$$ = INT_t;
		}
		| DOUBLE
		{
			$$ = DOUBLE_t;
		}
		| STRING
		{
			$$ = STRING_t;
		}
		| BOOL
		{
			$$ = BOOL_t;
		}
		| FLOAT
		{
			$$ = FLOAT_t;
		}
		;
 
literal_const : INT_CONST
		{
			int val = $1;
			$$ = createConstantAttribute(INT_t,&val);		
		}
			  | SUB_OP INT_CONST
		{
			int val = -$2;
			$$ = createConstantAttribute(INT_t,&val);
		}
			  | FLOAT_CONST
		{
			float val = $1;
			$$ = createConstantAttribute(FLOAT_t,&val);
		}
			  | SUB_OP FLOAT_CONST
		{
			float val = -$2;
			$$ = createConstantAttribute(FLOAT_t,&val);
		}
			  | SCIENTIFIC
		{
			double val = $1;
			$$ = createConstantAttribute(DOUBLE_t,&val);
		}
			  | SUB_OP SCIENTIFIC
		{
			double val = -$2;
			$$ = createConstantAttribute(DOUBLE_t,&val);
		}
			  | STR_CONST
		{
			$$ = createConstantAttribute(STRING_t,$1);
			free($1);
		}
			  | TRUE
		{
			bool val = true;
			$$ = createConstantAttribute(BOOL_t,&val);
		}
			  | FALSE
		{
			bool val = false;
			$$ = createConstantAttribute(BOOL_t,&val);
		}
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


int NameRedeclared(struct SymTable *table, struct SymTableNode* node){
	struct SymTableNode* list = table->head;
	while(list != NULL)
	{
		//printf("%s %s\n",list->name,node->name);
		if(strcmp(list->name, node->name) == 0)
		{
			return 1;
		}
		list = list -> next;
	}
	return 0;
}
struct checkinfo* createCheckInfoConst(struct Attribute * attribute)
{
	
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	info->type = (struct ExtType*)malloc(sizeof(struct ExtType));
	info->type->reference = 1;
	info->type->isArray = false;
	info->type->dim = 0;
	info->type->dimArray = NULL;	
	info->typevalid = 1;
	info->valuevalid = 1;

	info->type->baseType = attribute->constVal->type;


	switch(attribute->constVal->type)
	{
		case INT_t:
			info->value.integerVal = attribute->constVal->value.integerVal; 
			break;
		case FLOAT_t:
			info->value.floatVal = attribute->constVal->value.floatVal;
			break;
		case DOUBLE_t:
			info->value.doubleVal = attribute->constVal->value.doubleVal;
			break;
		case BOOL_t:
			info->value.boolVal = attribute->constVal->value.boolVal;
			break;
		case STRING_t:
			info->value.stringVal = strdup(attribute->constVal->value.stringVal);
			break;	
		default:
			break;
	}	
	return info;	
}
struct ExtType* copyExtType(struct ExtType *e_){
	struct ExtType *e = (struct ExtType *)malloc(sizeof(struct ExtType));
	e->reference = e_->reference;
	e->baseType = e_->baseType;
	e->isArray = e_->isArray;
	e->dim = e_->dim;
	struct ArrayDimNode* aDim_ = e_->dimArray;
	e->dimArray = (struct ArrayDimNode*)malloc(sizeof(struct ArrayDimNode));
	struct ArrayDimNode* aDim = e->dimArray;
	while(aDim_ != NULL)
	{
		aDim->reference = aDim_->reference;
		aDim->size = aDim_->size;
		if(aDim_->next != NULL)
		{
			aDim->next = (struct ArrayDimNode*)malloc(sizeof(struct ArrayDimNode));
			aDim = aDim->next;
		}
		else
		{
			aDim->next = NULL;
		}
		aDim_ = aDim_->next;
	}
	return e;
}
int compareExtType(struct ExtType *e1, struct ExtType *e2){
	if(e1->isArray == true && e2->isArray == true)
	{
		if(e1->dim == e2->dim)
		{
			if(e1->baseType == e2->baseType)
			{
				struct ArrayDimNode* aDim1 = e1->dimArray;
				struct ArrayDimNode* aDim2 = e2->dimArray;
				while(aDim1 != NULL)
				{
					if(aDim2 != NULL)
					{
						if(aDim1->size == aDim2->size)
						{
							aDim1 = aDim1->next;
							aDim2 = aDim2->next;
						}
						else
						{
							return 0;
						}
					}
					else
					{
						return 0;
					}
				}
				return 1;
			}
			else
			{
				return 0;
			}
		}
		else
		{
			return 0;
		}
	}
	else if(e1->isArray == false && e2->isArray == false)
	{
		if(e1->baseType == e2->baseType)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return 0;
	}

}
struct checkinfo* createCheckInfoType(struct ExtType * e){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
		info->typevalid = 1;
		info->valuevalid = 0;
		info->type = copyExtType(e);
	return info;	
}
struct checkinfo * minusCheckInfo(struct checkinfo * info){
	if(info->typevalid == 1 && info->valuevalid == 1 && info->type->isArray == false)
	{
		switch(info->type->baseType)
		{
			case INT_t:
				info->value.integerVal = -info->value.integerVal;
				break;
			case FLOAT_t:
				info->value.floatVal = -info->value.floatVal;
				break;
			case DOUBLE_t:
				info->value.doubleVal = -info->value.doubleVal;
				break;
			default:
				info->typevalid = 0;
				info->valuevalid = 0;
				printf("##########Error at Line #%d: INVALID TYPE FOR MINUS OPERATION.##########\n",linenum);
				break;
		}
	}
	else
	{
		if(info->type != NULL)
		{
			if(info->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info->typevalid == 0)
		{
			printf("##########Error at Line #%d: INVALID TYPE FOR MINUS OPERATION.##########\n",linenum);
		}
	}
	return info;		
}
struct checkinfo* FuncCall(struct SymTable* table, char* name, struct checkinfo* info_){
	struct SymTableNode* list = table->head;
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	info->type->reference = 1;
	info->type->isArray = false;
	info->type->dim = 0;
	info->type->dimArray = NULL;
	info->typevalid = 1;
	info->valuevalid = 1;
	while(list != NULL){
		if(strcmp(list->name, name) == 0)
		{
			if(list->kind != 0)
			{
				info->typevalid = 0;
				info->valuevalid = 0;
				printf("##########Error at Line #%d: NO SUCH FUNCTION.##########\n",linenum);
				return info;
			}
			struct FuncAttrNode * par = list->attr->funcParam->head;
			while(par != NULL){
				if(!compareExtType(par->value, info_->type))
				{
					info->typevalid = 0;
					info->valuevalid = 0;
					printf("##########Error at Line #%d: PARAMETER NO MATCH.##########\n",linenum);
					return info;
				}
				par = par->next;
			}
			info->type = copyExtType(list->type);
			return info;
		}
		list = list -> next;
	}
	info->typevalid = 0;
	info->valuevalid = 0;
	return info;	
}


struct checkinfo* FuncCallNoPar(struct SymTable* table, char* name)
{
	struct SymTableNode* list = table->head;
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	info->type->reference = 1;
	info->type->isArray = false;
	info->type->dim = 0;
	info->type->dimArray = NULL;
	info->typevalid = 1;
	info->valuevalid = 1;
	while(list != NULL){
		if(strcmp(list->name, name) == 0)
		{
			if(list->kind != 0)
			{
				info->typevalid = 0;
				info->valuevalid = 0;
				printf("##########Error at Line #%d: NO SUCH FUNCTION.##########\n",linenum);
				return info;
			}
			info->type = copyExtType(list->type);
			return info;	
		}
		list = list -> next;
	}
	info->typevalid = 0;
	info->valuevalid = 0;
	return info;	
}
struct checkinfo* copyCheckInfo(struct checkinfo* info_){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	info->type = copyExtType(info_->type);
	info->typevalid = info_->typevalid;
	info->valuevalid = info_->valuevalid;
	if(info_->valuevalid == 1)
	{
		switch(info_->type->baseType)
		{
			case INT_t:
				info->value.integerVal = info_->value.integerVal; 
				break;
			case FLOAT_t:
				info->value.floatVal = info_->value.floatVal;
				break;
			case DOUBLE_t:
				info->value.doubleVal = info_->value.doubleVal;
				break;
			case BOOL_t:
				info->value.boolVal = info_->value.boolVal;
				break;
			case STRING_t:
				info->value.stringVal = strdup(info_->value.stringVal);
				break;	
			default:
				break;
		}	
	}
	
	return info;
}
struct checkinfo* combineMod(struct checkinfo*info1, struct checkinfo*info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	info->type = copyExtType(info1->type);
	info->typevalid = 1;
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->isArray == false && info2->type->isArray == false)
	{
		if(info1->type->baseType == 0 && info2->type->baseType == 0)
		{
			if(info1->valuevalid == 1 && info2->valuevalid == 1)
			{
				info->valuevalid = 1;
				info->value.integerVal = info1->value.integerVal % info2->value.integerVal;
				return info;
			}
			else
			{
				info->valuevalid = 0;
				return info;
			}
		}
		else
		{
			info->typevalid = 0;
			info->valuevalid = 0;
			printf("##########Error at Line #%d: INVALID TYPE FOR MOD OPERATION.##########\n",linenum);
			return info;
		}
	}
	else
	{
		if(info1->type->isArray == true || info2->type->isArray == true)
		{
			printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
		}
		info->typevalid = 0;
		info->valuevalid = 0;
		printf("##########Error at Line #%d: INVALID TYPE FOR MOD OPERATION.##########\n",linenum);
		return info;
	}
}
int ExtTypeCon(struct checkinfo *info1, struct checkinfo *info2){
	if(info1->type->baseType <= 2 && info2->type->baseType <= 2)
	{
		if(info1->type->baseType == info2->type->baseType)
			return 1;
		else if(info1->type->baseType > info2->type->baseType)
		{
			int i;
			switch(info2->type->baseType)
			{
				case INT_t:	
					i = 0;
					break;
				case FLOAT_t:	
					i = 1;
					break;
				default:
					break;
			}
			switch(info1->type->baseType)
			{
				case FLOAT_t:	
					info2->value.floatVal = (float)info2->value.integerVal;
					break;
				case DOUBLE_t:
					if(i == 0)	
						info2->value.doubleVal = (double)info2->value.integerVal;
					else
						info2->value.doubleVal = (double)info2->value.floatVal;
					break;
				default:
					break;
			}
			info2->type->baseType = info1->type->baseType; 
			return 1;
		}
		else if(info1->type->baseType < info2->type->baseType)
		{
			int i;
			switch(info1->type->baseType)
			{
				case INT_t:	
					i = 0;
					break;
				case FLOAT_t:	
					i = 1;
					break;
				default:
					break;
			}
			switch(info2->type->baseType)
			{
				case FLOAT_t:	
					info1->value.floatVal = (float)info1->value.integerVal;
					break;
				case DOUBLE_t:
					if(i == 0)	
						info1->value.doubleVal = (double)info1->value.integerVal;
					else
						info1->value.doubleVal = (double)info1->value.floatVal;
					break;
				default:
					break;
			}
			info1->type->baseType = info2->type->baseType; 
			return 1;
		}
	}
	else
	{
		return 0;
	}
}
struct checkinfo* combineMul(struct checkinfo*info1, struct checkinfo*info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->isArray == false && info2->type->isArray == false)
	{
		info->typevalid = 1;
		if(info1->type->baseType <= 2 && info2->type->baseType <= 2)
		{
			int i = ExtTypeCon(info1,info2);
			info->type = copyExtType(info1->type);
			if(info1->valuevalid == 1 && info2->valuevalid == 1)
			{
				info->valuevalid = 1;
				switch(info->type->baseType)
				{
					case INT_t:	
						info->value.integerVal = info1->value.integerVal * info2->value.integerVal;
						break;
					case FLOAT_t:	
						info->value.floatVal = info1->value.floatVal * info2->value.floatVal;
						break;
					case DOUBLE_t:	
						info->value.doubleVal = info1->value.doubleVal * info2->value.doubleVal;
						break;
					default:
						break;
				}
				return info;
			}
			else
			{
				info->valuevalid = 0;
				return info;
			}
		}
		else
		{
			info->typevalid = 0;
			info->valuevalid = 0;
			info->type = NULL;
			printf("##########Error at Line #%d: INVALID TYPE FOR MUL OPERATION.##########\n",linenum);
			return info;
		}
	}
	else
	{
		if(info1->type != NULL)
		{
			if(info1->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info2->type != NULL)
		{
			if(info2->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}	
		}
		info->typevalid = 0;
		info->valuevalid = 0;
			info->type = NULL;
		printf("##########Error at Line #%d: INVALID TYPE FOR MUL OPERATION.##########\n",linenum);
		return info;
	}
}
struct checkinfo* combineDiv(struct checkinfo*info1, struct checkinfo*info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->isArray == false && info2->type->isArray == false)
	{
		info->typevalid = 1;
		if(info1->type->baseType <= 2 && info2->type->baseType <= 2)
		{
			int i = ExtTypeCon(info1,info2);
			info->type = copyExtType(info1->type);
			if(info1->valuevalid == 1 && info2->valuevalid == 1)
			{
				info->valuevalid = 1;
				switch(info->type->baseType)
				{
					case INT_t:	
						info->value.integerVal = info1->value.integerVal / info2->value.integerVal;
						break;
					case FLOAT_t:	
						info->value.floatVal = info1->value.floatVal / info2->value.floatVal;
						break;
					case DOUBLE_t:	
						info->value.doubleVal = info1->value.doubleVal / info2->value.doubleVal;
						break;
					default:
						break;
				}
				return info;
			}
			else
			{
				info->valuevalid = 0;
				return info;
			}
		}
		else
		{
			info->typevalid = 0;
			info->valuevalid = 0;
			info->type = NULL;
			printf("##########Error at Line #%d: INVALID TYPE FOR DIV OPERATION.##########\n",linenum);
			return info;
		}
	}
	else
	{
		if(info1->type != NULL)
		{
			if(info1->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info2->type != NULL)
		{
			if(info2->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}	
		}
		info->typevalid = 0;
		info->valuevalid = 0;
		info->type = NULL;
		printf("##########Error at Line #%d: INVALID TYPE FOR DIV OPERATION.##########\n",linenum);
		return info;
	}
}
struct checkinfo* combineAdd(struct checkinfo*info1, struct checkinfo*info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->isArray == false && info2->type->isArray == false)
	{
		info->typevalid = 1;
		if(info1->type->baseType <= 2 && info2->type->baseType <= 2)
		{
			int i = ExtTypeCon(info1,info2);
			info->type = copyExtType(info1->type);
			if(info1->valuevalid == 1 && info2->valuevalid == 1)
			{
				info->valuevalid = 1;
				switch(info->type->baseType)
				{
					case INT_t:	
						info->value.integerVal = info1->value.integerVal + info2->value.integerVal;
						break;
					case FLOAT_t:	
						info->value.floatVal = info1->value.floatVal + info2->value.floatVal;
						break;
					case DOUBLE_t:	
						info->value.doubleVal = info1->value.doubleVal + info2->value.doubleVal;
						break;
					default:
						break;
				}
				return info;
			}
			else
			{
				info->valuevalid = 0;
				return info;
			}
		}
		else
		{
			info->typevalid = 0;
			info->valuevalid = 0;
			info->type = NULL;
			printf("##########Error at Line #%d: INVALID TYPE FOR ADD OPERATION.##########\n",linenum);
			return info;
		}
	}
	else
	{
		if(info1->type != NULL)
		{
			if(info1->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info2->type != NULL)
		{
			if(info2->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}	
		}
		info->typevalid = 0;
		info->valuevalid = 0;
		info->type = NULL;
		printf("##########Error at Line #%d: INVALID TYPE FOR ADD OPERATION.##########\n",linenum);
		return info;
	}
}
struct checkinfo* combineSub(struct checkinfo*info1, struct checkinfo*info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->isArray == false && info2->type->isArray == false)
	{
		info->typevalid = 1;
		if(info1->type->baseType <= 2 && info2->type->baseType <= 2)
		{
			int i = ExtTypeCon(info1,info2);
			info->type = copyExtType(info1->type);
			if(info1->valuevalid == 1 && info2->valuevalid == 1)
			{
				info->valuevalid = 1;
				switch(info->type->baseType)
				{
					case INT_t:	
						info->value.integerVal = info1->value.integerVal - info2->value.integerVal;
						break;
					case FLOAT_t:	
						info->value.floatVal = info1->value.floatVal - info2->value.floatVal;
						break;
					case DOUBLE_t:	
						info->value.doubleVal = info1->value.doubleVal - info2->value.doubleVal;
						break;
					default:
						break;
				}
				return info;
			}
			else
			{
				info->valuevalid = 0;
				return info;
			}
		}
		else
		{
			info->typevalid = 0;
			info->valuevalid = 0;
			info->type = NULL;
			printf("##########Error at Line #%d: INVALID TYPE FOR SUB OPERATION.##########\n",linenum);
			return info;
		}
	}
	else
	{
		if(info1->type != NULL)
		{
			if(info1->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info2->type != NULL)
		{
			if(info2->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}	
		}
		info->typevalid = 0;
		info->valuevalid = 0;
		info->type = NULL;
		printf("##########Error at Line #%d: INVALID TYPE FOR SUB OPERATION.##########\n",linenum);
		return info;
	}
}
int ReOpSelect(char* op){
	if(strcmp(op,"<") == 0)
	{
		return 0;
	}
	else if(strcmp(op,"<=") == 0)
	{
		return 1;
	}
	else if(strcmp(op,"!=") == 0)
	{
		return 2;
	}
	else if(strcmp(op,">") == 0)
	{
		return 3;
	}
	else if(strcmp(op,">=") == 0)
	{
		return 4;
	}
	else if(strcmp(op,"==") == 0)
	{
		return 5;
	}		
}
struct checkinfo* combineRe(struct checkinfo*info1, int op, struct checkinfo*info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->isArray == false && info2->type->isArray == false)
	{
		info->typevalid = 1;
		if(info1->type->baseType <= 2 && info2->type->baseType <= 2)
		{
			int i = ExtTypeCon(info1,info2);
			info->type = copyExtType(info1->type);
			if(info1->valuevalid == 1 && info2->valuevalid == 1)
			{
				info->valuevalid = 1;
				if(op == 0)
				{
					switch(info->type->baseType)
					{
						case INT_t:
							if(info1->value.integerVal < info2->value.integerVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case FLOAT_t:
							if(info1->value.floatVal < info2->value.floatVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case DOUBLE_t:
							if(info1->value.doubleVal < info2->value.doubleVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						default:
							break;
					}
				}
				else if(op == 1)
				{
					switch(info->type->baseType)
					{
						case INT_t:
							if(info1->value.integerVal <= info2->value.integerVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case FLOAT_t:
							if(info1->value.floatVal <= info2->value.floatVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case DOUBLE_t:
							if(info1->value.doubleVal <= info2->value.doubleVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						default:
							break;
					}
				}
				else if(op == 2)
				{
					switch(info->type->baseType)
					{
						case INT_t:
							if(info1->value.integerVal != info2->value.integerVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case FLOAT_t:
							if(info1->value.floatVal != info2->value.floatVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case DOUBLE_t:
							if(info1->value.doubleVal != info2->value.doubleVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case BOOL_t:
							break;
						default:
							break;
					}
				}
				else if(op == 3)
				{
					switch(info->type->baseType)
					{
						case INT_t:
							if(info1->value.integerVal > info2->value.integerVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case FLOAT_t:
							if(info1->value.floatVal > info2->value.floatVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case DOUBLE_t:
							if(info1->value.doubleVal > info2->value.doubleVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						default:
							break;
					}
				}
				else if(op == 4)
				{
					switch(info->type->baseType)
					{
						case INT_t:
							if(info1->value.integerVal >= info2->value.integerVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case FLOAT_t:
							if(info1->value.floatVal >= info2->value.floatVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case DOUBLE_t:
							if(info1->value.doubleVal >= info2->value.doubleVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						default:
							break;
					}
				}
				else if(op == 5)
				{
					switch(info->type->baseType)
					{
						case INT_t:
							if(info1->value.integerVal == info2->value.integerVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case FLOAT_t:
							if(info1->value.floatVal == info2->value.floatVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						case DOUBLE_t:
							if(info1->value.doubleVal == info2->value.doubleVal)
								info->value.boolVal = true;
							else
								info->value.boolVal = false;
							break;
						default:
							break;
					}
				}
				info->type->baseType = BOOL_t;
				return info;
			}
			else
			{	
				info->type->baseType = BOOL_t;
				info->valuevalid = 0;
				return info;
			}
		}
		else
		{
			info->type = copyExtType(info1->type);
			if(op == 2 && info1->type->baseType == BOOL_t && info2->type->baseType == BOOL_t)
			{
				if(info1->valuevalid == 1 && info2->valuevalid == 1)
				{
					info->valuevalid = 1;
					if(info1->value.boolVal != info2->value.boolVal)
						info->value.boolVal = true;
					else
						info->value.boolVal = false;
				}
				else
				{
					info->valuevalid = 0;
				}
			}
			else if(op == 5 && info1->type->baseType == BOOL_t && info2->type->baseType == BOOL_t)
			{
				if(info1->valuevalid == 1 && info2->valuevalid == 1)
				{
					info->valuevalid = 1;
					if(info1->value.boolVal == info2->value.boolVal)
						info->value.boolVal = true;
					else
						info->value.boolVal = false;
				}
				else
				{
					info->valuevalid = 0;
				}
			}
			else
			{
				info->typevalid = 0;
				info->valuevalid = 0;
				printf("##########Error at Line #%d: INVALID TYPE FOR RE OPERATION.##########\n",linenum);
			}
			return info;
		}
	}
	else
	{
		if(info1->type != NULL)
		{
			if(info1->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info2->type != NULL)
		{
			if(info2->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}	
		}
		info->typevalid = 0;
		info->valuevalid = 0;
		info->type = NULL;
		printf("##########Error at Line #%d: INVALID TYPE FOR RE OPERATION.##########\n",linenum);
		return info;
	}
}
struct checkinfo* notBoolCheckInfo(struct checkinfo *info ){

	if(info->typevalid == 1 && info->type->baseType == BOOL_t && info->type->isArray == false)
	{
		if(info->valuevalid == 1)
		{
			if(info->value.boolVal == true)
				info->value.boolVal = false;
			else
				info->value.boolVal = true;
		}
		return info;
	}
	else
	{	
		if(info->type != NULL)
		{
			if(info->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		info->typevalid = 0;
		printf("##########Error at Line #%d: INVALID TYPE FOR NOT OPERATION.##########\n",linenum);
		return info;
	}
}
struct checkinfo* andBoolCheckInfo(struct checkinfo *info1,  struct checkinfo *info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->baseType == 3 && info2->type->baseType == 3 && info1->type->isArray == false && info2->type->isArray == false)
	{
		info->typevalid = 1;
		info->type = copyExtType(info1->type);
		if(info1->valuevalid == 1 && info2->valuevalid == 1)
		{
			info->valuevalid = 1;
			info->value.boolVal = (info1->value.boolVal && info2->value.boolVal);	
			return info;
		}
		else
		{
			info->valuevalid = 0;
			return info;
		}
	}
	else
	{	
		if(info1->type != NULL)
		{
			if(info1->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info2->type != NULL)
		{
			if(info2->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}	
		}
		info->typevalid = 0;
		info->valuevalid = 0;
		info->type = NULL;
		printf("##########Error at Line #%d: INVALID TYPE FOR AND OPERATION.##########\n",linenum);
		return info;
	}
}
struct checkinfo* orBoolCheckInfo(struct checkinfo *info1,  struct checkinfo *info2){
	struct checkinfo *info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
	if(info1->typevalid == 1 && info2->typevalid == 1 && info1->type->baseType == 3 && info2->type->baseType == 3 && info1->type->isArray == false && info2->type->isArray == false)
	{
		info->typevalid = 1;
		info->type = copyExtType(info1->type);
		if(info1->valuevalid == 1 && info2->valuevalid == 1)
		{
			info->valuevalid = 1;
			info->value.boolVal = (info1->value.boolVal || info2->value.boolVal);
			return info;
		}
		else
		{
			info->valuevalid = 0;
			printf("##########Error at Line #%d: INVALID TYPE FOR OR OPERATION.##########\n",linenum);

			return info;
		}
	}
	else
	{	
		if(info1->type != NULL)
		{
			if(info1->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}
		}
		if(info2->type != NULL)
		{
			if(info2->type->isArray == true)
			{
				printf("##########Error at Line #%d: ARRAY CAN'T BE USED IN ARITHMETIC.##########\n",linenum);
			}	
		}
		info->typevalid = 0;
		info->valuevalid = 0;
		info->type = NULL;
		printf("##########Error at Line #%d: INVALID TYPE FOR OR OPERATION.##########\n",linenum);
		return info;
	}
}

struct ExtType* searchIdType(struct SymTableList * tablelist, char *name)
{
  	struct SymTable * nowtable = tablelist->tail; 
	while(nowtable != tablelist->head)
	{
		struct SymTableNode* list = nowtable->head;
		while(list != NULL)
		{
			if(strcmp(list->name,name) == 0)
			{
				return list->type;
			}
			list = list->next;
		}
		nowtable = nowtable->prev;
	}
	struct SymTableNode* list = nowtable->head;
	while(list != NULL)
	{
		if(strcmp(list->name,name) == 0)
		{
			return list->type;
		}
		list = list->next;
	}
	printf("##########Error at Line #%d: UNKNOWN ID.##########\n",linenum);
	struct ExtType *e = (struct ExtType*)malloc(sizeof(struct ExtType));
	e->reference = -1;
	e->baseType = VOID_t;
	e->dim = 0;
	e->isArray = false;
	e->dimArray = NULL;
	return e;
}
void printCheckInfo(struct checkinfo* info)
{
	if(info->typevalid == 1)
	{
		if(info->type->isArray == 0)
		{
			switch(info->type->baseType)
			{
				case INT_t:
					printf("Type: int\n");
					break;
				case FLOAT_t:
					printf("Type: float\n");
					break;
				case DOUBLE_t:
					printf("Type: double\n");
					break;
				case BOOL_t:
					printf("Type: bool\n");
					break;
				case STRING_t:
					printf("Type: string\n");
					break;
				case VOID_t:
					printf("Type: void\n");
					break;
			}
			if(info->valuevalid == 1)
			{
				switch(info->type->baseType)
				{
					case INT_t:
						printf("value: %d\n",info->value.integerVal);
						break;
					case FLOAT_t:
						printf("value: %f\n",info->value.floatVal);
						break;
					case DOUBLE_t:
						printf("value: %lf\n",info->value.doubleVal);
						break;
					case BOOL_t:
						if(info->value.boolVal == true)
							printf("value: true\n");
						else
							printf("value: false\n");
						break;
					case STRING_t:
						printf("value: %s\n",info->value.stringVal);
						break;
					case VOID_t:
						printf("value: void\n");
						break;
				}
			}
		}
		else
		{
			printf("Type: array ");
			switch(info->type->baseType)
			{
				case INT_t:
					printf("baseType: int ");
					break;
				case FLOAT_t:
					printf("baseType: float ");
					break;
				case DOUBLE_t:
					printf("baseType: double ");
					break;
				case BOOL_t:
					printf("baseType: bool ");
					break;
				case STRING_t:
					printf("baseType: string ");
					break;
				case VOID_t:
					printf("baseType: void ");
					break;
			}
			printf("dim: %d ",info->type->dim);

			struct ArrayDimNode* aDim = info->type->dimArray;
			while( aDim != NULL)
			{
				printf("reference: %d size: %d\n",aDim->reference,aDim->size);
				aDim = aDim->next;
			}
			if(info->valuevalid == 1)
			{
				switch(info->type->baseType)
				{
					case INT_t:
						printf("value: %d\n",info->value.integerVal);
						break;
					case FLOAT_t:
						printf("value: %f\n",info->value.floatVal);
						break;
					case DOUBLE_t:
						printf("value: %lf\n",info->value.doubleVal);
						break;
					case BOOL_t:
						if(info->value.boolVal == true)
							printf("value: true\n");
						else
							printf("value: false\n");
						break;
					case STRING_t:
						printf("value: %s\n",info->value.stringVal);
						break;
					case VOID_t:
						printf("value: void\n");
						break;
				}
			}

		}
	}
	else
	{
		printf("##########Error at Line #%d: INVALID TYPE.##########\n",linenum);
	}
}
void freeCheckInfo(struct checkinfo * info)
{
	if(info->type == NULL)
	{
		free(info);
		return ;
	}
	struct ArrayDimNode* aDim1 = info->type->dimArray;
	struct ArrayDimNode* aDim2;
	while(aDim1 != NULL)
	{
		aDim2 = aDim1;
		aDim1 = aDim1->next;
		free(aDim2);
	}
	free(info->type);
	free(info);

}
struct ExtType * searchArrayType(struct SymTableList * tablelist, char* name)
{
	struct SymTable * nowtable = tablelist->tail; 
	while(nowtable !=  tablelist->head)
	{
		struct SymTableNode* list = nowtable->head;
		while(list != NULL)
		{
			if(strcmp(list->name,name) == 0)
			{
				return list->type;
			}
			list = list->next;
		}
		nowtable = nowtable->prev;
	}
	struct SymTableNode* list = nowtable->head;
	while(list != NULL)
	{
		if(strcmp(list->name,name) == 0)
		{
			return list->type;
		}
		list = list->next;
	}
	printf("##########Error at Line #%d: UNKNOWN ARRAY ID.##########\n",linenum);
	struct ExtType *e = (struct ExtType*)malloc(sizeof(struct ExtType));
	e->reference = -1;
	e->baseType = VOID_t;
	e->dim = 0;
	e->isArray = false;
	e->dimArray = NULL;
	return e;
}
int checkArrayDim(struct checkinfo* info, struct ExtType *e)
{
	if(info->type->dim == e->dim)
	{
		return 1;
	}
	else if(info->type->dim < e->dim)
	{
		return 0;
	}
	else
	{
		return -1;
	}
	
}
int checkArrayIndex(struct checkinfo* info)
{
	struct ArrayDimNode* aDim = info->type->dimArray;
	while(aDim != NULL)
	{
	  	if(aDim->reference == 1 && aDim->size < 0)
	  		return 0;
	  	else if(aDim->reference == -1)
	  		return 0;
	  	aDim = aDim->next;
	}
	return 1;
}
int checkVariableIsConst(struct SymTableList *tablelist, char* name)
{
	struct SymTable * nowtable = tablelist->tail; 
	while(nowtable != tablelist->head)
	{
		struct SymTableNode* list = nowtable->head;
		while(list != NULL)
		{
			if(strcmp(list->name,name) == 0 && list->kind == 3)
			{
				return 1;
			}
			list = list->next;
		}
		nowtable = nowtable->prev;
	}
	struct SymTableNode* list = nowtable->head;
	while(list != NULL)
	{
		if(strcmp(list->name,name) == 0)
		{
			return 1;
		}
		list = list->next;
	}
	return 0;
}
int checkDeclArrayIndex(struct Variable	*v)
{
	struct ArrayDimNode *aDim = v->type->dimArray;
	while(aDim != NULL)
	{
		if(aDim->size <= 0)
			return 0;
		aDim = aDim->next;
	}
	return 1;
}
struct checkinfolist* createCheckInfoList(struct checkinfo* info){
	struct checkinfolist* list = (struct checkinfolist*)malloc(sizeof(struct checkinfolist));
	struct checkinfonode* node = (struct checkinfonode*)malloc(sizeof(struct checkinfonode));
	node->info = info;
	node->next = NULL;
	list->head = node;
	list->tail = node;
	list->size = 1;
	return list;
}
struct checkinfolist* createCheckInfoListNull(){
	struct checkinfolist* list = (struct checkinfolist*)malloc(sizeof(struct checkinfolist));
	list->head = NULL;
	list->tail = NULL;
	list->size = 0;
	return list;
}
struct checkinfolist* connectCheckInfoList(struct checkinfolist* list, struct checkinfo* info){
	struct checkinfonode* node = (struct checkinfonode*)malloc(sizeof(struct checkinfonode));
	node->info = info;
	if(list->tail != NULL)
	{
		node->next = NULL;
		list->tail->next = node;
		list->tail = node;
		list->size++;
	}
	else
	{
		node->next = NULL;
		list->tail = node;
		list->size++;
	}
	return list;
}
int checkInitialArray(struct Variable* v, struct checkinfolist* list){
	if(list == NULL)
	{
		return 1;
	}
	struct ArrayDimNode* aDim = v->type->dimArray;
	int size = 1;
	while(aDim != NULL)
	{
		size = size * aDim->size;
		aDim = aDim->next;
	}
	if(size < list->size)
	{
		printf("##########Error at Line #%d: ARRAY INITIALIZER LARGER THAN ARRAY SIZE.##########\n",linenum);
		return 0;
	}
	struct checkinfonode* node = list->head;
	struct checkinfo* info_ = node->info;
	while(node != NULL)
	{
		if(ExtTypeCon(info_,node->info) == 1 || info_->type->baseType == node->info->type->baseType)
		{
			info_ = node->info;
		}
		else
		{
			
			return 0;	
		}
		node = node->next;
	}
	list->head->info->type->baseType = info_->type->baseType;

	/**/
	return 1;
}
int ExtTypeConE(BTYPE B,struct ExtType *e1)
{
	if(B == e1->baseType)
	{
		return 1;
	}
	else if(B > e1->baseType)
	{
		if(e1->baseType <= 2 && B <= 2)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return 0;
	}
}
void printTypeInfo(struct ExtType *e)
{
	switch(e->baseType)
	{
		case INT_t:
			printf("baseType: int \n");
			break;
		case FLOAT_t:
			printf("baseType: float \n");
			break;
		case DOUBLE_t:
			printf("baseType: double \n");
			break;
		case BOOL_t:
			printf("baseType: bool \n");
			break;
		case STRING_t:
			printf("baseType: string \n");
			break;
		case VOID_t:
			printf("baseType: void \n");
			break;
		case INVALID_t:
			printf("baseType: invalid \n");
			break;
	}
}
void freeCheckInfoList(struct checkinfolist * list)
{
	if(list != NULL)
	{
		struct checkinfonode* node_;
		struct checkinfonode* node = list->head;
	while(node != NULL)
	{
		node_ = node;
		node = node->next;
		freeCheckInfo(node_->info);
		//free(node_);
	}
		free(list);
	}
}
int ExtTypeConAs(struct checkinfo *info1, struct checkinfo* info2)
{
	if(info1->type->baseType == info2->type->baseType)
	{
		return 1;
	}
	else if(info1->type->baseType > info2->type->baseType)
	{
		if(info1->type->baseType <= 2 && info2->type->baseType <= 2)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return 0;
	}
}
struct declarelist* connectDeclareList(struct declarelist* list, struct SymTableNode* node, int op)
{
	if(list == NULL)
	{
		list = (struct declarelist*)malloc(sizeof(struct declarelist));
		strcpy(list->name,node->name);
		list->next = NULL;
		if(op == 1)
			list->isDefined = 1;
		else
			list->isDefined = 0;
		if(op == 0)
			list->isDeclared = 1;
		else
			list->isDeclared = 0;
	}
	else
	{
		struct declarelist* decl = (struct declarelist*)malloc(sizeof(struct declarelist));
		strcpy(decl->name,node->name);
		decl->next = NULL;
		if(op == 1)
			decl->isDefined = 1;
		else
			decl->isDefined = 0;
		if(op == 0)
			decl->isDeclared = 1;
		else
			decl->isDeclared = 0;
		struct declarelist* lis = list;
		while(lis->next!= NULL)
		{
			lis = lis->next;
		}
		lis->next = decl;
	}
	return list;
}
int isDefined(struct declarelist* list, struct SymTableNode* node)
{
	struct declarelist* lis = list;
	while(lis != NULL)
	{
		if(strcmp(lis->name,node->name) == 0)
		{
			if(lis->isDefined == 1)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
		lis = lis->next;
	}
	return 0;
}
int isDeclared(struct declarelist* list, struct SymTableNode* node)
{
	struct declarelist* lis = list;
	while(lis != NULL)
	{
		if(strcmp(lis->name,node->name) == 0)
		{
			if(lis->isDeclared == 1)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
		lis = lis->next;
	}
	return 0;
}
void setDefined(struct declarelist* list, struct SymTableNode* node){
	struct declarelist* lis = list;
	while(lis != NULL)
	{
		if(strcmp(lis->name,node->name) == 0)
		{
			lis->isDefined = 1;
		}
		lis = lis->next;
	}
}
struct checkinfo* createCheckInfoNULL()
{
struct checkinfo* info = (struct checkinfo*)malloc(sizeof(struct checkinfo));
info->typevalid = 0;
info->valuevalid = 0;
struct ExtType * e = (struct ExtType*)malloc(sizeof(struct ExtType));
e->baseType = INVALID_t;
e->reference = 0;
e->isArray = false;
e->dim = 0;
e->dimArray = NULL;
info->type = e;
return	info;
}
int searchIsArrayType(struct SymTableList * tablelist, char *name)
{
  	struct SymTable * nowtable = tablelist->tail; 
	while(nowtable != tablelist->head)
	{
		struct SymTableNode* list = nowtable->head;
		while(list != NULL)
		{
			if(strcmp(list->name,name) == 0 && list->type->isArray == true)
			{
				return 1;
			}
			list = list->next;
		}
		nowtable = nowtable->prev;
	}
	struct SymTableNode* list = nowtable->head;
	while(list != NULL)
	{
		if(strcmp(list->name,name) == 0 && list->type->isArray == true)
		{
			return 1;
		}
		list = list->next;
	}
	return 0;
}