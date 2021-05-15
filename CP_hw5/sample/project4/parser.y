%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"
int yylex();
extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_Symbol;		/* declared in lex.l */

int scope = 0;
char fileName[256];
struct SymTable *symbolTable;
__BOOLEAN paramError;
struct PType *funcReturn;
__BOOLEAN semError = __FALSE;
int inloop = 0;

%}

%union {
	int intVal;
	float floatVal;	
	char *lexeme;
	struct idNode_sem *id;
	struct ConstAttr *constVal;
	struct PType *ptype;
	struct param_sem *par;
	struct expr_sem *exprs;
	struct expr_sem_node *exprNode;
	struct constParam *constNode;
	struct varDeclParam* varDeclNode;
};

%token	LE_OP NE_OP GE_OP EQ_OP AND_OP OR_OP
%token	READ BOOLEAN WHILE DO IF ELSE TRUE FALSE FOR INT PRINT BOOL VOID FLOAT DOUBLE STRING CONTINUE BREAK RETURN CONST
%token	L_PAREN R_PAREN COMMA SEMICOLON ML_BRACE MR_BRACE L_BRACE R_BRACE ADD_OP SUB_OP MUL_OP DIV_OP MOD_OP ASSIGN_OP LT_OP GT_OP NOT_OP

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <floatVal>FLOAT_CONST
%token <floatVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<ptype> scalar_type dim
%type<par> array_decl parameter_list
%type<constVal> literal_const
%type<constNode> const_list 
%type<exprs> variable_reference logical_expression logical_term logical_factor relation_expression arithmetic_expression term factor logical_expression_list literal_list initial_array
%type<intVal> relation_operator add_op mul_op dimension
%type<varDeclNode> identifier_list


%start program
%%

program :		decl_list 
			    funct_def
				decl_and_def_list 
				{
					checkUndefinedFunc(symbolTable);
					if(Opt_Symbol == 1)
					printSymTable( symbolTable, scope );	
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
				funcReturn = $1; 
				struct SymNode *node;
				node = findFuncDeclaration( symbolTable, $2 );
				
				if( node != 0 ){
					verifyFuncDeclaration( symbolTable, 0, $1, node );
				}
				else{
					insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __TRUE );
				}
			}
			compound_statement { funcReturn = 0; }	
		  | scalar_type ID L_PAREN parameter_list R_PAREN  
			{				
				funcReturn = $1;
				
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				// check and insert function into symbol table
				else{
					struct SymNode *node;
					node = findFuncDeclaration( symbolTable, $2 );

					if( node != 0 ){
						if(verifyFuncDeclaration( symbolTable, $4, $1, node ) == __TRUE){	
							insertParamIntoSymTable( symbolTable, $4, scope+1 );
						}				
					}
					else{
						insertParamIntoSymTable( symbolTable, $4, scope+1 );				
						insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __TRUE );
					}
				}
			} 	
			compound_statement { funcReturn = 0; }
		  | VOID ID L_PAREN R_PAREN 
			{
				funcReturn = createPType(VOID_t); 
				struct SymNode *node;
				node = findFuncDeclaration( symbolTable, $2 );

				if( node != 0 ){
					verifyFuncDeclaration( symbolTable, 0, createPType( VOID_t ), node );					
				}
				else{
					insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __TRUE );	
				}
			}
			compound_statement { funcReturn = 0; }	
		  | VOID ID L_PAREN parameter_list R_PAREN
			{									
				funcReturn = createPType(VOID_t);
				
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				// check and insert function into symbol table
				else{
					struct SymNode *node;
					node = findFuncDeclaration( symbolTable, $2 );

					if( node != 0 ){
						if(verifyFuncDeclaration( symbolTable, $4, createPType( VOID_t ), node ) == __TRUE){	
							insertParamIntoSymTable( symbolTable, $4, scope+1 );				
						}
					}
					else{
						insertParamIntoSymTable( symbolTable, $4, scope+1 );				
						insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __TRUE );
					}
				}
			} 
			compound_statement { funcReturn = 0; }		  
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
			{
				insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __FALSE );	
			}
		   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
		    {
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				else {
					insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __FALSE );
				}
			}
		   | VOID ID L_PAREN R_PAREN SEMICOLON
			{				
				insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __FALSE );
			}
		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
			{
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;	
				}
				else {
					insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __FALSE );
				}
			}
		   ;

