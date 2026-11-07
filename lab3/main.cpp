#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include "ast.hpp"

extern int yyparse();
extern FILE* yyin;
extern std::unique_ptr<BlockNode> root_node;

int main() {
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
    const char* test_code =
        "int a = 10;\n"
        "int b = 20;\n"
        "if (a < b) {\n"
        "    a = a + 5;\n"
        "} else {\n"
        "    b = b - 5;\n"
        "}\n";

    FILE* f = fopen("input.c", "w");
    if (f) {
        fputs(test_code, f);
        fclose(f);
    }

    yyin = fopen("input.c", "r");
    if (!yyin) {
        std::cerr << "Не вдалося відкрити вхідний файл!" << std::endl;
        return 1;
    }

    if (yyparse() == 0 && root_node) {
        std::cout << "Синтаксичний аналіз успішно завершено!\n";

        std::ofstream json_file("ast.json");
        root_node->dump_json(json_file);
        json_file.close();
        std::cout << "AST збережено в ast.json\n\n";

        std::stringstream ss;
        int t = 0;
        root_node->generate_code(ss, t);
        std::cout << "\nЗгенерований код:\n" << ss.str();
    }

    fclose(yyin);
    return 0;
}