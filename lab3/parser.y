%{
#include <iostream>
#include <memory>
#include <string>
#include "ast.hpp"

extern int yylex();
extern int yylineno;
void yyerror(const char* s);

std::unique_ptr<BlockNode> root_node;
%}

%code requires {
    #include "ast.hpp"
}

%union {
    int ival;
    double fval;
    std::string* sval;
    ASTNode* node;
    BlockNode* block;
}

%token <ival> TOKEN_NUM_INT
%token <fval> TOKEN_NUM_FLOAT
%token <sval> TOKEN_ID
%token TOKEN_INT TOKEN_FLOAT TOKEN_IF TOKEN_ELSE TOKEN_WHILE TOKEN_RETURN
%token TOKEN_EQ TOKEN_NEQ

%type <node> program statement expr primary_expr var_decl
%type <block> statement_list block

%right '='
%left TOKEN_EQ TOKEN_NEQ
%left '<' '>'
%left '+' '-'
%left '*' '/'
%nonassoc LOWER_THAN_ELSE
%nonassoc TOKEN_ELSE

%%

program
    : statement_list {
        root_node = std::unique_ptr<BlockNode>($1);
    }
    ;

statement_list
    : statement_list statement {
        $1->add(std::unique_ptr<ASTNode>($2));
        $$ = $1;
    }
    | {
        $$ = new BlockNode();
    }
    ;

statement
    : expr ';' { $$ = $1; }
    | var_decl ';' { $$ = $1; }
    | block { $$ = $1; }
    | TOKEN_IF '(' expr ')' statement %prec LOWER_THAN_ELSE {
        $$ = new IfNode(std::unique_ptr<ASTNode>($3), std::unique_ptr<ASTNode>($5));
    }
    | TOKEN_IF '(' expr ')' statement TOKEN_ELSE statement {
        $$ = new IfNode(std::unique_ptr<ASTNode>($3), std::unique_ptr<ASTNode>($5), std::unique_ptr<ASTNode>($7));
    }
    ;

block
    : '{' statement_list '}' { $$ = $2; }
    ;

var_decl
    : TOKEN_INT TOKEN_ID '=' expr {
        $$ = new BinaryOpNode("=", std::make_unique<VariableNode>(*$2), std::unique_ptr<ASTNode>($4));
        delete $2;
    }
    | TOKEN_INT TOKEN_ID {
        $$ = new VariableNode(*$2);
        delete $2;
    }
    ;

expr
    : TOKEN_ID '=' expr {
        $$ = new BinaryOpNode("=", std::make_unique<VariableNode>(*$1), std::unique_ptr<ASTNode>($3));
        delete $1;
    }
    | expr '+' expr { $$ = new BinaryOpNode("+", std::unique_ptr<ASTNode>($1), std::unique_ptr<ASTNode>($3)); }
    | expr '-' expr { $$ = new BinaryOpNode("-", std::unique_ptr<ASTNode>($1), std::unique_ptr<ASTNode>($3)); }
    | expr '*' expr { $$ = new BinaryOpNode("*", std::unique_ptr<ASTNode>($1), std::unique_ptr<ASTNode>($3)); }
    | expr '/' expr { $$ = new BinaryOpNode("/", std::unique_ptr<ASTNode>($1), std::unique_ptr<ASTNode>($3)); }
    | expr '<' expr { $$ = new BinaryOpNode("<", std::unique_ptr<ASTNode>($1), std::unique_ptr<ASTNode>($3)); }
    | expr '>' expr { $$ = new BinaryOpNode(">", std::unique_ptr<ASTNode>($1), std::unique_ptr<ASTNode>($3)); }
    | primary_expr { $$ = $1; }
    ;

primary_expr
    : TOKEN_NUM_INT { $$ = new NumberNode($1); }
    | TOKEN_NUM_FLOAT { $$ = new NumberNode($1); }
    | TOKEN_ID { $$ = new VariableNode(*$1); delete $1; }
    | '(' expr ')' { $$ = $2; }
    ;

%%

void yyerror(const char* s) {
    std::cerr << "Синтаксическая ошибка на строке " << yylineno << ": " << s << std::endl;
}