parameter_list : parameter_list COMMA scalar_type ID
			   {
				struct param_sem *ptr;
				ptr = createParam( createIdList( $4 ), $3 );
				param_sem_addParam( $1, ptr );
				$$ = $1;
			   }
			   | parameter_list COMMA scalar_type array_decl
			   {
				$4->pType->type= $3->type;
				param_sem_addParam( $1, $4 );
				$$ = $1;
			   }
			   | scalar_type array_decl 
			   { 
				$2->pType->type = $1->type;  
				$$ = $2;
			   }
			   | scalar_type ID { $$ = createParam( createIdList( $2 ), $1 ); }
			   ;

var_decl : scalar_type identifier_list SEMICOLON
			{
				struct varDeclParam *ptr;
				struct SymNode *newNode;
				for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {						
					if( verifyRedeclaration( symbolTable, ptr->para->idlist->value, scope ) == __FALSE ) { }
					else {
						if( verifyVarInitValue( $1, ptr, symbolTable, scope ) ==  __TRUE ){	
							newNode = createVarNode( ptr->para->idlist->value, scope, ptr->para->pType );
							insertTab( symbolTable, newNode );											
						}
					}
				}
			}
			;

identifier_list : identifier_list COMMA ID
				{					
					struct param_sem *ptr;	
					struct varDeclParam *vptr;				
					ptr = createParam( createIdList( $3 ), createPType( VOID_t ) );
					vptr = createVarDeclParam( ptr, 0 );	
					addVarDeclParam( $1, vptr );
					$$ = $1; 					
				}
                | identifier_list COMMA ID ASSIGN_OP logical_expression
				{
					struct param_sem *ptr;	
					struct varDeclParam *vptr;				
					ptr = createParam( createIdList( $3 ), createPType( VOID_t ) );
					vptr = createVarDeclParam( ptr, $5 );
					vptr->isArray = __TRUE;
					vptr->isInit = __TRUE;	
					addVarDeclParam( $1, vptr );	
					$$ = $1;
					
				}
                | identifier_list COMMA array_decl ASSIGN_OP initial_array
				{
					struct varDeclParam *ptr;
					ptr = createVarDeclParam( $3, $5 );
					ptr->isArray = __TRUE;
					ptr->isInit = __TRUE;
					addVarDeclParam( $1, ptr );
					$$ = $1;	
				}
                | identifier_list COMMA array_decl
				{
					struct varDeclParam *ptr;
					ptr = createVarDeclParam( $3, 0 );
					ptr->isArray = __TRUE;
					addVarDeclParam( $1, ptr );
					$$ = $1;
				}
                | array_decl ASSIGN_OP initial_array
				{	
					$$ = createVarDeclParam( $1 , $3 );
					$$->isArray = __TRUE;
					$$->isInit = __TRUE;	
				}
                | array_decl 
				{ 
					$$ = createVarDeclParam( $1 , 0 ); 
					$$->isArray = __TRUE;
				}
                | ID ASSIGN_OP logical_expression
				{
					struct param_sem *ptr;					
					ptr = createParam( createIdList( $1 ), createPType( VOID_t ) );
					$$ = createVarDeclParam( ptr, $3 );		
					$$->isInit = __TRUE;
				}
                | ID 
				{
					struct param_sem *ptr;					
					ptr = createParam( createIdList( $1 ), createPType( VOID_t ) );
					$$ = createVarDeclParam( ptr, 0 );				
				}
                ;
		 
initial_array : L_BRACE literal_list R_BRACE { $$ = $2; }
			  ;

