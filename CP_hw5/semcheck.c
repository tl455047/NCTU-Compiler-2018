#include <stdio.h>
#include "semcheck.h"
#include <stdlib.h>
#include <string.h>
#include "header.h"
#include "symtab.h"

extern int linenum;
extern __BOOLEAN semError; 

void printOperator( OPERATOR op )
{
	switch( op ) {
	 case ADD_t:
		fprintf(stdout,"+");
		break;
	 case SUB_t:
		fprintf(stdout,"-");
		break;
	 case MUL_t:
		fprintf(stdout,"*");
		break;
	 case DIV_t:
		fprintf(stdout,"/");
		break;
	 case MOD_t:
		fprintf(stdout,"%%");
		break;
	 case LT_t:
		fprintf(stdout,"<");
		break;
	 case LE_t:
		fprintf(stdout,"<=");
		break;
	 case EQ_t:
		fprintf(stdout,"==");
		break;
	 case GE_t:
		fprintf(stdout,">=");
		break;
	 case GT_t:
		fprintf(stdout,">");
		break;
	 case NE_t:
		fprintf(stdout,"!=");
		break;
	 case AND_t:
		fprintf(stdout,"&&");
		break;
	 case OR_t:
	 	fprintf(stdout,"||");
		break;
	 case NOT_t:
		fprintf(stdout,"!");
	}
}

struct idNode_sem *createIdList( const char *str ) 
{
	struct idNode_sem *newNode = (struct idNode_sem *)malloc(sizeof(struct idNode_sem));
	newNode->value = (char *)malloc(sizeof(char)*(strlen(str)+1));
	strcpy( newNode->value, str );
	newNode->next = 0;

	return newNode;
}

struct ConstAttr *createConstAttr( SEMTYPE type, void *value )
{
	struct ConstAttr *result = (struct ConstAttr *)malloc(sizeof(struct ConstAttr));
	result->category = type;

	result->hasMinus = __FALSE;

	switch( type ) {
	 case INTEGER_t:
		result->value.integerVal = *(int*)value;
		if( *(int*)value < 0 )
			result->hasMinus = __TRUE;
		break;
	 case FLOAT_t:
		result->value.floatVal = *(float*)value;
		if( *(float*)value < 0.0 )
			result->hasMinus = __TRUE;
		break;	 
	 case STRING_t:
		result->value.stringVal = (char *)malloc(sizeof(char)*(strlen((char *)value)+1));
		strcpy( result->value.stringVal, (char *)value );
		break;
	 case BOOLEAN_t:
		result->value.booleanVal = *(int*)value;
		break;
         case DOUBLE_t:
                result->value.doubleVal = *(double*)value;
                if( *(double*)value < 0.0 )
                        result->hasMinus = __TRUE;
                break;
	}
	return result;
}

struct constParam *createConstParam( struct ConstAttr *constNode, const char *id ){
	struct constParam *result = (struct constParam *)malloc(sizeof(struct constParam));
	result->value = constNode;
	result->name = (char *)malloc(sizeof(char)*(strlen(id)+1));
	strcpy( result->name, id );
	result->next = 0;
	
	return result; 
}

struct param_sem *createParam( struct idNode_sem *ids, struct PType *pType )
{
	struct param_sem *result = (struct param_sem *)malloc(sizeof(struct param_sem));
	result->idlist = ids;
	result->pType = pType;
	result->next = 0;

	return result;
}

struct varDeclParam *createVarDeclParam( struct param_sem *par, struct expr_sem *exp ){
	struct varDeclParam *result = (struct varDeclParam *)malloc(sizeof(struct varDeclParam));
	result->para = par;
	result->expr = exp;
	result->isArray = __FALSE;
	result->isInit = __FALSE;

	return result;
}

struct expr_sem *createExprSem( const char *id ) 
{
	struct expr_sem *result = (struct expr_sem *)malloc(sizeof(struct expr_sem));
	// setup beginningOp
	result->beginningOp = NONE_t;
	// setup isDeref
	result->isDeref = __FALSE;
	// setup varRef
	result->varRef = (struct var_ref_sem *)malloc(sizeof(struct var_ref_sem));
	if( strlen( id ) != 0 ){	
		result->varRef->id = (char *)malloc(sizeof(char)*(strlen(id)+1));
		strcpy( result->varRef->id, id );
	}
	result->varRef->dimNum = 0;
	result->varRef->dim = 0;
	// setup pType
	result->pType = 0;

	result->next = 0;

	return result;
}

void increaseDim( struct expr_sem* expr, SEMTYPE dimType )
{
	struct typeNode *newNode = (struct typeNode *)malloc(sizeof(struct typeNode));
	newNode->value = dimType;
	newNode->next = 0;

	if( expr->varRef->dim == 0 ) {	// the first dim
		++(expr->varRef->dimNum);
		expr->varRef->dim = newNode;
	}
	else {	// others, attached after the last
		struct typeNode *typePtr;
		for( typePtr=(expr->varRef->dim) ; (typePtr->next)!=0 ; typePtr=(typePtr->next) );
		typePtr->next = newNode;
		++(expr->varRef->dimNum);
	}
}

