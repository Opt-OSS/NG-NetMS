/*
 * NGNMS Demo
 *
 * Event collector rules file lexical analyzer.
 *
 * (C) M.Golov 2003
 *
 */

  /* definitions */

%{
#define YYSTYPE char*
#include <strings.h>
#include "RulesYacc.tab.h"
extern YYSTYPE yylval;
%}

L           [a-zA-Z_]
D           [0-9]

%%

  /* rules */
"event"     { return EVENT; }
"condition" { return CONDITION; }
"protocol"  { return PROTOCOL; }
"syslog"    { yylval = strdup(yytext); return SYSLOG; }
"snmp"      { yylval = strdup(yytext); return SNMP; }
"netflow"   { yylval = strdup(yytext); return NETFLOW; }
"apache"    { yylval = strdup(yytext); return APACHE; }
"custom1"   { yylval = strdup(yytext); return CUSTOM1; }
"custom2"   { yylval = strdup(yytext); return CUSTOM2; }
"can_bus"   { yylval = strdup(yytext); return CAN_BUS; }
"severity"  { return SEVERITY; }
"action"    { return ACTION; }
"discard"   { return DISCARD; }

"#"([^\n])*\n      { /* ignore comment */ }
{L}({L}|{D})*      { yylval = strdup(yytext); return IDENTIFIER; }
{D}+               { yylval = strdup(yytext); return NUM; }
\"(\\.|[^\\"])*\"  { yylval = strdup(yytext+1); 
                     yylval[strlen(yylval)-1]='\0'; return STRING; }
"$"({L}|{D})*      { yylval = strdup(yytext); return VARIABLE; }

"&&"        { return AND; }
"||"        { return OR;  }
"!"         { return NOT; }

"~="        { return MATCH; }

";"         { return ';'; }
"{"         { return '{'; }
"}"         { return '}'; }
"("         { return '('; }
")"         { return ')'; }

[ \t\n\v\f] { }
.           { /* ignore everything else */ }

%%

  /* user code */