literal_list : literal_list COMMA logical_expression
				{
					struct expr_sem *ptr;
					for( ptr=$1; (ptr->next)!=0; ptr=(ptr->next) );				
					ptr->next = $3;
					$$ = $1;
				}
             | logical_expression
				{
					$$ = $1;
				}
             |
             ;

const_decl 	: CONST scalar_type const_list SEMICOLON
			{
				struct SymNode *newNode;				
				struct constParam *ptr;
				for( ptr=$3; ptr!=0; ptr=(ptr->next) ){
					if( verifyRedeclaration( symbolTable, ptr->name, scope ) == __TRUE ){//no redeclare
						if( ptr->value->category != $2->type ){//type different
							if( !(($2->type==FLOAT_t || $2->type == DOUBLE_t ) && ptr->value->category==INTEGER_t) ) {
								if(!($2->type==DOUBLE_t && ptr->value->category==FLOAT_t)){	
									fprintf( stdout, "########## Error at Line#%d: const type different!! ##########\n", linenum );
									semError = __TRUE;	
								}
								else{
									newNode = createConstNode( ptr->name, scope, $2, ptr->value );
									insertTab( symbolTable, newNode );
								}
							}							
							else{
								newNode = createConstNode( ptr->name, scope, $2, ptr->value );
								insertTab( symbolTable, newNode );
							}
						}
						else{
							newNode = createConstNode( ptr->name, scope, $2, ptr->value );
							insertTab( symbolTable, newNode );
						}
					}
				}
			}
			;

const_list : const_list COMMA ID ASSIGN_OP literal_const
			{				
				addConstParam( $1, createConstParam( $5, $3 ) );
				$$ = $1;
			}
		   | ID ASSIGN_OP literal_const
			{
				$$ = createConstParam( $3, $1 );	
			}
		   ;

array_decl : ID dim 
			{
				$$ = createParam( createIdList( $1 ), $2 );
			}
		   ;

dim : dim ML_BRACE INT_CONST MR_BRACE
		{
			if( $3 == 0 ){
				fprintf( stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum );
				semError = __TRUE;
			}
			else
				increaseArrayDim( $1, 0, $3 );			
		}
	| ML_BRACE INT_CONST MR_BRACE	
		{
			if( $2 == 0 ){
				fprintf( stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum );
				semError = __TRUE;
			}			
			else{		
				$$ = createPType( VOID_t ); 			
				increaseArrayDim( $$, 0, $2 );
			}		
		}
	;
	