void idlist_addNode( struct idNode_sem *node, const char *string )
{
	struct idNode_sem *newNode = 0;
	newNode = (struct idNode_sem *)malloc(sizeof(struct idNode_sem ));
	newNode->value = (char *)malloc(sizeof(char)*(strlen(string)+1));
	strcpy( newNode->value, string );
	newNode->next = 0;

	struct idNode_sem *ptr;
	for( ptr=node ; (ptr->next)!=0 ; ptr=(ptr->next) );
	// add into idlist
	ptr->next = newNode;
}



void param_sem_addParam( struct param_sem *lhs, struct param_sem *rhs )
{
	struct param_sem *ptr;
	for( ptr=lhs ; (ptr->next)!=0 ; ptr=(ptr->next) );
	ptr->next = rhs;

}

void addVarDeclParam( struct varDeclParam *lhs, struct varDeclParam *rhs ){
	struct varDeclParam *ptr; 
	for( ptr=lhs ; (ptr->next)!=0 ; ptr=(ptr->next) );
	ptr->next = rhs;
}

void addConstParam( struct constParam *lhs, struct constParam *rhs ){
	struct constParam *ptr;	
	for( ptr=lhs ; (ptr->next)!=0 ; ptr=(ptr->next) );
	ptr->next = rhs;
	
}

struct PType *createPType( SEMTYPE type )
{
	struct PType *result = (struct PType *)malloc(sizeof(struct PType));
	result->isError = __FALSE;
	result->isArray = __FALSE;	// scalar
	result->type = type;
	result->dimNum = 0;
	result->dim = 0;		// null
	
	return result;
}

void increaseArrayDim( struct PType *pType, int lo, int hi )
{
	if( pType->isArray == __FALSE )
		pType->isArray = __TRUE;
	
	/* increase # of dim */
	++(pType->dimNum);
	// setup properties of newDim
	struct ArrayDimNode *newDim = (struct ArrayDimNode *)malloc(sizeof(struct ArrayDimNode));
	newDim->low = lo;
	newDim->high = hi;
	newDim->size = hi-lo;
	newDim->next = 0;	
	// add newDim into pType, in the rear of list
	struct ArrayDimNode *ptrr;
	
	if(pType->dim == 0) pType->dim = newDim;
	else{
		for( ptrr=pType->dim ; (ptrr->next)!=0 ; ptrr=(ptrr->next) );
		ptrr->next = newDim;	
	}
}

struct ArrayDimNode *copyArrayDimList( struct ArrayDimNode *src )
{
	if( src == 0 ) {
		return 0;
	}
	else {
		// copy the first element
		struct ArrayDimNode *dest = (struct ArrayDimNode *)malloc(sizeof(struct ArrayDimNode));;
		dest->low = src->low;
		dest->high = src->high;
		dest->size = src->size;
		dest->next = 0;

		struct ArrayDimNode *ptr = dest;	// ptr: points to the last element of new list
		struct ArrayDimNode *arrPtr;
		for( arrPtr=(src->next) ; arrPtr!=0 ; arrPtr=(arrPtr->next) ) {
				struct ArrayDimNode *newNode = (struct ArrayDimNode *)malloc(sizeof(struct ArrayDimNode));
				newNode->low = arrPtr->low;
				newNode->high = arrPtr->high;
				newNode->size = arrPtr->size;
				newNode->next = 0;

				ptr->next = newNode;	// attach to list
				ptr = newNode;
		}
		return dest;
	}
}

struct PType *copyPType( struct PType *src )
{
	if( src == 0 ) {
		return 0;
	}
	else {
		struct PType *dest = (struct PType *)malloc(sizeof(struct PType));
		dest->isError = src->isError;
		dest->isArray = src->isArray;
		dest->type = src->type;
		dest->dimNum = src->dimNum;
		dest->dim = copyArrayDimList( src->dim );
		return dest;
	}
}

/* verification(s) */


void verifyArrayDim( struct PType *pType, int lo, int hi )
{
	__BOOLEAN isPass = __TRUE;
	
	if( lo<0 || hi<0 ) {
		isPass = __FALSE;
	} 
	else if( lo >= hi ) {
		isPass = __FALSE;
	}

	if( isPass == __FALSE ) {
		pType->isError = __TRUE;
	}
}

void verifyArrayType( struct idNode_sem *ids, struct PType *pType )
{
	struct idNode_sem *ptr;
	if( pType->isError == __TRUE ) {
		fprintf( stdout, "########## Error at Line#%d: wrong dimension declaration for array ", linenum ); semError = __TRUE;
		printf("%s", ids->value);
		for( ptr=ids->next ; ptr!=0 ; ptr=(ptr->next) ) {
			printf(", %s", ptr->value);
		}
		printf(" ##########\n");
	}
}

SEMTYPE verifyArrayIndex( struct expr_sem *expr )
{
	SEMTYPE result;
	if( expr->isDeref == __FALSE ) {
		fprintf( stdout, "########## Error at Line#%d: array index is not integer ##########\n", linenum ); semError = __TRUE;
		result = ERROR_t;
	}
	else if( expr->pType->isArray == __TRUE ) {	
		fprintf( stdout, "########## Error at Line#%d: array index cannot be arrya_type ##########\n", linenum ); semError = __TRUE;
		result = ERROR_t;
	}
	else if( expr->pType->type != INTEGER_t ) {
		fprintf( stdout, "########## Error at Line#%d: array index is not integer ##########\n", linenum ); semError = __TRUE;
		result = ERROR_t;
	}
	else {
		result = INTEGER_t;
	}
	return result;
}

