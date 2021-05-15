#include <stdio.h>
#include "semcheck.h"
#include <stdlib.h>
#include <string.h>
#include "header.h"
#include "symtab.h"
#include "generatecode.h"
extern struct SymTable *symbolTable;
extern int scope;
extern FILE *outfile;
extern char fileName[256];
extern int l_count;
extern int while_begin;
extern int while_exit;
extern struct if_label* if_head;
extern struct if_label* if_tail;
extern struct while_label* while_head;
extern struct while_label* while_tail;
extern int count;
extern int in_main;
extern SEMTYPE return_type;
void genPar(struct PType *type1, struct PType *type2)
{
	switch(type1->type)
	{
		case INTEGER_t:
			break;
		case FLOAT_t:
			if(type2->type == INTEGER_t)
			{
				fprintf(outfile,"i2f\n");
			}
			break;
		case DOUBLE_t:
				if(type2->type == INTEGER_t)
				{
					fprintf(outfile,"i2d\n");
				}
				else
				{
					fprintf(outfile,"f2d\n");
				}
				break;
		case BOOLEAN_t:
			break;
		}
}
struct PTypeList * searchPar(struct SymTable * table,char* name)
{
	int i,f;
	struct SymNode *ptr;
	struct PTypeList* tar;
	for( i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if(ptr->scope == 0 && strcmp(ptr->name,name) == 0) {
				tar = ptr->attribute->formalParam->params;
				return tar;
			}
		}	
	}
}
void genReturnType(struct expr_sem *op1,SEMTYPE type)
{
	if(in_main == 1)
	{
		fprintf(outfile,"return\n");
	}
	else
	{
		switch(op1->pType->type)
		{
			case INTEGER_t:
				if(type == INTEGER_t)
				{
					fprintf(outfile,"ireturn\n");
				}
				else if(type == FLOAT_t)
				{
					fprintf(outfile,"i2f\n");
					fprintf(outfile,"freturn\n");
				}
				else 
				{
					fprintf(outfile,"i2d\n");
					fprintf(outfile,"dreturn\n");
				}
				break;
			case FLOAT_t:
				if(type == FLOAT_t)
				{
					fprintf(outfile,"freturn\n");
				}
				else 
				{
					fprintf(outfile,"f2d\n");
					fprintf(outfile,"dreturn\n");
				}
				break;
			case DOUBLE_t:
				fprintf(outfile,"dreturn\n");
				break;
			case BOOLEAN_t:
				fprintf(outfile,"ireturn\n");
				break;
		}
	}
	
}
void setReturnType(SEMTYPE type)
{
	switch(type)
	{
		case INTEGER_t:
			return_type = INTEGER_t;
			break;
		case FLOAT_t:
			return_type = FLOAT_t;
			break;
		case DOUBLE_t:
			return_type = DOUBLE_t;
			break;
		case BOOLEAN_t:
			return_type = BOOLEAN_t;
			break;
	}
}
void removeExpression(struct expr_sem *op1)
{
	if(op1->load == 1)
	{
		if(op1->pType->type != DOUBLE_t)
		{
			fprintf(outfile,"pop\n");
		}
		else
		{
			fprintf(outfile,"pop2\n");
		}
	}
}
struct PType* searchReturnType(struct SymTable* table,char* name)
{
	struct SymNode *ptr;
	for( int i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if( ptr->scope == 0 && strcmp(name,ptr->name) == 0) {
				return ptr->type;
			}
		}
	}
}
void genFuncInvok(struct SymTable* table,char* name)
{
	fprintf(outfile,"invokestatic %s/%s(",fileName,name);
	struct SymNode *ptr;
	for( int i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if( ptr->scope == 0 && strcmp(name,ptr->name) == 0) {
				switch(ptr->type->type)
				{
					case INTEGER_t:
						fprintf(outfile,")I\n");
						break;
					case FLOAT_t:
						fprintf(outfile,")F\n");
						break;
					case DOUBLE_t:
						fprintf(outfile,")D\n");
						break;
					case BOOLEAN_t:
						fprintf(outfile,")Z\n");
						break;
					case VOID_t:
						fprintf(outfile,")V\n");
						break;
				}
			}
		}
	}
	
}
void genFuncInvokPar(struct SymTable* table,char* name)
{
	fprintf(outfile,"invokestatic %s/%s(",fileName,name);
	struct SymNode *ptr;
	for( int i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if( ptr->scope == 0 && strcmp(name,ptr->name) == 0) {
				struct PTypeList *pt = ptr->attribute->formalParam->params;
				for(int j = 0; j < ptr->attribute->formalParam->paramNum; j++)
				{
					switch(pt->value->type)
					{
						case INTEGER_t:
							fprintf(outfile,"I");
							break;
						case FLOAT_t:
							fprintf(outfile,"F");
							break;
						case DOUBLE_t:
							fprintf(outfile,"D");
							break;
						case BOOLEAN_t:
							fprintf(outfile,"Z");
							break;
					}
					pt = pt->next; 
				}
				switch(ptr->type->type)
				{
					case INTEGER_t:
						fprintf(outfile,")I\n");
						break;
					case FLOAT_t:
						fprintf(outfile,")F\n");
						break;
					case DOUBLE_t:
						fprintf(outfile,")D\n");
						break;
					case BOOLEAN_t:
						fprintf(outfile,")Z\n");
						break;
					case VOID_t:
						fprintf(outfile,")V\n");
						break;
				}
			}
		}
	}
	
}
void genForBegin()
{
	genWhileBegin();
}
void addForIncrLabel()
{
	struct while_label* l = while_tail;
	l->while_incr = l_count;
	l_count++;
}
void addForTrueLabel()
{
	struct while_label* l = while_tail;
	l->while_true = l_count;
	l_count++;
}
void genForMiddleBegin()
{
	addWhileExitLabel();
	fprintf(outfile,"ifeq L%d\n",while_tail->while_exit);
}
void genForMiddle()
{
	fprintf(outfile,"ifeq L%d\n",while_tail->while_exit);
}
void genForIncrBegin()
{
	addForTrueLabel();
	fprintf(outfile,"goto L%d\n",while_tail->while_true);
	addForIncrLabel();
	fprintf(outfile,"L%d:\n",while_tail->while_incr);
}
void genForIncrAfter()
{
	fprintf(outfile,"goto L%d\n",while_tail->while_begin);
	fprintf(outfile,"L%d:\n",while_tail->while_true);
}