compound_statement : {scope++;}L_BRACE var_const_stmt_list R_BRACE
					{ 
						// print contents of current scope
						if( Opt_Symbol == 1 )
							printSymTable( symbolTable, scope );
							
						deleteScope( symbolTable, scope );	// leave this scope, delete...
						scope--; 
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

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON
					{
						// check if LHS exists
						__BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
						// id RHS is not dereferenced, check and deference
						__BOOLEAN flagRHS = __TRUE;
						if( $3->isDeref == __FALSE ) {
							flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
						}
						// if both LHS and RHS are exists, verify their type
						if( flagLHS==__TRUE && flagRHS==__TRUE )
							verifyAssignmentTypeMatch( $1, $3 );
					}
				 | PRINT logical_expression SEMICOLON { verifyScalarExpr( $2, "print" ); }
				 | READ variable_reference SEMICOLON 
					{ 
						if( verifyExistence( symbolTable, $2, scope, __TRUE ) == __TRUE )						
							verifyScalarExpr( $2, "read" ); 
					}
				 ;

conditional_statement : IF L_PAREN conditional_if  R_PAREN compound_statement
					  | IF L_PAREN conditional_if  R_PAREN compound_statement
						ELSE compound_statement
					  ;
conditional_if : logical_expression { verifyBooleanExpr( $1, "if" ); };;					  

				
while_statement : WHILE L_PAREN logical_expression { verifyBooleanExpr( $3, "while" ); } R_PAREN { inloop++; }
					compound_statement { inloop--; }
				| { inloop++; } DO compound_statement WHILE L_PAREN logical_expression R_PAREN SEMICOLON  
					{ 
						 verifyBooleanExpr( $6, "while" );
						 inloop--; 
						
					}
				;


				
for_statement : FOR L_PAREN initial_expression SEMICOLON control_expression SEMICOLON increment_expression R_PAREN  { inloop++; }
					compound_statement  { inloop--; }
			  ;

initial_expression : initial_expression COMMA statement_for		
				   | initial_expression COMMA logical_expression
				   | logical_expression	
				   | statement_for
				   |
				   ;

control_expression : control_expression COMMA statement_for
				   {
						fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
						semError = __TRUE;	
				   }
				   | control_expression COMMA logical_expression
				   {
						if( $3->pType->type != BOOLEAN_t ){
							fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
							semError = __TRUE;	
						}
				   }
				   | logical_expression 
					{ 
						if( $1->pType->type != BOOLEAN_t ){
							fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
							semError = __TRUE;	
						}
					}
				   | statement_for
				   {
						fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
						semError = __TRUE;	
				   }
				   |
				   ;

increment_expression : increment_expression COMMA statement_for
					 | increment_expression COMMA logical_expression
					 | logical_expression
					 | statement_for
					 |
					 ;

statement_for 	: variable_reference ASSIGN_OP logical_expression
					{
						// check if LHS exists
						__BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
						// id RHS is not dereferenced, check and deference
						__BOOLEAN flagRHS = __TRUE;
						if( $3->isDeref == __FALSE ) {
							flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
						}
						// if both LHS and RHS are exists, verify their type
						if( flagLHS==__TRUE && flagRHS==__TRUE )
							verifyAssignmentTypeMatch( $1, $3 );
					}
					;
					 
					 
function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
							{
								verifyFuncInvoke( $1, $3, symbolTable, scope );
							}
						  | ID L_PAREN R_PAREN SEMICOLON
							{
								verifyFuncInvoke( $1, 0, symbolTable, scope );
							}
						  ;

jump_statement : CONTINUE SEMICOLON
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: continue can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
				}
			   | BREAK SEMICOLON 
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: break can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
				}
			   | RETURN logical_expression SEMICOLON
				{
					verifyReturnStatement( $2, funcReturn );
				}
			   ;

variable_reference : ID
					{
						$$ = createExprSem( $1 );
					}
				   | variable_reference dimension
					{	
						increaseDim( $1, $2 );
						$$ = $1;
					}
				   ;

dimension : ML_BRACE arithmetic_expression MR_BRACE
			{
				$$ = verifyArrayIndex( $2 );
			}
		  ;
		  
logical_expression : logical_expression OR_OP logical_term
					{
						verifyAndOrOp( $1, OR_t, $3 );
						$$ = $1;
					}
				   | logical_term { $$ = $1; }
				   ;

logical_term : logical_term AND_OP logical_factor
				{
					verifyAndOrOp( $1, AND_t, $3 );
					$$ = $1;
				}
			 | logical_factor { $$ = $1; }
			 ;

logical_factor : NOT_OP logical_factor
				{
					verifyUnaryNOT( $2 );
					$$ = $2;
				}
			   | relation_expression { $$ = $1; }
			   ;

relation_expression : arithmetic_expression relation_operator arithmetic_expression
					{
						verifyRelOp( $1, $2, $3 );
						$$ = $1;
					}
					| arithmetic_expression { $$ = $1; }
					;

relation_operator : LT_OP { $$ = LT_t; }
				  | LE_OP { $$ = LE_t; }
				  | EQ_OP { $$ = EQ_t; }
				  | GE_OP { $$ = GE_t; }
				  | GT_OP { $$ = GT_t; }
				  | NE_OP { $$ = NE_t; }
				  ;

arithmetic_expression : arithmetic_expression add_op term
			{
				verifyArithmeticOp( $1, $2, $3 );
				$$ = $1;
			}
                   | relation_expression { $$ = $1; }
		   | term { $$ = $1; }
		   ;