__BOOLEAN verifyRedeclaration( struct SymTable *table, const char *str, int scope )
{
	__BOOLEAN result = __TRUE;
	// then check normal variable(s)
	if( lookupSymbol( table, str, scope, __TRUE ) == 0 ) {	// only search current scope
		result =  __TRUE;
	}
	else {
		fprintf( stdout, "########## Error at Line#%d: symbol %s is redeclared ##########\n", linenum, str ); semError = __TRUE;
		result = __FALSE;
	}
	
	return result;
}

__BOOLEAN verifyExistence( struct SymTable *table, struct expr_sem *expr, int scope, __BOOLEAN isAssignmentLHS )
{
	__BOOLEAN result = __TRUE;
	struct SymNode *node = 0;
	
	node = lookupSymbol( table, expr->varRef->id, scope, __FALSE );	// if not found, check normal symbol
	
	if( node == 0 ) {	// symbol not found
		fprintf( stdout, "########## Error at Line#%d: '%s' is not declared ##########\n", linenum, expr->varRef->id ); semError = __TRUE;
		expr->pType = createPType( ERROR_t );
		result = __FALSE;
	}
	else {	// deference and verify, if pass, setup PType field in expr_sem

		// expr is dereferenced...
		expr->isDeref = __TRUE;

		if( node->category == FUNCTION_t ) {
			fprintf( stdout, "########## Error at Line#%d: '%s' is function ##########\n", linenum, node->name ); semError = __TRUE;
			expr->pType = createPType( ERROR_t );	
			result = __FALSE;
		}
		else if( node->category==CONSTANT_t && isAssignmentLHS==__TRUE ) {
			fprintf( stdout, "########## Error at Line#%d: constant '%s' cannot be assigned ##########\n", linenum, node->name ); semError = __TRUE;
			expr->pType = createPType( ERROR_t );
			result = __FALSE;
		}
		else {
			if( expr->varRef->dimNum == 0 ) {
				expr->pType = copyPType( node->type );
			}
			else {	// dereference dimension
				if( node->type->dimNum < expr->varRef->dimNum ) {
					fprintf( stdout, "########## Error at Line#%d: '%s' is %d dimension(s), but reference in %d dimension(s) ##########\n", linenum, node->name, node->type->dimNum, expr->varRef->dimNum ); semError = __TRUE;
					expr->pType = createPType( ERROR_t );
					result = __FALSE;
				}
				else if( node->type->dimNum == expr->varRef->dimNum ) {	// result in scalar!
					expr->pType = createPType( node->type->type );
				}
				else {								// result in array type
					expr->pType = (struct PType *)malloc(sizeof(struct PType));
					expr->pType->isError = __FALSE;
					expr->pType->isArray = __TRUE;
					expr->pType->type = node->type->type;
					expr->pType->dimNum = (node->type->dimNum)-(expr->varRef->dimNum);
					
					int i;
					struct ArrayDimNode *arrPtr;
					for( i=0, arrPtr=(node->type->dim) ; i<(expr->varRef->dimNum) ; i++, arrPtr=(arrPtr->next) );
					expr->pType->dim = copyArrayDimList( arrPtr );
				}
			}
		}
	}
	return result;
}

/**
 * void verifyUnaryMinus: mark the subexpression with beginning unaryOp, and check type mismatch
 */
void verifyUnaryMinus( struct expr_sem *expr )
{
	expr->beginningOp = SUB_t;

	if( expr->isDeref == __FALSE ) {
		// deference and verify existence and type
		//struct SymNode *node = lookupSymbol( table );

		fprintf( stdout, "########## Error at Line#%d: operand of unary - is not integer/real ##########\n", linenum ); semError = __TRUE;
		expr->isDeref = __TRUE;
		expr->pType->type = ERROR_t;
	}
	else {
		if( !(((expr->pType->type)==INTEGER_t) || ((expr->pType->type)==FLOAT_t) || ((expr->pType->type)==DOUBLE_t)) ) {
			fprintf( stdout, "########## Error at Line#%d: operand of unary - is not integer/real ##########\n", linenum ); semError = __TRUE;
			expr->pType->type = ERROR_t;
		}
	}
	// if pass 
}

void verifyUnaryNOT( struct expr_sem *expr )
{
	expr->beginningOp = NOT_t;

	if( expr->pType->dimNum != 0 ) {
		fprintf( stdout, "########## Error at Line#%d: operand of 'not' cannot be array_type ##########\n", linenum ); semError = __TRUE;
		expr->pType->type = ERROR_t;
	}
	else if( expr->pType->type != BOOLEAN_t ) {
		fprintf( stdout, "########## Error at Line#%d: operand of 'not' is not boolean ##########\n", linenum ); semError = __TRUE;
		expr->pType->type = ERROR_t;
	}
	else {	// pass verification, result is boolean
		expr->pType->type = BOOLEAN_t;
	}
}

