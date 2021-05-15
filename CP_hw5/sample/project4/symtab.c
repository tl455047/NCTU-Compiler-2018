#include "header.h"
#include "symtab.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "semcheck.h"

void initSymTab( struct SymTable *table )
{	int i;
	for( i=0 ; i<HASHBUNCH ; ++i ){
		table->entry[i] = NULL;		
	}
}


void insertTab( struct SymTable *table, struct SymNode *newNode )
{
	int location = 0;

	if( table->entry[location] == 0 ) {	// the first
		table->entry[location] = newNode;
	} 
	else {
		struct SymNode *nodePtr;
		for( nodePtr=table->entry[location] ; (nodePtr->next)!=0 ; nodePtr=nodePtr->next );
		nodePtr->next = newNode;
		newNode->prev = nodePtr;
	}
}

struct SymNode* createVarNode( const char *name, int scope, struct PType *type ) 
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	/* setup name */
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	/* setup scope */
	newNode->scope = scope;
	/* setup type */
	newNode->type = type;
	/* Category: variable */
	newNode->category = VARIABLE_t;
	/* without attribute */
	newNode->attribute = 0;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;
}

struct SymNode* createParamNode( const char *name, int scope, struct PType *type )
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	/* setup name */
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	/* setup scope */
	newNode->scope = scope;
	/* setup type */
	newNode->type = type;
	/* Category: parameter */
	newNode->category = PARAMETER_t;
	/* without attribute */
	newNode->attribute = 0;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;	
}

struct SymNode * createConstNode( const char *name, int scope, struct PType *pType, struct ConstAttr *constAttr )
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	// setup name /
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	//* setup scope /
	newNode->scope = scope;
	//* setup type /
	newNode->type = pType;
	//* Category: constant /
	newNode->category = CONSTANT_t;
	//* setup attribute /
	newNode->attribute = (union SymAttr*)malloc(sizeof(union SymAttr));
	newNode->attribute->constVal = constAttr;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;
}

struct SymNode *createFuncNode( const char *name, int scope, struct PType *pType, struct FuncAttr *params )
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	// setup name /
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	//* setup scope /
	newNode->scope = scope;
	//* setup type /
	newNode->type = pType;
	//* Category: constant /
	newNode->category = FUNCTION_t;
	//* setup attribute /
	newNode->attribute = (union SymAttr*)malloc(sizeof(union SymAttr));
	newNode->attribute->formalParam = params;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;
}

/**
 * __BOOLEAN currentScope: true: only search current scope
 */

struct SymNode *lookupSymbol( struct SymTable *table, const char *id, int scope, __BOOLEAN currentScope )
{
	int index = 0;
	struct SymNode *nodePtr, *result=0;
	nodePtr=table->entry[0];
	for( nodePtr=(table->entry[index]) ; nodePtr!=0 ; nodePtr=(nodePtr->next) ) {
		if( !strcmp(nodePtr->name,id) && ((nodePtr->scope)==scope) ) { 
			return nodePtr;
		}
	}
	// not found...
	if( scope == 0 )	return 0;	// null
	else {
		if( currentScope == __TRUE ) {
			return 0;
		}
		else {
			return lookupSymbol( table, id, scope-1, __FALSE );
		}
	}
}



void deleteSymbol( struct SymNode *symbol )
{
	// delete name
	if( symbol->name != 0 )
		free( symbol->name );
	// delete PType
	deletePType( symbol->type );
	// delete SymAttr, according to category
	deleteSymAttr( symbol->attribute, symbol->category );
	//
	symbol->next = 0;
	symbol->prev = 0;

	free( symbol );
}