add_op	: ADD_OP { $$ = ADD_t; }
		| SUB_OP { $$ = SUB_t; }
		;
		   
term : term mul_op factor
		{
			if( $2 == MOD_t ) {
				verifyModOp( $1, $3 );
			}
			else {
				verifyArithmeticOp( $1, $2, $3 );
			}
			$$ = $1;
		}
     | factor { $$ = $1; }
	 ;

mul_op 	: MUL_OP { $$ = MUL_t; }
		| DIV_OP { $$ = DIV_t; }
		| MOD_OP { $$ = MOD_t; }
		;
		
factor : variable_reference
		{
			verifyExistence( symbolTable, $1, scope, __FALSE );
			$$ = $1;
			$$->beginningOp = NONE_t;
		}
	   | SUB_OP variable_reference
		{
			if( verifyExistence( symbolTable, $2, scope, __FALSE ) == __TRUE )
			verifyUnaryMinus( $2 );
			$$ = $2;
			$$->beginningOp = SUB_t;
		}		
	   | L_PAREN logical_expression R_PAREN
		{
			$2->beginningOp = NONE_t;
			$$ = $2; 
		}
	   | SUB_OP L_PAREN logical_expression R_PAREN
		{
			verifyUnaryMinus( $3 );
			$$ = $3;
			$$->beginningOp = SUB_t;
		}
	   | ID L_PAREN logical_expression_list R_PAREN
		{
			$$ = verifyFuncInvoke( $1, $3, symbolTable, scope );
			$$->beginningOp = NONE_t;
		}
	   | SUB_OP ID L_PAREN logical_expression_list R_PAREN
	    {
			$$ = verifyFuncInvoke( $2, $4, symbolTable, scope );
			$$->beginningOp = SUB_t;
		}
	   | ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $1, 0, symbolTable, scope );
			$$->beginningOp = NONE_t;
		}
	   | SUB_OP ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $2, 0, symbolTable, scope );
			$$->beginningOp = SUB_OP;
		}
	   | literal_const
	    {
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
			  $$->pType = createPType( $1->category );
			  $$->next = 0;
			  if( $1->hasMinus == __TRUE ) {
			  	$$->beginningOp = SUB_t;
			  }
			  else {
				$$->beginningOp = NONE_t;
			  }
		}
	   ;

logical_expression_list : logical_expression_list COMMA logical_expression
						{
			  				struct expr_sem *exprPtr;
			  				for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  				exprPtr->next = $3;
			  				$$ = $1;
						}
						| logical_expression { $$ = $1; }
						;

		  


scalar_type : INT { $$ = createPType( INTEGER_t ); }
			| DOUBLE { $$ = createPType( DOUBLE_t ); }
			| STRING { $$ = createPType( STRING_t ); }
			| BOOL { $$ = createPType( BOOLEAN_t ); }
			| FLOAT { $$ = createPType( FLOAT_t ); }
			;
 
literal_const : INT_CONST
				{
					int tmp = $1;
					$$ = createConstAttr( INTEGER_t, &tmp );
				}
			  | SUB_OP INT_CONST
				{
					int tmp = -$2;
					$$ = createConstAttr( INTEGER_t, &tmp );
				}
			  | FLOAT_CONST
				{
					float tmp = $1;
					$$ = createConstAttr( FLOAT_t, &tmp );
				}
			  | SUB_OP FLOAT_CONST
			    {
					float tmp = -$2;
					$$ = createConstAttr( FLOAT_t, &tmp );
				}
			  | SCIENTIFIC
				{
					double tmp = $1;
					$$ = createConstAttr( DOUBLE_t, &tmp );
				}
			  | SUB_OP SCIENTIFIC
				{
					double tmp = -$2;
					$$ = createConstAttr( DOUBLE_t, &tmp );
				}
			  | STR_CONST
				{
					$$ = createConstAttr( STRING_t, $1 );
				}
			  | TRUE
				{
					SEMTYPE tmp = __TRUE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
				}
			  | FALSE
				{
					SEMTYPE tmp = __FALSE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
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
}