void verifyAssignmentTypeMatch( struct expr_sem *LHS, struct expr_sem *RHS )
{
	__BOOLEAN misMatch = __FALSE;

	if( (LHS->pType->type)==ERROR_t || (RHS->pType->type)==ERROR_t ) {	// previous error(s)
		// ......
	}
	// verify type
	else if( LHS->pType->type != RHS->pType->type ) {
		if( !((LHS->pType->type==FLOAT_t || LHS->pType->type==DOUBLE_t )&&RHS->pType->type==INTEGER_t) ) {
			if(!(LHS->pType->type==DOUBLE_t&&RHS->pType->type==FLOAT_t)){	
				misMatch = __TRUE;
			}
		}
	}

	if( misMatch == __TRUE ) {
		fprintf( stdout, "########## Error at Line#%d: type mismatch, LHS= ", linenum ); semError = __TRUE;
		printType( LHS->pType, 0 );
		fprintf( stdout, ", RHS= " );
		printType( RHS->pType, 0 );
		fprintf( stdout, " ##########\n" );
	}

	// verify dimension #
	if( (LHS->pType->dimNum > 0) || (RHS->pType->dimNum > 0)){
		fprintf( stdout, "########## Error at Line#%d: array type assignment ##########\n", linenum ); semError = __TRUE;
	}
	
}

__BOOLEAN verifyVarInitValue( struct PType *scalar, struct varDeclParam *var, struct SymTable *table, int scope ){
	__BOOLEAN result = __TRUE;
	
	var->para->pType->type = scalar->type; 

	if( var->isInit == __TRUE ){
		
		if( var->isArray == __TRUE ){
			result = verifyArrayInitVal( scalar, var, table, scope );	
		}
		else{//not array decl
			if( var->expr->isDeref == __FALSE ){				
				if( verifyExistence( table, var->expr,  scope, __FALSE ) == __FALSE ){ 					
					return __FALSE; 
				}				
			}
			if( var->expr->pType->type != scalar->type ){
				if( !((scalar->type==FLOAT_t || scalar->type==DOUBLE_t) &&  var->expr->pType->type==INTEGER_t) ){ //float|double  = int
					if( !(scalar->type==DOUBLE_t && var->expr->pType->type==FLOAT_t) ){// double = float
						result = __FALSE;			
						fprintf( stdout, "########## Error at Line#%d: initial value type error ##########\n", linenum ); semError = __TRUE;
					}
				}
				else if( var->expr->pType->isArray == __TRUE ){
					result = __FALSE;
					fprintf( stdout, "########## Error at Line#%d: initial value type(array type) error ##########\n", linenum ); semError = __TRUE;
				}
			}
			else if( var->expr->pType->isArray == __TRUE ){
				result = __FALSE;
				fprintf( stdout, "########## Error at Line#%d: initial value type(array type) error ##########\n", linenum ); semError = __TRUE;
			}
		}
		
	}

	
	return result;
}

__BOOLEAN verifyArrayInitVal( struct PType *scalar, struct varDeclParam *var, struct SymTable *table, int scope ){
	__BOOLEAN result = __TRUE;

	struct ArrayDimNode *ptr;
	int element = 1, initElement = 0;	
	for( ptr=var->para->pType->dim; ptr!=0; ptr=(ptr->next) ){
		if( ptr->size > 0 ){
			element = element * ptr->size;
		}
	}

	struct expr_sem *tmp;
	for( tmp=var->expr; tmp!=0; tmp=(tmp->next) ){
		initElement ++;
		if(initElement > element)
			break;
	
  	 	if( tmp->isDeref == __FALSE ){
			if( verifyExistence( table, tmp,  scope, __FALSE ) == __FALSE ){ 
				return __FALSE; 
			}	
		}
	
		if( tmp->pType->type == ERROR_t ){
			var->para->pType->type = ERROR_t;
			return __FALSE; 
		}
		else{			
			
			if( var->para->pType->type != tmp->pType->type ){ //type different
				if( !((scalar->type==FLOAT_t || scalar->type==DOUBLE_t) &&  tmp->pType->type==INTEGER_t) ){ //float|double  = int
					if( !(scalar->type==DOUBLE_t && tmp->pType->type==FLOAT_t) ){// double = float
						result = __FALSE;			
						fprintf( stdout, "########## Error at Line#%d: initial value type error ##########\n", linenum ); semError = __TRUE;
					}
				}
				else if( tmp->pType->isArray == __TRUE ){
					var->para->pType->type = ERROR_t;
					result = __FALSE;
					fprintf( stdout, "########## Error at Line#%d: initial value type(array type) error ##########\n", linenum ); semError = __TRUE;
				}
			}
			else if( tmp->pType->isArray == __TRUE ){
				var->para->pType->type = ERROR_t;
				fprintf( stdout, "########## Error at Line#%d: initial value can't be array type ##########\n", linenum ); semError = __TRUE;
				result = __FALSE;
			}			
		}
	}
	
	if( initElement > element ){
		var->para->pType->type = ERROR_t;
		fprintf( stdout, "########## Error at Line#%d: too many initial value numbers ##########\n", linenum ); semError = __TRUE;
		result = __FALSE;
	}

	return result;
}

void verifyModOp( struct expr_sem *op1, struct expr_sem *op2 ) 
{
	if( (op1->pType->type)==ERROR_t || (op2->pType->type)==ERROR_t ) {
		op1->pType->type = ERROR_t;
	}
	else if( op2->beginningOp != NONE_t ) {
		fprintf( stdout, "########## Error at Line#%d: adjacent operator 'mod", linenum); semError = __TRUE;
		fprintf( stdout ,"' and '" );
		printOperator( op2->beginningOp );
		fprintf( stdout ,"'\n" );
		op1->pType->type = ERROR_t;		
	}
	else if( (op1->pType->dimNum)!=0 || (op2->pType->dimNum)!=0 ) {
		fprintf( stdout, "########## Error at Line#%d: operand(s) between 'mod' are array_type\n", linenum ); semError = __TRUE;
		op1->pType->type = ERROR_t;		
	}
	else if( (op1->pType->type)!=INTEGER_t || (op2->pType->type)!=INTEGER_t ) {
		fprintf( stdout, "########## Error at Line#%d: operand(s) between 'mod' are not integer\n", linenum ); semError = __TRUE; 
		op1->pType->type = ERROR_t;
	}
	else {	// pass verify
		op1->pType->type = INTEGER_t;
	}
}

