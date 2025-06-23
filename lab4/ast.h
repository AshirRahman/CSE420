#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>
using namespace std;

class ASTNode {
public:
    virtual ~ASTNode() {}
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};

// Expression node types

class ExprNode : public ASTNode {
protected:
    string node_type; // Type information (int, float, void, etc.)
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};

// Variable node (for ID references)
// for a variable, like a or arr[i]
class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; // For array access, nullptr for simple variables

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }
    
    bool has_index() const { return index != nullptr; }
    
    // when variable = arr[i]
    // array offset calculate kore
    // to find the index 
    string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
        int& temp_count, int& label_count) const {
    // Generating code for the index expression
    string index_temp = index->generate_code(outcode, symbol_to_temp, temp_count, label_count); // to find idx

    int size = 4;
    if (node_type == "float" || node_type == "double") {
    size = 8;
    } 

    string offset = "t" + to_string(temp_count++); // creates a new temporary variable like t1, t2..
    outcode << offset << " = " << index_temp << " * " << size << endl;

    return offset;
    // returns a temporary variable name (like t1) holding the offset
    }


    // for variables like a or a[i]
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
        int& temp_count, int& label_count) const {
        if (!has_index()) {  // for normal variable like a
        return name; // returns the lexeme
        } else {
        string offset = generate_index_code(outcode, symbol_to_temp, temp_count, label_count);

        string value_temp = "t" + to_string(temp_count++);
        outcode << value_temp << " = " << name << "[" << offset<< "]" << endl;
        // arr[i] er bhitorer element return
        return value_temp;
        }}

    string get_name() const { return name; }
};

// Constant node

// for constant values
class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode,map<string, string>& symbol_to_temp,
                                    int& temp_count, int& label_count) const override {

    string temp = "t" + to_string(temp_count++); // temp variable
    outcode << temp << " = " << value << endl;
    // jemon t0 = 5
    return temp;
    }

};

// Binary operation node

// binary operation er jonno like x * y , i < j
class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
        int& temp_count, int& label_count) const override {
        string left_temp = left->generate_code(outcode, symbol_to_temp, temp_count, label_count); // gets temp var that holds the left temp value
        string right_temp = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (symbol_to_temp.count(left_temp)) {  // updates to the latest temp holding this value
            left_temp = symbol_to_temp[left_temp];
        }
        if (symbol_to_temp.count(right_temp)) {
            right_temp = symbol_to_temp[right_temp];
        }
        string bin_temp = "t" + to_string(temp_count++);

        outcode << bin_temp << " = " << left_temp << " " << op << " " << right_temp << endl;
        
        return bin_temp; // like t2 = t0 + t1
        }
};

// Unary operation node

// for -x (negation), !x (logical not)
class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {

                string operand_temp = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count); // child theke value nei like 5
                string uni_temp = "t" + to_string(temp_count++);
            
                outcode << uni_temp << " = " << op << operand_temp << endl;
            
                return uni_temp; // t1= !t0
    }
};

// Assignment node

// for x = 5;, a[i] = b;
class AssignNode : public ExprNode {
private:
    VarNode* lhs; // VarNode like a or a[i]
    ExprNode* rhs; // ExprNode like 5 or b

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
                
                // gets the value of the right side
                string rhs_temp = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);

                if (!lhs->has_index()) { // normal variable
                    outcode << lhs->get_name() << " = " << rhs_temp << endl;

                } else {               // Array 
                    string offset = lhs->generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
                    outcode << lhs->get_name() << "[" << offset << "] = " << rhs_temp << endl; // a[t1] = t0
                }
            
                return rhs_temp;
            } 
};

// Statement node types

class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};

// Expression statement node

// // for f();       // function call  
// a + b;     // throwaway computation  
// x = 5;     // assignment
class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
      
        string expr_temp = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        
        return expr_temp;  // result ta kothaw use hlew return kori incase if another node wants to know what temp was used 

// FuncCallNode hle generates code for calling the function
// AssignNode hle generates code for doing the assignment
// a + b hle just calculates the sum and discards the result
        }
};

// Block (compound statement) node

class BlockNode : public StmtNode {
private:                                      
    vector<StmtNode*> statements;


public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }

    
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {

            for (const auto& stmt : statements) { // protita line of code(statement) loop kore
                stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
                // each statement to generate its code
            }
        
            return ""; // No specific return value for the block itself

            //Go through every statement in the {} block one by one, and ask them to write their own code
        }
};

// If statement node

