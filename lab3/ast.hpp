#pragma once
#include <iostream>
#include <memory>
#include <string>
#include <vector>
#include <sstream>

class ASTNode {
public:
    virtual ~ASTNode() = default;
    virtual void dump_json(std::ostream& out) const = 0;
    virtual void generate_code(std::stringstream& ss, int& temp_count) const = 0;
};

class NumberNode : public ASTNode {
public:
    double value;
    NumberNode(double val) : value(val) {}

    void dump_json(std::ostream& out) const override {
        out << "{\"name\": \"" << value << "\"}";
    }

    void generate_code(std::stringstream& ss, int& temp_count) const override {}
};

class VariableNode : public ASTNode {
public:
    std::string name;
    VariableNode(const std::string& n) : name(n) {}

    void dump_json(std::ostream& out) const override {
        out << "{\"name\": \"Id: " << name << "\"}";
    }

    void generate_code(std::stringstream& ss, int& temp_count) const override {}
};

class BinaryOpNode : public ASTNode {
public:
    std::string op;
    std::unique_ptr<ASTNode> left;
    std::unique_ptr<ASTNode> right;

    BinaryOpNode(std::string o, std::unique_ptr<ASTNode> l, std::unique_ptr<ASTNode> r)
        : op(std::move(o)), left(std::move(l)), right(std::move(r)) {
    }

    void dump_json(std::ostream& out) const override {
        out << "{\"name\": \"Op: " << op << "\", \"children\": [";
        left->dump_json(out);
        out << ", ";
        right->dump_json(out);
        out << "]}";
    }

    void generate_code(std::stringstream& ss, int& temp_count) const override {
        if (op == "=") {
            auto* var = dynamic_cast<VariableNode*>(left.get());
            int t = ++temp_count;
            right->generate_code(ss, temp_count);
            ss << "  " << (var ? var->name : "temp") << " = t" << t << "\n";
        }
        else {
            left->generate_code(ss, temp_count);
            int left_t = temp_count;
            right->generate_code(ss, temp_count);
            int right_t = temp_count;
            int my_t = ++temp_count;
            ss << "  t" << my_t << " = t" << left_t << " " << op << " t" << right_t << "\n";
        }
    }
};

class BlockNode : public ASTNode {
public:
    std::vector<std::unique_ptr<ASTNode>> statements;

    void add(std::unique_ptr<ASTNode> stmt) {
        statements.push_back(std::move(stmt));
    }

    void dump_json(std::ostream& out) const override {
        out << "{\"name\": \"Block\", \"children\": [";
        for (size_t i = 0; i < statements.size(); ++i) {
            statements[i]->dump_json(out);
            if (i + 1 < statements.size()) out << ", ";
        }
        out << "]}";
    }

    void generate_code(std::stringstream& ss, int& temp_count) const override {
        for (const auto& stmt : statements) {
            stmt->generate_code(ss, temp_count);
        }
    }
};

class IfNode : public ASTNode {
public:
    std::unique_ptr<ASTNode> condition;
    std::unique_ptr<ASTNode> then_block;
    std::unique_ptr<ASTNode> else_block;

    IfNode(std::unique_ptr<ASTNode> cond, std::unique_ptr<ASTNode> then_b, std::unique_ptr<ASTNode> else_b = nullptr)
        : condition(std::move(cond)), then_block(std::move(then_b)), else_block(std::move(else_b)) {
    }

    void dump_json(std::ostream& out) const override {
        out << "{\"name\": \"If\", \"children\": [";
        condition->dump_json(out);
        out << ", ";
        then_block->dump_json(out);
        if (else_block) {
            out << ", ";
            else_block->dump_json(out);
        }
        out << "]}";
    }

    void generate_code(std::stringstream& ss, int& temp_count) const override {
        int cond_t = ++temp_count;
        condition->generate_code(ss, temp_count);
        int label_false = ++temp_count;
        int label_end = ++temp_count;

        ss << "  if_false t" << cond_t << " goto L" << label_false << "\n";
        then_block->generate_code(ss, temp_count);
        ss << "  goto L" << label_end << "\n";
        ss << "L" << label_false << ":\n";
        if (else_block) {
            else_block->generate_code(ss, temp_count);
        }
        ss << "L" << label_end << ":\n";
    }
};