void verifyArithmeticOp( struct expr_sem *op1, OPERATOR operator, struct expr_sem *op2 ) 
{

	if( (op1->pType->type)==ERROR_t || (op2->pType->type)==ERROR_t ) {
		op1->pType->type = ERROR_t;
	}
	else if( op2->beginningOp != NONE_t ) {
		fprintf( stdout, "########## Error at Line#%d: adjacent operator '", linenum); semError = __TRUE;
		printOperator( operator );
		fprintf( stdout ,"' and '" );
		printOperator( op2->beginningOp );
		fprintf( stdout ,"'\n" );
		op1->pType->type = ERROR_t;		
	}
	else if( (op1->pType->dimNum)!=0 || (op2->pType->dimNum)!=0 ) {
		fprintf( stdout, "########## Error at Line#%d: operand(s) between '", linenum); semError = __TRUE;
		printOperator( operator );
		fprintf( stdout ,"' are array_type ##########\n" );
		op1->pType->type = ERROR_t;		
	}
	else {
		if( op1->pType->type==STRING_t && op2->pType->type==STRING_t ) {	// string concatenation			
				fprintf( stdout, "########## Error at Line#%d: operand(s) between '", linenum); semError = __TRUE;
				printOperator( operator );
				fprintf( stdout ,"' are string type ##########\n" );			
		}
		else if( ((op1->pType->type==INTEGER_t || op1->pType->type==FLOAT_t || op1->pType->type==DOUBLE_t) && \
			(op2->pType->type==INTEGER_t || op2->pType->type==FLOAT_t || op2->pType->type==DOUBLE_t)) ) {	// need to consider type coercion
			if( op1->pType->type==INTEGER_t && op2->pType->type==INTEGER_t ) {
				op1->pType->type = INTEGER_t;
			}
			else {
				if(op1->pType->type==DOUBLE_t || op2->pType->type==DOUBLE_t){				
					op1->pType->type = DOUBLE_t;

				}
				else
					op1->pType->type = FLOAT_t;	
			}
		}
		else {	// fail verify, dump error message
			fprintf( stdout, "########## Error at Line#%d: operand(s) between '", linenum); semError = __TRUE;
			printOperator( operator );
			fprintf( stdout, "' are not integer/real ##########\n" );
			op1->pType->type = ERROR_t;		
		}
	}
}

void verifyRelOp( struct expr_sem *op1, OPERATOR operator, struct expr_sem *op2 )
{
	if( (op1->pType->type)==ERROR_t || (op2->pType->type)==ERROR_t ) {
		op1->pType->type = ERROR_t;
	}
	else if( op2->beginningOp != NONE_t ) {
		fprintf( stdout, "########## Error at Line#%d: adjacent operator '", linenum); semError = __TRUE;
		printOperator( operator );
		fprintf( stdout ,"' and '" );
		printOperator( op2->beginningOp );
		fprintf( stdout ,"'\n" );
		op1->pType->type = ERROR_t;		
	}
	else if( (op1->pType->dimNum)!=0 || (op2->pType->dimNum)!=0 ) {
		fprintf( stdout, "########## Error at Line#%d: operand(s) between '", linenum); semError = __TRUE;
		printOperator( operator );
		fprintf( stdout ,"' are array_type ##########\n" );
		op1->pType->type = ERROR_t;		
	}
	else if( !((op1->pType->type==INTEGER_t || op1->pType->type==FLOAT_t || op1->pType->type==DOUBLE_t) && (op2->pType->type==INTEGER_t || op2->pType->type==FLOAT_t || op2->pType->type==DOUBLE_t)) ) {	
		if( op1->pType->type==BOOLEAN_t && op2->pType->type==BOOLEAN_t && ( operator==EQ_t || operator==NE_t )){}
		else{
			fprintf( stdout, "########## Error at Line#%d: operand(s) between '", linenum); semError = __TRUE;
			printOperator( operator );
			fprintf( stdout, "' are not integer/real or the same type##########\n" );
			op1->pType->type = ERROR_t;
		}
	}
	else {	// pass verification, result is boolean!
		op1->pType->type = BOOLEAN_t;
	}
}

void verifyAndOrOp( struct expr_sem *op1, OPERATOR operator, struct expr_sem *op2 )
{
	if( (op1->pType->type)==ERROR_t || (op2->pType->type)==ERROR_t ) {
		op1->pType->type = ERROR_t;
	}
	else if( op2->beginningOp != NONE_t ) {
		fprintf( stdout, "########## Error at Line#%d: adjacent operator '", linenum); semError = __TRUE;
		printOperator( operator );
		fprintf( stdout ,"' and '" );
		printOperator( op2->beginningOp );
		fprintf( stdout ,"' ##########\n" );
		op1->pType->type = ERROR_t;		
	}
	else if( (op1->pType->dimNum)!=0 || (op2->pType->dimNum)!=0 ) {
		fprintf( stdout, "########## Error at Line#%d: operand(s) between '", linenum ); semError = __TRUE;
		printOperator( operator );
		fprintf( stdout, "' are array_type ##########\n" );
		op1->pType->type = ERROR_t;		
	}
	else if( (op1->pType->type)!=BOOLEAN_t || (op2->pType->type)!=BOOLEAN_t ) {
		fprintf( stdout, "########## Error at Line#%d: operand(s) between '", linenum ); semError = __TRUE;
		printOperator( operator );
		fprintf( stdout, "' are not boolean ##########\n" );
		op1->pType->type = ERROR_t;
	}
	else {	// pass verification, result is boolean!
		op1->pType->type = BOOLEAN_t;
	}
}