// for if and if-else statements 
class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; // nullptr if no else part

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                    int& temp_count, int& label_count) const override {
           string cond_temp = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count); // temp var e condition er code generate hoi
       
           string label_then = "L" + to_string(label_count++);
           string label_else = else_block ? ("L" + to_string(label_count++)) : "";
           string label_end = "L" + to_string(label_count++);
       
           if (else_block) {
               outcode << "if " << cond_temp << " goto " << label_then << endl;
               outcode << "goto " << label_else << endl;
       
               outcode << label_then << ":" << endl;
               then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
               outcode << "goto " << label_end << endl;
       
               outcode << label_else << ":" << endl;
               else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
           } 
           else {
               outcode << "if " << cond_temp << " goto " << label_then << endl;
               outcode << "goto " << label_end << endl;
       
               outcode << label_then << ":" << endl;
               then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
           }
       
           outcode << label_end << ":" << endl;
           return "";


           //Make a label for the if part, maybe for the else part, and an end.
//Check the condition, jump to the right block, and always go to the end when done.
       }
       

        
};

// While statement node

class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
            string label_start = "L" + to_string(label_count++);  // lable for condition
            string label_body = "L" + to_string(label_count++); // body
            string label_end = "L" + to_string(label_count++); // if condition is false

            outcode << label_start << ":" << endl;

            string cond_temp = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);  // generates code for condition
            outcode << "if " << cond_temp << " goto " << label_body << endl; // if true go to loop body
            outcode << "goto " << label_end << endl; // if false

            outcode << label_body << ":" << endl;
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "goto " << label_start << endl; // goes to end

            outcode << label_end << ":" << endl;

            return label_end;
        }

};

// For statement node

class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) delete init;
        if (condition) delete condition;
        if (update) delete update;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
        int& temp_count, int& label_count) const override {

        if (init) { // code for int i =0
        init->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        string label_start = "L" + to_string(label_count++);
        string label_body  = "L" + to_string(label_count++);
        string label_end   = "L" + to_string(label_count++);


        outcode << label_start << ":" << endl;
        string cond_temp = condition ? condition->generate_code(outcode, symbol_to_temp, temp_count, label_count) : "1";
        outcode << "if " << cond_temp << " goto " << label_body << endl; // if condition then generate code 
        outcode << "goto " << label_end << endl;


        outcode << label_body << ":" << endl;
        if (body) {
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        if (update) { // for i++
        update->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        outcode << "goto " << label_start << endl;


        outcode << label_end << ":" << endl;

        return "";
        }
};

// Return statement node

class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { if (expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) { // if return has expression like a+2
            string ret_temp = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count); // generates exprssion for code
            outcode << "return " << ret_temp << endl;
        } else {
            outcode << "return" << endl;
        }
        return "";
    }
};

// Declaration node

// like int a;
class DeclNode : public StmtNode {
private:
    string type;
    vector<pair<string, int>> vars; // Variable name and array size (0 for regular vars)

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {
        vars.push_back(make_pair(name, array_size));
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (const auto& var : vars) {
            const string& name = var.first;
            int size = var.second;
    
            if (size > 0) {
                outcode << "// Declaration: " << type << " " << name << "[" << size << "]" << endl;
            } else {
                outcode << "// Declaration: " << type << " " << name << endl;
            }
        }
        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; // Parameter type and name
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                int& temp_count, int& label_count) const override {
        
        outcode << "// Function: " << return_type << " " << name << "(";
        for (int i = 0; i < params.size(); ++i) {
            outcode << params[i].first << " " << params[i].second;
            if (i < params.size() - 1)
                outcode << ", ";
        }
        outcode << ")" << endl;
    
        for (const auto& param : params) {
            string temp = "t" + to_string(temp_count++);
            outcode << temp << " = " << param.second << endl;
            symbol_to_temp[param.second] = temp;
        }
    
        if (body) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
    
        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        // Don't delete args here - they'll be transferred to FuncCallNode
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    int size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // This node doesn't generate code directly
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
        int& temp_count, int& label_count) const override {
            vector<string> arg_temps;

            for (ExprNode* arg : arguments) {
                string arg_temp = arg->generate_code(outcode, symbol_to_temp, temp_count, label_count);
                arg_temps.push_back(arg_temp);
                string param_temp = "t" + to_string(temp_count++);
                outcode << param_temp <<" = "<<arg_temp<< endl;
                outcode << "param " << param_temp << endl;
                
            }
        
            string result_temp = "t" + to_string(temp_count++);
        
            outcode << result_temp << " = call " << func_name << ", " << arguments.size() << endl;
        
            return result_temp;
            
        }

};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (const auto& unit : units) {
            unit->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return ""; 
    }
};

#endif // AST_H