void genForAfter()
{
	fprintf(outfile,"goto L%d\n",while_tail->while_incr);
	fprintf(outfile,"L%d:\n",while_tail->while_exit);
	deleteWhileLabel();
}
void genReturn(SEMTYPE type)
{
	switch(type)
	{
		case INTEGER_t:
			fprintf(outfile,"ireturn\n");
			break;
		case FLOAT_t:
			fprintf(outfile,"freturn\n");
			break;
		case DOUBLE_t:
			fprintf(outfile,"dreturn\n");
			break;
		case BOOLEAN_t:
			fprintf(outfile,"ireturn\n");
			break;
		case VOID_t:
			fprintf(outfile,"return\n");
			break;
	}
}
void genFunctionEnd(SEMTYPE type,char* name)
{
	if(type == VOID_t || strcmp(name,"main") == 0)
	{
		fprintf(outfile,"return\n");
	}
	fprintf(outfile,".end method\n");
}
void genFunctionBegin(SEMTYPE type, char* name, struct param_sem * par)
{
	int lstack = 100,llocals = 100;
	if(strcmp(name,"main") == 0)
	{
		fprintf(outfile,".method public static main([Ljava/lang/String;)V\n");
	}
	else
	{
		struct param_sem * ptr = par;
		fprintf(outfile,".method public static %s(",name);
		for(  ; ptr!=0 ; ptr=(ptr->next) ) {
			switch(ptr->pType->type)
			{
				case INTEGER_t:
					fprintf(outfile,"I");
					break;
				case FLOAT_t:
					fprintf(outfile,"F");
					break;
				case DOUBLE_t:
					fprintf(outfile,"D");
					break;
				case BOOLEAN_t:
					fprintf(outfile,"Z");
					break;
			}
		}
		switch(type)
		{
			case INTEGER_t:
				fprintf(outfile,")I\n");
				break;
			case FLOAT_t:
				fprintf(outfile,")F\n");
				break;
			case DOUBLE_t:
				fprintf(outfile,")D\n");
				break;
			case BOOLEAN_t:
				fprintf(outfile,")Z\n");
				break;
			case VOID_t:
				fprintf(outfile,")V\n");
				break;
		}
	}
	fprintf(outfile,".limit stack %d\n",lstack);
	fprintf(outfile,".limit locals %d\n",llocals);
}
void genDoWhileBegin()
{
	genWhileBegin();
}
void genDoWhileAfter()
{
	genWhileMiddle();
	genWhileAfter();
}
void deleteWhileLabel()
{
	/*struct if_label* l1 = if_tail;
	while(l1 != NULL)
	{
		printf("falsel: %d exitl: %d\n",l1->if_false,l1->if_exit);
		l1 = l1->prev;
	}*/
	struct while_label* l = while_tail;
	if(while_tail->prev == NULL)
	{
		while_tail = NULL;
		while_head = NULL;
	}
	else
	{
		while_tail = while_tail->prev;
	}
	free (l);
	//if_top--;
}
void addWhileExitLabel()
{
	struct while_label* l = while_tail;
	l->while_exit = l_count;
	l_count++;
}
void createWhileLabel()
{
	struct while_label* l = (struct while_label*)malloc(sizeof(struct while_label));
	l->while_begin = l_count;
	l_count++;
	l->while_exit = -1;
	l->next = NULL;
	l->prev = NULL;
	if(while_head == NULL)
	{
		while_head = l;
		while_tail = l;
	}
	else
	{
		while_tail->next = l;
		l->prev = while_tail;
		while_tail = l;
	}	
	//ifl[if_top] = l;
	//if_top++;
} 
void createIfLabel()
{
	struct if_label* l = (struct if_label*)malloc(sizeof(struct if_label));
	l->if_false = l_count;
	l_count++;
	l->if_exit = -1;
	l->next = NULL;
	l->prev = NULL;
	if(if_head == NULL)
	{
		if_head = l;
		if_tail = l;
	}
	else
	{
		if_tail->next = l;
		l->prev = if_tail;
		if_tail = l;
	}	
	//ifl[if_top] = l;
	//if_top++;
}
void addIfExitLabel()
{
	struct if_label* l = if_tail;
	l->if_exit = l_count;
	l_count++;
}
void deleteIfLabel()
{
	/*struct if_label* l1 = if_tail;
	while(l1 != NULL)
	{
		printf("falsel: %d exitl: %d\n",l1->if_false,l1->if_exit);
		l1 = l1->prev;
	}*/
	struct if_label* l = if_tail;
	if(if_tail->prev == NULL)
	{
		if_tail = NULL;
		if_head = NULL;
	}
	else
	{
		if_tail = if_tail->prev;
	}
	free (l);
	//if_top--;
}
void genWhileBegin()
{
	createWhileLabel();
	fprintf(outfile,"L%d:\n",while_tail->while_begin);
}
void genWhileMiddle()
{
	addWhileExitLabel();
	fprintf(outfile,"ifeq L%d\n",while_tail->while_exit);
}
void genWhileAfter()
{
	fprintf(outfile,"goto L%d\n",while_tail->while_begin);
	fprintf(outfile,"L%d:\n",while_tail->while_exit);
	deleteWhileLabel();
}
void genIfstatementforward()
{
	createIfLabel();
	fprintf(outfile,"ifeq L%d\n",if_tail->if_false);
}
void genIfstatementafter()
{
	fprintf(outfile,"L%d:\n",if_tail->if_false);
	deleteIfLabel();
}
void genIfElsestatementmiddle()
{
	addIfExitLabel();
	fprintf(outfile,"goto L%d\n",if_tail->if_exit);
	fprintf(outfile,"L%d:\n",if_tail->if_false);
}
void genIfElsestatementafter()
{
	fprintf(outfile,"L%d:\n",if_tail->if_exit);
	deleteIfLabel();
}