struct expr_sem *verifyFuncInvoke( const char *id, struct expr_sem *exprList, struct SymTable *table, int scope )
{
	struct expr_sem *result = (struct expr_sem *)malloc(sizeof(struct expr_sem));
	// setup attributes except `pType`
	result->beginningOp = NONE_t;
	result->isDeref = __TRUE;
	result->varRef = 0;
	result->next = 0;

	struct SymNode *node = 0;
	node = lookupSymbol( table, id, 0, __FALSE );	// function always in scope 0
	
	if( node == 0 ) {	// symbol not found
		fprintf( stdout, "########## Error at Line#%d: symbol '%s' not found ##########\n", linenum, id ); semError = __TRUE;
		result->pType = createPType( ERROR_t );
	}
	else if( node->category != FUNCTION_t  ) {
		fprintf( stdout, "########## Error at Line#%d: symbol '%s' is not a function ##########\n", linenum, id ); semError = __TRUE;
		result->pType = createPType( ERROR_t );
	}
	else {			// check parameters...
		if( node->attribute->formalParam->paramNum == 0 ) {
			if( exprList != 0 ) {
				fprintf( stdout, "########## Error at Line#%d: too many arguments to function %s ##########\n", linenum, node->name ); semError = __TRUE;
				result->pType = createPType( ERROR_t );
			}
			else {
				//result->pType = node->type;	// return type of function declaration
				result->pType = createPType(node->type->type);
			}
		}
		else {
			__BOOLEAN mismatch = __FALSE;	
			struct PTypeList *listPtr;
			struct expr_sem *exprPtr;
			// compare each parameter
			for( listPtr=(node->attribute->formalParam->params), exprPtr=exprList ; (listPtr!=0)&&(exprPtr!=0) ; listPtr=(listPtr->next), exprPtr=(exprPtr->next) ) {
				// verify type
				if( listPtr->value->type != exprPtr->pType->type ) {
					if( !((listPtr->value->type==FLOAT_t)&&(exprPtr->pType->type==INTEGER_t))
						&& !((listPtr->value->type==DOUBLE_t)&&(exprPtr->pType->type==INTEGER_t))
						&& !((listPtr->value->type==DOUBLE_t)&&(exprPtr->pType->type==FLOAT_t)) )
						mismatch = __TRUE;
				}
				// verify dimension #
				if( listPtr->value->dimNum != exprPtr->pType->dimNum ) {
					mismatch = __TRUE;
				}
				else {		// dim # is the same, verify each dim(s)
					struct ArrayDimNode *lhsPtr, *rhsPtr;
					for( lhsPtr=(listPtr->value->dim), rhsPtr=(exprPtr->pType->dim) ; lhsPtr!=0 ; lhsPtr=(lhsPtr->next), rhsPtr=(rhsPtr->next) ) {
						if( lhsPtr->size != rhsPtr->size ) {
							mismatch = __TRUE;
							break;
						}
					}
				}
			}
			if( mismatch == __TRUE ) {
				fprintf( stdout, "########## Error at Line#%d: parameter type mismatch ##########\n", linenum ); semError = __TRUE;
				result->pType = createPType( ERROR_t );
			}
			else {
				if( listPtr != 0 ) {
					fprintf( stdout, "########## Error at Line#%d: too few arguments to function '%s' ##########\n", linenum, node->name ); semError = __TRUE;
					result->pType = createPType( ERROR_t );
				}
				else if( exprPtr != 0 ) {
					fprintf( stdout, "########## Error at Line#%d: too many arguments to function '%s' ##########\n", linenum, node->name ); semError = __TRUE;
					result->pType = createPType( ERROR_t );
				}
				else {					
					result->pType = createPType(node->type->type);
				}
			}
		}
	}
	return result;
}
/**
 * if expression is not in scalar type, produce error message
 */
void verifyScalarExpr( struct expr_sem *expr, const char *str )
{
	if( expr->pType->dim > 0 ) {
		fprintf( stdout, "########## Error at Line#%d: %s statement's operand is array type ##########\n", linenum, str ); semError = __TRUE;
	}
}

void verifyBooleanExpr( struct expr_sem *expr, const char *str )
{
	if( expr->pType->dim > 0 ) {
		fprintf( stdout, "########## Error at Line#%d: %s statement's operand is array type ##########\n", linenum, str ); semError = __TRUE;
	}
	else if( expr->pType->type != BOOLEAN_t ) {
		fprintf( stdout, "########## Error at Line#%d: %s statement's operand is not boolean type ##########\n", linenum, str ); semError = __TRUE;
	}
}

