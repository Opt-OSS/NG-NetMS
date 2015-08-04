/*
 * NGNMS Demo
 *
 * Event collector rules file parser.
 *
 * (C) M.Golov 2003
 *
 */

%{
#define Operator void
#define Value void

#include <stdio.h>

typedef union { 
    char* str; 
    Operator* op;
    Value* val;
} myYYSTYPE;

#define YYSTYPE myYYSTYPE
#define YYDEBUG 1

int storeCondition(const Operator* cond);
int storeSeverity(const char* sev);
int storeProtocol(const char* proto);
int storeAction(const char* action);
int storeDiscard(void);
int storeEvent(const char* event);

Operator* makeAndOp(Operator* a, Operator* b);
Operator* makeOrOp(Operator* a, Operator* b);
Operator* makeNotOp(Operator* a);

Operator* makeMatchOp(Value* a, Value* b);

Value* makeVar(const char* name);
Value* makeStr(const char* str);

extern int yylex ();

void yyerror(const char* s)
{
    printf("%s\n", s);
}

%}

%token EVENT
%token CONDITION
%token PROTOCOL
%token SYSLOG
%token SNMP
%token SEVERITY
%token ACTION
%token DISCARD

%token NUM
%token IDENTIFIER
%token STRING
%token VARIABLE

%token AND
%token OR
%token NOT

%token MATCH

%%

input:    /* empty */
        | input event 
;

event:    EVENT IDENTIFIER '{' ev_descr '}' { storeEvent($2.str); }
;

ev_descr: ev_descr_item
        | ev_descr ev_descr_item
;

ev_descr_item: condition
        | protocol
        | severity
        | action
        | discard
;

condition: CONDITION bool ';' { storeCondition($2.op); }
;

protocol: PROTOCOL SYSLOG ';' { storeProtocol($2.str); }
        | PROTOCOL SNMP   ';' { storeProtocol($2.str); }
;

action: ACTION STRING ';' { storeAction($2.str); }
;

severity: SEVERITY NUM ';'  { storeSeverity($2.str); }
;

discard: DISCARD ';'  { storeDiscard(); }
;

bool: '(' bool ')'        { $$.op = $2.op; }
        | bool AND bool   { $$.op = makeAndOp( $1.op, $3.op ); }
        | bool OR bool    { $$.op = makeOrOp( $1.op, $3.op ); }
        | NOT bool        { $$.op = makeNotOp( $2.op ); }
        | match
;

match:    prim MATCH prim { $$.op = makeMatchOp($1.val, $3.val); }
;

prim: VARIABLE { $$.val = makeVar($1.str); }
    | STRING   { $$.val = makeStr($1.str); }
;

%%