void genReadafter(struct SymTable *table, struct expr_sem *expr,int __scope)
{
	fprintf(outfile,"getstatic %s/_sc Ljava/util/Scanner;\n",fileName);
	fprintf(outfile,"invokevirtual java/util/Scanner/next");
	struct SymNode *ptr;
	int count1;
	for( int i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if(strcmp(ptr->name,expr->varRef->id) == 0) {
				count1 = ptr->count;
			}
		}	
	}
	switch(expr->pType->type)
	{
		case INTEGER_t:
			fprintf(outfile,"Int()I\n");
			fprintf(outfile,"istore %d\n",count1);
			break;
		case FLOAT_t:
			fprintf(outfile,"Float()F\n");
			fprintf(outfile,"fstore %d\n",count1);
			break;
		case DOUBLE_t:
			fprintf(outfile,"Double()D\n");
			fprintf(outfile,"dstore %d\n",count1);
			break;
		case BOOLEAN_t:
			fprintf(outfile,"Boolean()Z\n");
			fprintf(outfile,"istore %d\n",count1);
			break;
	}

}
void genDeclareAssignment(int count,  SEMTYPE type1, SEMTYPE type2, int __scope, char* name)
{
	switch(type1)
	{
		case INTEGER_t:
			fprintf(outfile,"istore %d\n",count);
			break;
		case FLOAT_t:
			if(type2 == INTEGER_t)
				fprintf(outfile,"i2f\n");
			fprintf(outfile,"fstore %d\n",count);
			break;
		case DOUBLE_t:
			if(type2 == INTEGER_t)
				fprintf(outfile,"i2d\n");
			else if(type2 == FLOAT_t)
				fprintf(outfile,"f2d\n");
			fprintf(outfile,"dstore %d\n",count);
			break;
		case BOOLEAN_t:
			fprintf(outfile,"istore %d\n",count);
			break;
	}
}
void genReadforward()
{
	fprintf(outfile,"new java/util/Scanner\n");
	fprintf(outfile,"dup\n");
	fprintf(outfile,"getstatic java/lang/System/in Ljava/io/InputStream;\n");
	fprintf(outfile,"invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
	fprintf(outfile,"putstatic %s/_sc Ljava/util/Scanner;\n",fileName);
}
void genPrintforward()
{
	fprintf(outfile,"getstatic java/lang/System/out Ljava/io/PrintStream;\n");
}
void genPrintafter(struct expr_sem *expr)
{
	if(expr->pType->type == STRING_t)
	{
		fprintf(outfile,"invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
	}
	else
	{
		switch(expr->pType->type)
			{
				case INTEGER_t:
					fprintf(outfile,"invokevirtual java/io/PrintStream/print(I)V\n");
					break;
				case FLOAT_t:
					fprintf(outfile,"invokevirtual java/io/PrintStream/print(F)V\n");
					break;
				case DOUBLE_t:
					fprintf(outfile,"invokevirtual java/io/PrintStream/print(D)V\n");
					break;
				case BOOLEAN_t:
					fprintf(outfile,"invokevirtual java/io/PrintStream/print(Z)V\n");
					break;
			}
		
	}
}
void genAssignment(struct SymTable *table, struct expr_sem *expr1, struct expr_sem *expr2, int __scope)
{
	int i,f;
	struct SymNode *ptr,*tar;
	for( i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if(strcmp(ptr->name,expr1->varRef->id) == 0) {
				tar = ptr;
			}
		}	
	}
	ptr = tar;

	if(ptr->category == VARIABLE_t || ptr->category == PARAMETER_t)
	{
		if(ptr->count >= 0)
		{
			switch(expr1->pType->type)
			{
				case INTEGER_t:
					fprintf(outfile,"istore %d\n",ptr->count);
					break;
				case FLOAT_t:
					if(expr2->pType->type == INTEGER_t)
						fprintf(outfile,"i2f\n");
					fprintf(outfile,"fstore %d\n",ptr->count);
					break;
				case DOUBLE_t:
					if(expr2->pType->type == INTEGER_t)
						fprintf(outfile,"i2d\n");
					else if(expr2->pType->type == FLOAT_t)
						fprintf(outfile,"f2d\n");
					fprintf(outfile,"dstore %d\n",ptr->count);
					break;
				case BOOLEAN_t:
					fprintf(outfile,"istore %d\n",ptr->count);
					break;
			}
		}
		else
		{
			
			switch(expr1->pType->type)
			{
				case INTEGER_t:
					fprintf(outfile,"putstatic %s/%s I\n",fileName,expr1->varRef->id);
					break;
				case FLOAT_t:
					if(expr2->pType->type == INTEGER_t)
						fprintf(outfile,"i2f\n");
					fprintf(outfile,"putstatic %s/%s F\n",fileName,expr1->varRef->id);
					break;
				case DOUBLE_t:
					if(expr2->pType->type == INTEGER_t)
						fprintf(outfile,"i2d\n");
					else if(expr2->pType->type == FLOAT_t)
						fprintf(outfile,"f2d\n");
					fprintf(outfile,"putstatic %s/%s D\n",fileName,expr1->varRef->id);
					break;
				case BOOLEAN_t:
					fprintf(outfile,"putstatic %s/%s Z\n",fileName,expr1->varRef->id);
					break;
			}
		}
		return;
	}
}
void genOr()
{
	fprintf(outfile,"ior\n");
}
void genAnd()
{
	fprintf(outfile,"iand\n");
}
void genNot()
{
	fprintf(outfile,"iconst_1\n");
	fprintf(outfile,"ixor\n");
}
void genRelate(struct expr_sem *op1, OPERATOR operator, struct expr_sem *op2)
{
	/*if( ((op1->pType->type==INTEGER_t || op1->pType->type==FLOAT_t || op1->pType->type==DOUBLE_t) && \
			(op2->pType->type==INTEGER_t || op2->pType->type==FLOAT_t || op2->pType->type==DOUBLE_t)) ) {
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
	}*/
	int l1 = l_count;
	switch(operator)
	{
		case LT_t:
			if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"isub\n");
				
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dcmpl\n");
			}
			else 
			{
				fprintf(outfile,"fcmpl\n");
			}
			fprintf(outfile,"iflt L%d\n",l1);
			break;
		case LE_t:
			if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"isub\n");
				
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dcmpl\n");
			}
			else 
			{
				fprintf(outfile,"fcmpl\n");
			}
			fprintf(outfile,"ifle L%d\n",l1);
			break;
		case EQ_t:
			if( (op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t) || (op1->pType->type == BOOLEAN_t && op2->pType->type == BOOLEAN_t) )
			{
				fprintf(outfile,"isub\n");
				
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dcmpl\n");
			}
			else 
			{
				fprintf(outfile,"fcmpl\n");
			}
			fprintf(outfile,"ifeq L%d\n",l1);
			break;
		case GE_t:
			if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"isub\n");
				
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dcmpl\n");
			}
			else 
			{
				fprintf(outfile,"fcmpl\n");
			}
			fprintf(outfile,"ifge L%d\n",l1);
			break;
		case GT_t:
			if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"isub\n");
				
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dcmpl\n");
			}
			else
			{
				fprintf(outfile,"fcmpl\n");
			}
			fprintf(outfile,"ifgt L%d\n",l1);
			break;
		case NE_t:
			if((op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t) || (op1->pType->type == BOOLEAN_t && op2->pType->type == BOOLEAN_t))
			{
				fprintf(outfile,"isub\n");
				
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dcmpl\n");
			}
			else 
			{
				fprintf(outfile,"fcmpl\n");
			}
			fprintf(outfile,"ifne L%d\n",l1);
			break; 
	}
	l_count++;
	fprintf(outfile,"iconst_0\n");
	int l2 = l_count;
	fprintf(outfile,"goto L%d\n",l2);
	l_count++;
	fprintf(outfile,"L%d:\n",l1);
	fprintf(outfile,"iconst_1\n");
	fprintf(outfile,"L%d:\n",l2);
}
void genMod()
{
	fprintf(outfile,"irem\n");
}
void genMinusForType(struct PType *type)
{
	switch(type->type)
	{
		case INTEGER_t:
			fprintf(outfile,"ineg\n");
			break;
		case FLOAT_t:
			fprintf(outfile,"fneg\n");
			break;
		case DOUBLE_t:
			fprintf(outfile,"dneg\n");
			break;
	}
}
void genMinus(struct expr_sem *op1)
{
	switch(op1->pType->type)
	{
		case INTEGER_t:
			fprintf(outfile,"ineg\n");
			break;
		case FLOAT_t:
			fprintf(outfile,"fneg\n");
			break;
		case DOUBLE_t:
			fprintf(outfile,"dneg\n");
			break;
	}
}
void genOperandOp(struct expr_sem *op1, struct expr_sem *op2, int __scope)
{	
	if(op2->varRef != NULL && op2->load == 0)
	{
		genVariableOp(symbolTable,op1,op2,__scope);
		op2->load = 1;
	}
	else if( op2->load == 0)
	{
		genConstOp(op1,op2);
		op2->load = 1;
	}
	else if(op2->load == 1)
	{
		switch(op2->pType->type)
		{
			case INTEGER_t:
				fprintf(outfile,"istore %d\n",count);
				break;
			case FLOAT_t:
				fprintf(outfile,"fstore %d\n",count);
				break;
			case DOUBLE_t:
				fprintf(outfile,"dstore %d\n",count);
				break;
			case BOOLEAN_t:
				fprintf(outfile,"istore %d\n",count);
				break;
		}
		switch(op1->pType->type)
		{
			case INTEGER_t:
				if(op2->pType->type == INTEGER_t)
				{
					fprintf(outfile,"iload %d\n",count);
				}
				else if(op2->pType->type == FLOAT_t)
				{
					fprintf(outfile,"i2f\n");
					fprintf(outfile,"fload %d\n",count);
				}
				else 
				{
					fprintf(outfile,"i2d\n");
					fprintf(outfile,"dload %d\n",count);
				}
				break;
			case FLOAT_t:
				if(op2->pType->type == INTEGER_t)
				{
						fprintf(outfile,"iload %d\n",count);
						fprintf(outfile,"i2f\n");
				}
				else if(op2->pType->type == FLOAT_t)
				{
					fprintf(outfile,"fload %d\n",count);
				}
				else 
				{
					fprintf(outfile,"f2d\n");
					fprintf(outfile,"dload %d\n",count);
				}
				break;
			case DOUBLE_t:
				if(op2->pType->type == INTEGER_t)
				{
					fprintf(outfile,"iload %d\n",count);
					fprintf(outfile,"i2d\n");
				}
				else if(op2->pType->type == FLOAT_t)
				{
					fprintf(outfile,"fload %d\n",count);
					fprintf(outfile,"f2d\n");
				}
				else 
				{
					fprintf(outfile,"dload %d\n",count);
				}
				break;
			case BOOLEAN_t:
				fprintf(outfile,"iload %d\n",count);
				break;
			}
	}
}
void genVariableOp(struct SymTable *table, struct expr_sem *expr1, struct expr_sem *expr2, int __scope)
{
	int i,f;
	struct SymNode *ptr,*tar;
	for( i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if(strcmp(ptr->name,expr2->varRef->id) == 0) {
				tar = ptr;
			}
		}	
	}
	ptr = tar;

	if(ptr->category == VARIABLE_t || ptr->category == PARAMETER_t)
	{
		if(ptr->count >= 0)
		{
			switch(expr1->pType->type)
			{
				case INTEGER_t:
					if(expr2->pType->type == INTEGER_t)
					{
						fprintf(outfile,"iload %d\n",ptr->count);
					}
					else if(expr2->pType->type == FLOAT_t)
					{
						fprintf(outfile,"i2f\n");
						fprintf(outfile,"fload %d\n",ptr->count);
					}
					else 
					{
						fprintf(outfile,"i2d\n");
						fprintf(outfile,"dload %d\n",ptr->count);
					}
					break;
				case FLOAT_t:
					if(expr2->pType->type == INTEGER_t)
					{
						fprintf(outfile,"iload %d\n",ptr->count);
						fprintf(outfile,"i2f\n");
					}
					else if(expr2->pType->type == FLOAT_t)
					{
						fprintf(outfile,"fload %d\n",ptr->count);
					}
					else 
					{
						fprintf(outfile,"f2d\n");
						fprintf(outfile,"dload %d\n",ptr->count);
					}
					break;
				case DOUBLE_t:
					if(expr2->pType->type == INTEGER_t)
					{
						fprintf(outfile,"iload %d\n",ptr->count);
						fprintf(outfile,"i2d\n");
					}
					else if(expr2->pType->type == FLOAT_t)
					{
						fprintf(outfile,"fload %d\n",ptr->count);
						fprintf(outfile,"f2d\n");
					}
					else 
					{
						fprintf(outfile,"dload %d\n",ptr->count);
					}
					break;
				case BOOLEAN_t:
					fprintf(outfile,"iload %d\n",ptr->count);
					break;
			}
		}
		else
		{
			
			switch(expr1->pType->type)
			{
				case INTEGER_t:
					if(expr2->pType->type == INTEGER_t)
					{
						fprintf(outfile,"getstatic %s/%s I\n",fileName,expr2->varRef->id);
					}
					else if(expr2->pType->type == FLOAT_t)
					{
						fprintf(outfile,"i2f\n");
						fprintf(outfile,"getstatic %s/%s F\n",fileName,expr2->varRef->id);
					}
					else 
					{
						fprintf(outfile,"i2d\n");
						fprintf(outfile,"getstatic %s/%s D\n",fileName,expr2->varRef->id);
					}
					
					break;
				case FLOAT_t:
					if(expr2->pType->type == INTEGER_t)
					{
						fprintf(outfile,"getstatic %s/%s I\n",fileName,expr2->varRef->id);
						fprintf(outfile,"i2f\n");
					}
					else if(expr2->pType->type == FLOAT_t)
					{
						fprintf(outfile,"getstatic %s/%s F\n",fileName,expr2->varRef->id);
					}
					else 
					{
						fprintf(outfile,"f2d\n");
						fprintf(outfile,"getstatic %s/%s D\n",fileName,expr2->varRef->id);
					}
					break;
				case DOUBLE_t:
					if(expr2->pType->type == INTEGER_t)
					{
						fprintf(outfile,"getstatic %s/%s I\n",fileName,expr2->varRef->id);
						fprintf(outfile,"i2d\n");
					}
					else if(expr2->pType->type == FLOAT_t)
					{
						fprintf(outfile,"getstatic %s/%s F\n",fileName,expr2->varRef->id);
						fprintf(outfile,"f2d\n");
					}
					else 
					{
						fprintf(outfile,"getstatic %s/%s D\n",fileName,expr2->varRef->id);
					}
					break;
				case BOOLEAN_t:
					fprintf(outfile,"getstatic %s/%s Z\n",fileName,expr2->varRef->id);
					break;
			}
		}
		return;
	}
	else if(ptr->category == CONSTANT_t)
	{
		switch(expr1->pType->type)
		{
			case INTEGER_t:
				if(ptr->type->type == INTEGER_t)
				{
					fprintf(outfile,"ldc %d\n",ptr->attribute->constVal->value.integerVal);
				}
				else if(ptr->type->type == FLOAT_t)
				{
					fprintf(outfile,"i2f\n");
					fprintf(outfile,"ldc %f\n",ptr->attribute->constVal->value.floatVal);
				}
				else
				{
					fprintf(outfile,"i2d\n");
					fprintf(outfile,"ldc2_w %lf\n",ptr->attribute->constVal->value.doubleVal);	
				}
				break;
			case FLOAT_t:
				if(ptr->type->type == INTEGER_t)
				{
					fprintf(outfile,"ldc %d\n",ptr->attribute->constVal->value.integerVal);
					fprintf(outfile,"i2f\n");
				}
				else if(ptr->type->type == FLOAT_t)
				{
					fprintf(outfile,"ldc %f\n",ptr->attribute->constVal->value.floatVal);
				}
				else
				{
					fprintf(outfile,"f2d\n");
					fprintf(outfile,"ldc2_w %lf\n",ptr->attribute->constVal->value.doubleVal);	
				}
				break;
			case DOUBLE_t:
				if(ptr->type->type == INTEGER_t)
				{
					fprintf(outfile,"ldc %d\n",ptr->attribute->constVal->value.integerVal);
					fprintf(outfile,"i2d\n");
				}
				else if(ptr->type->type == FLOAT_t)
				{
					fprintf(outfile,"ldc %f\n",ptr->attribute->constVal->value.floatVal);
					fprintf(outfile,"f2d\n");
				}
				else
				{
					fprintf(outfile,"ldc2_w %lf\n",ptr->attribute->constVal->value.doubleVal);	
				}
				break;
			case BOOLEAN_t:
				f = ptr->attribute->constVal->value.booleanVal;
				if(f == 1)
					fprintf(outfile,"iconst_1\n");
				else
					fprintf(outfile,"iconst_0\n");
				break;
			case STRING_t:
				fprintf(outfile,"ldc \"%s\"\n",ptr->attribute->constVal->value.stringVal);
				break;
		}
		return;
	}	
}
void genConstOp(struct expr_sem *op1, struct expr_sem *op2)
{
	int f;
	int i;
	float f1;
	double d1;
	switch(op1->pType->type)
	{
		case INTEGER_t:
			if(op2->pType->type == FLOAT_t)
			{
				fprintf(outfile,"i2f\n");
				fprintf(outfile,"ldc %f\n",op2->attr->value.floatVal);
			}
			else if(op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"i2d\n");
				fprintf(outfile,"ldc2_w %lf\n",op2->attr->value.doubleVal);
			}
			else
			{
				fprintf(outfile,"ldc %d\n",op2->attr->value.integerVal);
			}
			break;
		case FLOAT_t:
			if(op2->pType->type == INTEGER_t)
			{
				f1 = (float)op2->attr->value.integerVal;
				fprintf(outfile,"ldc %f\n",f1);
			}
			else if(op2->pType->type == FLOAT_t)
			{
				fprintf(outfile,"ldc %f\n",op2->attr->value.floatVal);
			}
			else
			{
				fprintf(outfile,"f2d\n");
				fprintf(outfile,"ldc2_w %lf\n",op2->attr->value.doubleVal);
			}
			break;
		case DOUBLE_t:
			if(op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"ldc2_w %lf\n",op2->attr->value.doubleVal);
			}
			else if(op2->pType->type == FLOAT_t)
			{
				d1 = (double)op2->attr->value.floatVal;
				fprintf(outfile,"ldc2_w %lf\n",d1);
			}
			else
			{
				d1 = (double)op2->attr->value.integerVal;
				fprintf(outfile,"ldc2_w %lf\n",d1);
			}
			break;
		case BOOLEAN_t:
			f = op2->attr->value.booleanVal;
			if(f == 1)
				fprintf(outfile,"iconst_1\n");
			else
				fprintf(outfile,"iconst_0\n");
			break;
	}
}
void genOperand(struct expr_sem *op1, int __scope)
{
	if(op1->varRef != NULL && op1->load == 0)
	{
		genVariable(symbolTable,op1,__scope);
		op1->load = 1;
	}
	else if( op1->load == 0)
	{
		genConst(op1);
		op1->load = 1;
	}
}
void genArithmetic(struct expr_sem *op1,OPERATOR operator, struct expr_sem *op2)
{
	switch(operator)
	{
		case ADD_t:
			if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"iadd\n");
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dadd\n");
			}
			else
			{
				fprintf(outfile,"fadd\n");
			}
		break;
		case SUB_t:
			if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"isub\n");
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dsub\n");
			}
			else
			{
				fprintf(outfile,"fsub\n");
			}
		break;
		case MUL_t:
				if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"imul\n");
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"dmul\n");
			}
			else
			{
				fprintf(outfile,"fmul\n");
			}
		break;
		case DIV_t:
				if(op1->pType->type == INTEGER_t && op2->pType->type == INTEGER_t)
			{
				fprintf(outfile,"idiv\n");
			}
			else if(op1->pType->type == DOUBLE_t || op2->pType->type == DOUBLE_t)
			{
				fprintf(outfile,"ddiv\n");
			}
			else
			{
				fprintf(outfile,"fdiv\n");
			}
		break;
	}
}
void genConst(struct expr_sem *op)
{
	int f;
	switch(op->pType->type)
	{
		case INTEGER_t:
			fprintf(outfile,"ldc %d\n",op->attr->value.integerVal);
			break;
		case FLOAT_t:
			fprintf(outfile,"ldc %f\n",op->attr->value.floatVal);
			break;
		case DOUBLE_t:
			fprintf(outfile,"ldc2_w %lf\n",op->attr->value.doubleVal);
			break;
		case STRING_t:
			fprintf(outfile,"ldc \"%s\"\n",op->attr->value.stringVal);
			break;
		case BOOLEAN_t:
			f = op->attr->value.booleanVal;
			if(f == 1)
				fprintf(outfile,"iconst_1\n");
			else
				fprintf(outfile,"iconst_0\n");
			break;
	}
}
void genVariable(struct SymTable *table, struct expr_sem *expr, int __scope)
{
	int i,f;
	struct SymNode *ptr,*tar;
	for( i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if(strcmp(ptr->name,expr->varRef->id) == 0) {
				tar = ptr;
			}
		}	
	}
	ptr = tar;

	if(ptr->category == VARIABLE_t || ptr->category == PARAMETER_t)
	{
		if(ptr->count >= 0)
		{
			switch(expr->pType->type)
			{
				case INTEGER_t:
					fprintf(outfile,"iload %d\n",ptr->count);
					break;
				case FLOAT_t:
					fprintf(outfile,"fload %d\n",ptr->count);
					break;
				case DOUBLE_t:
					fprintf(outfile,"dload %d\n",ptr->count);
					break;
				case BOOLEAN_t:
					fprintf(outfile,"iload %d\n",ptr->count);
					break;
			}
		}
		else
		{
			fprintf(outfile,"getstatic %s/%s ",fileName,expr->varRef->id);
			switch(ptr->type->type)
			{
				case INTEGER_t:
					fprintf(outfile,"I\n");
					break;
				case FLOAT_t:
					fprintf(outfile,"F\n");
					break;
				case DOUBLE_t:
					fprintf(outfile,"D\n");
					break;
				case BOOLEAN_t:
					fprintf(outfile,"Z\n");
					break;
			}
		}
		return;
	}
	else if(ptr->category == CONSTANT_t)
	{
		switch(ptr->type->type)
		{
			case INTEGER_t:
				fprintf(outfile,"ldc ");
				break;
			case FLOAT_t:
				fprintf(outfile,"ldc ");
				break;
			case DOUBLE_t:
				fprintf(outfile,"ldc2_w ");
				break;
			case BOOLEAN_t:
				f = ptr->attribute->constVal->value.booleanVal;
				if(f == 1)
					fprintf(outfile,"iconst_1\n");
				else
					fprintf(outfile,"iconst_0\n");
				break;
			case STRING_t:
				fprintf(outfile,"ldc ");
				break;
		}
		switch(ptr->attribute->constVal->category)
		{
			case INTEGER_t:
				fprintf(outfile,"%d\n",ptr->attribute->constVal->value.integerVal);
				break;
			case FLOAT_t:
				fprintf(outfile,"%f\n",ptr->attribute->constVal->value.floatVal);
				break;
			case DOUBLE_t:
				fprintf(outfile,"%lf\n",ptr->attribute->constVal->value.doubleVal);
				break;
			case STRING_t:
				fprintf(outfile,"\"%s\"\n",ptr->attribute->constVal->value.stringVal);
				break;
		}
		return;
	}	
}
int searchCount(struct SymTable *table, int __scope, char *name)
{
	int i;
	struct SymNode *ptr;
	for( i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if( ptr->scope == __scope && strcmp(ptr->name,name) == 0) {
				return ptr->count;
			}	// if( ptr->scope == __scope )
		}	// for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) )
	}	// for( i=0 ; i<HASHBUNCH ; i++ )
}
void traceExpr(struct expr_sem *expr)
{
	struct expr_sem *expr1 = expr;
	while(expr1 != NULL)
	{
		if(expr1->varRef != NULL)
		{
			printf("varref: %s ",expr1->varRef->id);
		}
		if(expr1->isDeref == 1)
			printf(" def: 1 ");
		else
			printf(" def: 0 ");
		if(expr1->pType != NULL)
		{
					switch(expr1->pType->type)
					{
						case INTEGER_t:
							printf("type: int\n");
							
							break;
						case FLOAT_t:
								printf("type: float\n");
							break;
						case DOUBLE_t:
								printf("type: double\n");
							break;
						case STRING_t:
								printf("type: string\n");
							break;
						case BOOLEAN_t:
								printf("type: bool\n");
							break;
					}
		
		}

		expr1 = expr1->next;
	}
	printf("\n");
}