void verifyReturnStatement( struct expr_sem *expr, struct PType *funcReturn )
{
	if( funcReturn == 0 ) {
		fprintf( stdout, "########## Error at Line#%d: program cannot be returned ##########\n", linenum ); semError = __TRUE;
	}
	else if( funcReturn->type == VOID_t ) {
		fprintf( stdout, "########## Error at Line#%d: void function cannot be returned ##########\n", linenum ); semError = __TRUE;
	}
	else if( funcReturn->type != expr->pType->type ) {
                 if( !((funcReturn->type==FLOAT_t || funcReturn->type==DOUBLE_t )&&expr->pType->type==INTEGER_t) ) {
                        if(!(funcReturn->type==DOUBLE_t&&expr->pType->type==FLOAT_t)){
		           fprintf( stdout, "########## Error at Line#%d: return type mismatch ##########\n", linenum ); semError = __TRUE;
                        }
                }
	}
	else if( funcReturn->dimNum != expr->pType->dimNum ) {
		fprintf( stdout, "########## Error at Line#%d: return dimension number mismatch ##########\n", linenum ); semError = __TRUE;
	}
	else {
		struct ArrayDimNode *returnDim, *exprDim;
		int i;
		for( returnDim=(funcReturn->dim), exprDim=(expr->pType->dim), i=0 ; returnDim!=0 ; returnDim=(returnDim->next), exprDim=(exprDim->next), ++i ) {
			if( returnDim->size != exprDim->size ) {
				fprintf( stdout, "########## Error at Line#%d: return dimension #%d's size mismatch ##########\n", linenum, i ); semError = __TRUE;
			}
		}
	}
}

__BOOLEAN insertParamIntoSymTable( struct SymTable *table, struct param_sem *params, int scope )
{
	__BOOLEAN result = __FALSE;

	// without parameters
	if( params == 0 ) {
		result = __FALSE;
	}
	else {
		struct param_sem *parPtr;
		struct idNode_sem *idPtr;
		struct SymNode *newNode;
		for( parPtr=params ; parPtr!=0 ; parPtr=(parPtr->next) ) {
			
			if( parPtr->pType->isError == __TRUE ) { 
				result = __TRUE;
			}	// array_type error ?
			else {
				for( idPtr=(parPtr->idlist) ; idPtr!=0 ; idPtr=(idPtr->next) ) {
					if( verifyRedeclaration( table, idPtr->value, scope ) ==__FALSE ) { result = __TRUE;  }
					else {	// without error, insert into symbol table
						newNode = createParamNode( idPtr->value, scope, parPtr->pType );
						insertTab( table, newNode );
					}
				}
			}
		}
	}
	return result;	// __TRUE: with some error(s)
}

__BOOLEAN checkFuncParam( struct param_sem *params ){
	__BOOLEAN result = __FALSE;
	// without parameters
	if( params == 0 ) {
		result = __FALSE;
	}
	else {
		struct param_sem *parPtr;		
		for( parPtr=params ; parPtr!=0 ; parPtr=(parPtr->next) ) {			
			if( parPtr->pType->isError == __TRUE ) { 
				result = __TRUE;
			}		
		}
	}
	return result;	// __TRUE: with some error(s)
}

void insertFuncIntoSymTable( struct SymTable *table, const char *id, struct param_sem *params, struct PType *retType, int scope, __BOOLEAN isDefine )
{
	if( verifyRedeclaration( table, id, scope ) == __FALSE ) { return; }	
	else {
		struct FuncAttr *formalParam = (struct FuncAttr *)malloc(sizeof(struct FuncAttr ));
		formalParam->paramNum = 0;
		formalParam->params = 0;

		if( params == 0 ) {
			// without parameters
		}
		else {
			struct param_sem *parPtr;
			struct idNode_sem *idPtr;

			struct PTypeList *lastPtr = 0;	// incicate the last element in PType list

			for( parPtr=params ; parPtr!=0 ; parPtr=(parPtr->next) ) {
				for( idPtr=(parPtr->idlist) ; idPtr!=0 ; idPtr=(idPtr->next) ) {
					if( formalParam->paramNum == 0 ) {	// add the first entry
						formalParam->params = (struct PTypeList *)malloc(sizeof(struct PTypeList));
						formalParam->params->value = copyPType( parPtr->pType );
						formalParam->params->next = 0;

						++(formalParam->paramNum);

						lastPtr = formalParam->params;
					}
					else {
						struct PTypeList *newPTypeList = (struct PTypeList *)malloc(sizeof(struct PTypeList));
						newPTypeList->value = copyPType( parPtr->pType );
						newPTypeList->next = 0;
						lastPtr->next = newPTypeList;
						++(formalParam->paramNum);

						lastPtr = (lastPtr->next);
					}
				}
			}
		}
	
		struct SymNode *newNode = createFuncNode( id, scope, retType, formalParam );
		newNode->isFuncDefine = isDefine;
		newNode->declarationLine = linenum;
		insertTab( table, newNode );
	}
}

struct SymNode *findFuncDeclaration( struct SymTable *table, char *name ){
	struct SymNode *node = 0;
	node = lookupSymbol( table, name, 0, __FALSE );// only search current scope

	if( node == 0 ) {	
		return 0;
	}

	return node;
}