void deleteScope( struct SymTable *table, int scope )
{
	int i;

	//struct SymNode *collectList = 0;

	struct SymNode *current, *previous;
	for( i=0 ; i<HASHBUNCH ; ++i ) {
		if( table->entry[i] == 0 ) {	// no element in this list
			continue;
		}
		else if( table->entry[i]->next == 0 ) {	// only one element in this list
			if( table->entry[i]->scope == scope ) {
				//deleteSymbol( table->entry[i] );
				table->entry[i] = 0;
			}
		}
		else {
			for( previous=(table->entry[i]), current=(table->entry[i]->next) ; current!=0 ; previous=current, current=(current->next) ) {
				if( previous->scope == scope ) {
					if( previous->prev == 0 ) {
						previous->next->prev = 0;
						table->entry[i] = current;
						//deleteSymbol( previous );
					}
					else {
						previous->prev->next = current;
						current->prev = previous->prev;
						//deleteSymbol( previous );
					}
				}
			}
			if( previous->scope == scope ) {
				//previous->prev->next = 0;
				if( previous->prev == 0 ) {
					table->entry[0] = 0;
					//deleteSymbol( previous );
				}
				else {
					previous->prev->next = 0;
					//deleteSymbol( previous );

				}
			}

		}
	}
}
/**
 * if flag == 1, invoked at symbol table dump
 */ 
void printType( struct PType *type, int flag )
{
	char buffer[50];
	memset( buffer, 0, sizeof(buffer) );
	struct PType *pType = type;

	switch( pType->type ) {
	 case INTEGER_t:
	 	sprintf(buffer, "int");
		break;
	 case FLOAT_t:
	 	sprintf(buffer, "float");
		break;
	case DOUBLE_t:
	 	sprintf(buffer, "double");
		break;
	 case BOOLEAN_t:
	 	sprintf(buffer, "bool");
		break;
	 case STRING_t:
	 	sprintf(buffer, "string");
		break;
	 case VOID_t:
	 	sprintf(buffer, "void");
		break;
	}

	int i;
	struct ArrayDimNode *ptrr;
	for( i=0, ptrr=pType->dim ; i<(pType->dimNum) ; i++,ptrr=(ptrr->next) ) {
		char buf[15];
		memset( buf, 0, sizeof(buf) );
		sprintf( buf, "[%d]", ptrr->size );
		strcat( buffer, buf  );
	}
	if( flag == 1 )
		printf("%-19s", buffer);
	else
		printf("%s",buffer );
}

void printSymTable( struct SymTable *table, int __scope )
{
	printf("=======================================================================================\n");
	// Name [29 blanks] Kind [7 blanks] Level [7 blank] Type [15 blanks] Attribute [15 blanks]
	printf("Name                             Kind       Level       Type               Attribute               \n");
	printf("---------------------------------------------------------------------------------------\n");
	int i;
	struct SymNode *ptr;
	for( i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if( ptr->scope == __scope ) {
				printf("%-32s ", ptr->name);

				switch( ptr->category ) {
				 case VARIABLE_t:
					printf("variable  ");
					break;
			 	 case CONSTANT_t:
			 		printf("constant  ");
					break;				 
				 case FUNCTION_t:
				 	printf("function  ");
					break;
				 case PARAMETER_t:
				 	printf("parameter ");
					break;
				}

				if( ptr->scope == 0 ) {
					printf("%2d(global)   ", ptr->scope);
				}
				else {
					printf("%2d(local)    ", ptr->scope);
				}

				printType( ptr->type, 1 );
			
				if( ptr->category == FUNCTION_t ) {
					int i;
					struct PTypeList *pTypePtr;
					for( i=0, pTypePtr=(ptr->attribute->formalParam->params) ; i<(ptr->attribute->formalParam->paramNum) ; i++, pTypePtr=(pTypePtr->next) ) {
						printType( pTypePtr->value, 0 );
						if(i < ptr->attribute->formalParam->paramNum-1)
							printf(",");
					}
				}
				else if( ptr->category == CONSTANT_t ) {
					switch( ptr->attribute->constVal->category ) {
					 case INTEGER_t:
						printf("%d",ptr->attribute->constVal->value.integerVal);
						break;
					 case FLOAT_t:
					 	printf("%lf",ptr->attribute->constVal->value.floatVal);
						break;
					case DOUBLE_t:
					 	printf("%lf",ptr->attribute->constVal->value.doubleVal);
						break;
					 case BOOLEAN_t:
					 	if( ptr->attribute->constVal->value.booleanVal == __TRUE ) 
							printf("true");
						else
							printf("false");
						break;
					 case STRING_t:
					 	printf("%s",ptr->attribute->constVal->value.stringVal);
						break;
					}
				}

				printf("\n");
			}	// if( ptr->scope == __scope )
		}	// for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) )
	}	// for( i=0 ; i<HASHBUNCH ; i++ )
	printf("======================================================================================\n");

}

