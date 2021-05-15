#ifndef _GERNERATECODE_H_
#define _GERNERATECODE_H_
#include "semcheck.h"
#include "header.h"
#include "symtab.h"
void genArithmetic(struct expr_sem *op1,OPERATOR operator, struct expr_sem *op2);
void genMinus(struct expr_sem *op1);
void genConst(struct expr_sem *op);
void genMod();
void genNot();
void genAnd();
void genOr();
void genAssignment(struct SymTable *table, struct expr_sem *expr1, struct expr_sem *expr2, int __scope);
void genRelate(struct expr_sem *op1, OPERATOR operator, struct expr_sem *op2);
void genOperand(struct expr_sem *op1, int __scope);
void genVariable(struct SymTable *table, struct expr_sem *expr, int __scope);
int searchCount(struct SymTable *table, int __scope, char *name);
void traceExpr(struct expr_sem *expr);
void genPrintforward();
void genPrintafter(struct expr_sem *expr);
void genReadforward();
void genDeclareAssignment(int count,  SEMTYPE type1, SEMTYPE type2, int __scope, char* name);
void genReadafter(struct SymTable *table, struct expr_sem *expr,int __scope);
void genIfstatementforward();
void genIfstatementafter();
void genIfElsestatementmiddle();
void genIfElsestatementafter();
struct if_label{
	int if_false;
	int if_exit;
	struct if_label* next;
	struct if_label* prev;
};
struct while_label{
	int while_begin;
	int while_exit;
	int while_true;
	int while_incr;
	struct while_label* next;
	struct while_label* prev;
};
void createIfLabel();
void addIfExitLabel();
void deleteIfLabel();
void genWhileBegin();
void genWhileMiddle();
void genWhileAfter();
void createWhileLabel();
void addWhileExitLabel();
void deleteWhileLabel();
void genDoWhileBegin();
void genDoWhileAfter();
void deleteWhileLabel();
void genFunctionBegin(SEMTYPE type, char* name, struct param_sem * par);
void genFunctionEnd(SEMTYPE type,char* name);
void genReturn(SEMTYPE type);
void genForBegin();
void addForIncrLabel();
void addForTrueLabel();
void genForMiddleBegin();
void genForMiddle();
void genForIncrBegin();
void genForIncrAfter();
void genForAfter();
void genFuncInvokPar(struct SymTable* table,char* name);
void genFuncInvok(struct SymTable* table,char* name);
struct PType* searchReturnType(struct SymTable* table,char* name);
void genMinusForType(struct PType *type);
void genOperandOp(struct expr_sem *op1, struct expr_sem *op2, int __scope);
void genConstOp(struct expr_sem *op1,struct expr_sem *op2);
void genVariableOp(struct SymTable *table, struct expr_sem *expr1, struct expr_sem *expr2, int __scope);
void removeExpression(struct expr_sem *op1);
void setReturnType(SEMTYPE type);
void genReturnType(struct expr_sem *op1,SEMTYPE type);
struct PTypeList* searchPar(struct SymTable * table,char* name);
void genPar(struct PType *type1, struct PType *type2);
#endif