__BOOLEAN verifyFuncDeclaration( struct SymTable *table, struct param_sem *par, struct PType *scalarType, struct SymNode *node ){
	__BOOLEAN result = __TRUE;

	if( node->isFuncDefine == __TRUE ){
		fprintf( stdout, "########## Error at Line#%d: function '%s' has been defined ##########\n", linenum, node->name ); semError = __TRUE;
		result = __FALSE;
	}
 	else if( node->category != FUNCTION_t  ) {
		fprintf( stdout, "########## Error at Line#%d: name '%s' has been used ##########\n", linenum, node->name ); semError = __TRUE;
		result = __FALSE;						
	}
	else {			// check parameters...
		if( scalarType->type != node->type->type ){
			fprintf( stdout, "########## Error at Line#%d: %s function return type error ##########\n", linenum, node->name ); semError = __TRUE;
			result = __FALSE;	
		}
		else if( node->attribute->formalParam->paramNum == 0 ) {
			if( par != 0 ) {
				fprintf( stdout, "########## Error at Line#%d: too many arguments to function %s ##########\n", linenum, node->name ); semError = __TRUE;
				result = __FALSE;				
			}
			else{
				node->isFuncDefine = __TRUE;
			}		
		}
		else {
			__BOOLEAN mismatch = __FALSE;	
			struct PTypeList *listPtr;	// = node->attribute->formalParam->params;
			struct param_sem *exprPtr;
			// compare each parameter
			for( listPtr=(node->attribute->formalParam->params), exprPtr=par ; (listPtr!=0)&&(exprPtr!=0) ; listPtr=(listPtr->next), exprPtr=(exprPtr->next) ) { 
				// verify type
				if( listPtr->value->type != exprPtr->pType->type ) {
					if( listPtr->value->type != exprPtr->pType->type )
						mismatch = __TRUE;
				}
				// verify dimension #
				if( listPtr->value->dimNum != exprPtr->pType->dimNum ) {
					mismatch = __TRUE;
				}
				else {		// dim # is the same, verify each dim(s)
					struct ArrayDimNode *lhsPtr, *rhsPtr;
					for( lhsPtr=(listPtr->value->dim), rhsPtr=(exprPtr->pType->dim) ; lhsPtr!=0 ; lhsPtr=(lhsPtr->next), rhsPtr=(rhsPtr->next) ) {
						if( lhsPtr->size != rhsPtr->size ) {
							mismatch = __TRUE;
							break;
						}
					}
				}
			}
			if( mismatch == __TRUE ) {
				fprintf( stdout, "########## Error at Line#%d: parameter type mismatch ##########\n", linenum ); semError = __TRUE;
				result = __FALSE;
			}
			else {
				if( listPtr != 0 ) {
					fprintf( stdout, "########## Error at Line#%d: too few arguments to function '%s' ##########\n", linenum, node->name ); semError = __TRUE;
					result = __FALSE;
				}
				else if( exprPtr != 0 ) {
					fprintf( stdout, "########## Error at Line#%d: too many arguments to function '%s' ##########\n", linenum, node->name ); semError = __TRUE;
					result = __FALSE;
				}
				else{
					node->isFuncDefine = __TRUE;
				}				
			}
		}
	}
	
	return result;
}
void checkUndefinedFunc(struct SymTable *symtab)
{
	for(int i=0;i<HASHBUNCH;++i)
	{
		if(symtab->entry[i]!=NULL)
		{
			if(symtab->entry[i]->category == FUNCTION_t && symtab->entry[i]->isFuncDefine == __FALSE)
			{
					fprintf( stdout, "########## Error at Line#%d: Funcction: '%s' is declared but not defined ##########\n", symtab->entry[i]->declarationLine,symtab->entry[i]->name ); semError = __TRUE;
				
			}
		}
	
	}

}


// major bug(s)......
void deletePType( struct PType *type )
{
	if( type != 0 ) {
	
		if( type->dim == 0 ) {  }
		else if( type->dim->next == 0 )	{ 
			free( type->dim ); 
		}
		else {
			struct ArrayDimNode *current, *previous, *nextt;
		
		}
	}
	
}

void deleteSymAttr( union SymAttr *attr, SEMTYPE category )
//void deleteSymAttr( union SymAttr *attr, SEMTYPE category )
{
	if( attr != 0 ) {

		//if( attr->constVal != 0 ) {
		if( category == CONSTANT_t ) {
			if( attr->constVal->category == STRING_t ) {
				free( attr->constVal->value.stringVal );
			}

			free( attr->constVal );
		}
		else if( category == FUNCTION_t ) {
		//else if( attr->formalParam != 0 ) {
			if( attr->formalParam->params == 0 ) {  }
			else if( attr->formalParam->params->next == 0 ) {
				deletePType( attr->formalParam->params->value );
			}
			else {
				struct PTypeList *current, *previous;
				for( current=(attr->formalParam->params->next), previous=(attr->formalParam->params) ; current!=0 ; current=(current->next), previous=(previous->next) ) {
					deletePType( previous->value );
					free( previous );
				}
				// last object...
				deletePType( previous->value );
				free( previous );
			}
			free( attr->formalParam );
		}
	free( attr );

	}
}

void deleteIdList( struct idNode_sem *idlist )
{
	if( idlist == 0 )	return;
	else if( idlist->next == 0 ) {
		if( idlist->value != 0 )
			free( idlist->value );
		free( idlist );
	}
	else {
		struct idNode_sem *current, *previous;
		for( current=(idlist->next), previous=idlist ; current!=0 ; previous=current, current=(current->next) ) {
			if( previous->value != 0 )
				free( previous->value );
		}
		if( previous->value != 0 )
			free( previous->value );

		free( idlist );
	}
}

