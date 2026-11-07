%{
#include <string>
#include <memory>
#include "ast.hpp"
#include "parser.tab.hpp"

int yylex();
%}

%option noyywrap
%option yylineno
%option nounistd
%option never-interactive

DIGIT       [0-9]
LETTER      [a-zA-Z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INT_LIT     {DIGIT}+
FLOAT_LIT   {DIGIT}+"."{DIGIT}+

%%

[ \t\r\n]+             ;
"//".*                 ;

"int"                  { return TOKEN_INT; }
"float"                { return TOKEN_FLOAT; }
"if"                   { return TOKEN_IF; }
"else"                 { return TOKEN_ELSE; }
"while"                { return TOKEN_WHILE; }
"return"               { return TOKEN_RETURN; }

{FLOAT_LIT}            { yylval.fval = std::stod(yytext); return TOKEN_NUM_FLOAT; }
{INT_LIT}              { yylval.ival = std::stoi(yytext); return TOKEN_NUM_INT; }
{ID}                   { yylval.sval = new std::string(yytext); return TOKEN_ID; }

"+"                    { return '+'; }
"-"                    { return '-'; }
"*"                    { return '*'; }
"/"                    { return '/'; }
"="                    { return '='; }
"<"                    { return '<'; }
">"                    { return '>'; }
"=="                   { return TOKEN_EQ; }
"!="                   { return TOKEN_NEQ; }
";"                    { return ';'; }
"{"                    { return '{'; }
"}"                    { return '}'; }
"("                    { return '('; }
")"                    { return ')'; }

.                      { std::cerr << "Невідомий символ: " << yytext << std::endl; }

%%