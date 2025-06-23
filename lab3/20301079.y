%{

#include "symbol_table.h"
#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

vector<string> split(const string& str, char delim) {
    vector<string> tokens;
    stringstream ss(str); 
    string token;
    while (getline(ss, token, delim)) {
        tokens.push_back(token);
    }
    return tokens;
};

int lines = 1;
int error_count = 0;
ofstream outlog;
ofstream error;

symbol_table* sym_table;

string current_data_type; 
string array_size;
string symbol_type;
vector<string> current_param_name;
vector<string> current_param_type;
bool void_func;

void yyerror(char *s)
{
    error<<"At line "<<lines<<" "<<s<<endl<<endl;
}

void print_error(const std::string& msg) {
    error << "At Line " << lines << ": " << msg << std::endl<<endl;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
        outlog<<"Symbol Table"<<endl<<endl;
        sym_table->print_all_scopes(outlog);
        $$ = new symbol_info("program_start", "start");
    }
    ;

program : program unit
    {
        outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
        outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
    }
    | unit
    {
        outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"program");
    }
    ;

unit : var_declaration
     {
        outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"unit");
     }
     | func_definition
     {
        outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"unit");
     }
     ;

func_definition : type_specifier ID LPAREN  parameter_list RPAREN {sym_table->enter_scope();
                    
                    for(int i=0; i<$4->get_param_name().size(); i++) {
                        if(!$4->get_param_name()[i].empty()) {
                            symbol_info* param = new symbol_info($4->get_param_name()[i], "ID", "variable", $4->get_param_type()[i]);
                            bool success = sym_table->insert(param);
                        if (!success) {
                print_error("Multiple declaration of variable "+std::string($4->get_param_name()[i])+" in paramater of "+ $2->get_name());
                error_count++;
                        }}}} compound_statement 
        {    
            outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
            outlog<<$1->get_data_type()<<" "<<$2->get_name()<<"("+$4->get_name()+")\n"<<$6->get_name()<<endl<<endl;

            symbol_info* func = new symbol_info($2->get_name(),"ID", "function", $1->get_data_type(), {$4->get_param_name()}, {$4->get_param_type()});
            bool success = sym_table->insert(func);
            if (success) {
                outlog << "Function " << $2->get_name() << " inserted into symbol table" << endl;
            } else {
                print_error("Multiple declaration of function "+$2->get_name());
                error_count++;
            
            }
            $$ = new symbol_info($1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")\n"+$6->get_name(),"func_def");    

            
            current_param_name.clear();
            current_param_type.clear();
        }
        | type_specifier ID LPAREN RPAREN  {sym_table->enter_scope();} compound_statement
        {
            outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
            outlog<<$1->get_data_type()<<" "<<$2->get_name()<<"()\n"<<$5->get_name()<<endl<<endl;
            
            symbol_info* func = new symbol_info($2->get_name(), "ID", "function", $1->get_data_type());
            bool success = sym_table->insert(func);
            if (success) {
                outlog << "Function " << $2->get_name() << " inserted into symbol table" << endl;
            } else {
              print_error("Multiple declaration of function "+$2->get_name());
              error_count++;
            
            }
            $$ = new symbol_info($1->get_name()+" "+$2->get_name()+"()\n"+$5->get_name(),"func_def");    
            current_param_name.clear();
            current_param_type.clear();
        }
        
        ;

parameter_list : parameter_list COMMA type_specifier ID
        {
            outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
            outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;
            
            
            current_param_name = $1->get_param_name();
            current_param_type = $1->get_param_type();
            
            
            current_param_name.push_back($4->get_name());
            current_param_type.push_back($3->get_data_type());  

            $$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");
            $$->set_param_name(current_param_name);
            $$->set_param_type(current_param_type);


        }
        | parameter_list COMMA type_specifier
        {
            outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
            outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
            
            current_param_name = $1->get_param_name();
            current_param_type = $1->get_param_type();

            current_param_name.push_back("");  
            current_param_type.push_back($3->get_data_type());

            $$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");
            $$->set_param_name(current_param_name);
            $$->set_param_type(current_param_type);
        }
        | type_specifier ID
        {
            outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
            outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;
            

            
            current_param_name = {$2->get_name()};  
            current_param_type = {$1->get_data_type()};  


            $$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");
            $$->set_param_name(current_param_name);
            $$->set_param_type(current_param_type);
        }
        | type_specifier
        {
            outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            
          
            current_param_name = {""};
            current_param_type = {$1->get_data_type()};  
            $$ = new symbol_info($1->get_name(),"param_list");
            $$->set_param_name(current_param_name);
            $$->set_param_type(current_param_type);
        }
        ;
compound_statement : LCURL statements RCURL
            { 
                outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
                outlog<<"{\n"+$3->get_name()+"\n}"<<endl<<endl;
                sym_table->print_all_scopes(outlog);
                sym_table->exit_scope();
                outlog << "Exited scope" << endl;
                $$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");
            }
            | LCURL RCURL
            { 
                outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
                outlog<<"{\n}"<<endl<<endl;
                sym_table->print_all_scopes(outlog);
                sym_table->exit_scope();
                outlog << "Exited scope" << endl;
                $$ = new symbol_info("{\n}","comp_stmnt");
            }
            ;
            
var_declaration : type_specifier declaration_list SEMICOLON
        { if ($1->get_data_type() == "void") {
        print_error("Variable type can not be void");
        error_count++;
    } else
         {
            outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
            outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;
            $$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");
            $$->set_data_type($1->get_data_type());
            
    
         }
        }
         ;

type_specifier : INT
        {
            outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
            outlog<<"int"<<endl<<endl;
            $$ = new symbol_info("int","type");
            $$->set_data_type("int");
            current_data_type = "int";
        }
        | FLOAT
        {
            outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
            outlog<<"float"<<endl<<endl;
            $$ = new symbol_info("float","type");
            $$->set_data_type("float");
            current_data_type = "float";
        }
        | VOID
        {
            outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
            outlog<<"void"<<endl<<endl;
            $$ = new symbol_info("void","type");
            $$->set_data_type("void");
            current_data_type = "void";
        }
        ;

declaration_list : declaration_list COMMA ID
          {
            outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
            outlog<<$1->get_name()+","<<$3->get_name()<<endl<<endl;
            symbol_info* symbol = new symbol_info($3->get_name(), "ID", "variable", current_data_type, {});
            bool success = sym_table->insert(symbol);
            if (success) {
                outlog << "Variable " << $3->get_name() << " inserted into symbol table" << endl;
            } else {
                print_error("Multiple declaration of variable "+$3->get_name());
                error_count++;
            }
            $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "declaration_list");
            $$->set_data_type($1->get_data_type());
          }
          | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
          {
            outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
            outlog<<$1->get_name()+","<<$3->get_name()<<"["<<$5->get_name()<<"]"<<endl<<endl;
            int array_size = stoi($5->get_name());
            symbol_info* symbol = new symbol_info($3->get_name(), "ID", "array", current_data_type, {}, {},array_size);
            bool success = sym_table->insert(symbol);
            if (success) {
                outlog << "Array " << $3->get_name() << " inserted into symbol table" << endl;
            } else {
               print_error("Multiple declaration of array "+$3->get_name());
               error_count++;
            }
            
            $$ = new symbol_info($1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]", "decl_list");
          }
          | ID
          {
            outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            symbol_info* symbol = new symbol_info($1->get_name(), "ID", "variable", current_data_type, {},{});
            bool success = sym_table->insert(symbol);
            if (success) {
                outlog << "Variable " << $1->get_name() << " inserted into symbol table" << endl;
            } else {
                print_error("Multiple declaration of variable "+$1->get_name());
                error_count++;
            
            }
            $$ = new symbol_info($1->get_name(), "decl_list");
          }
          | ID LTHIRD CONST_INT RTHIRD
          {
            outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
            outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;
            int array_size = stoi($3->get_name());
            symbol_info* symbol = new symbol_info($1->get_name(), "ID", "array", current_data_type, {}, {},array_size);
            bool success = sym_table->insert(symbol);
            if (success) {
                outlog << "Array " << $1->get_name() << " inserted into symbol table" << endl;
            } else {
                print_error("Multiple declaration of array "+$1->get_name());
                error_count++;
            
            }
            $$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]", "decl_list");
          }
          ;
          
statements : statement
       {
            outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"stmnts");
       }
       | statements statement
       {
            outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
            outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
       }
       ;
       
statement : var_declaration
      {
            outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"stmnt");
            $$->set_data_type($1->get_data_type());
      }
      | func_definition
      {
            outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"stmnt");
      }
      | expression_statement
      {
            outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"stmnt");
      }
      | compound_statement
      {
            outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"stmnt");
      }
      | FOR LPAREN expression_statement expression_statement expression RPAREN statement
      {
            outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
            outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;
            $$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
      }
      | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
      {
            outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
            outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
            $$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
      }
      | IF LPAREN expression RPAREN statement ELSE statement
      {
            outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
            outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;
            $$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
      }
      | WHILE LPAREN expression RPAREN statement
      {
            outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
            outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
            $$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
      }
      | PRINTLN LPAREN ID RPAREN SEMICOLON
      {
            outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
            outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl; 
        symbol_info* temp = new symbol_info($3->get_name(), "ID");
        symbol_info* sym = sym_table->lookup(temp);
        if (!sym) {
        print_error("Undeclared variable '" + $3->get_name() + "'");
        error_count++;  
      }
      else{
        $$ = new symbol_info("printf("+$3->get_name()+");","stmnt");
      }
      }
      | RETURN expression SEMICOLON
      {
            outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
            outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;
            $$ = new symbol_info("return "+$2->get_name()+";","stmnt");

      }
      ;
      
expression_statement : SEMICOLON
            {
                outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
                outlog<<";"<<endl<<endl;
                $$ = new symbol_info(";","expr_stmt");
            }            
            | expression SEMICOLON 
            {
                outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
                outlog<<$1->get_name()<<";"<<endl<<endl;
                $$ = new symbol_info($1->get_name()+";","expr_stmt");
            }
            ;
      
variable : ID     
      {
        outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"varbl");
        symbol_info* temp = new symbol_info($1->get_name(), "ID");
        symbol_info* sym = sym_table->lookup(temp);
        if (!sym) {
        print_error("Undeclared variable '" + $1->get_name() + "'");
        error_count++;}
        else if (sym->get_symbol_type() == "array") {
            print_error("Variable is of array type: " +$1->get_name());
            error_count++;}
        else{
        $$->set_data_type(sym->get_data_type());

    }
     }    
     | ID LTHIRD expression RTHIRD 
     {
        outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
        outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;
        $$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");
        $$->set_data_type($1->get_data_type());
        symbol_info* temp = new symbol_info($1->get_name(), "ID");
        symbol_info* arr = sym_table->lookup(temp);
        if (arr != nullptr) {
            if (arr->get_symbol_type() != "array") {
                print_error("variable is not of array type : "+$1->get_name());
                error_count++;
            } else {
                $$->set_data_type(arr->get_data_type());
            }
        }
        if ($3->get_data_type() != "int") {
        print_error("Array index is not of integer type :"+$1->get_name());
        error_count++;
    
    }

        
     }
     ;
     
expression : variable ASSIGNOP logic_expression     
       {
            outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
            outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;
            symbol_info* temp = new symbol_info($1->get_name(), "ID");
            symbol_info* sym = sym_table->lookup(temp);
            // error<<$3->get_data_type()<<lines<<endl;
            if ($1->get_data_type() =="int" && $3->get_data_type()  =="float" ){
                print_error("Warning: Assignment of float value into variable of integer type");
                error_count++;
    }
            else if ($3->get_data_type() == "void") {
                print_error("Operation on void function");
                error_count++;
    }

            $$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");
            
            $$->set_data_type($1->get_data_type());
       }
       | logic_expression
       {
            outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"expr");
            $$->set_data_type($1->get_data_type());
       }
       ;
            
logic_expression : rel_expression
         {
            outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"lgc_expr");
            $$->set_data_type($1->get_data_type());
         }    
         | rel_expression LOGICOP rel_expression 
         {
            outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
            outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
            if ($3->get_data_type()=="void"){
                $$->set_data_type("void");
            }
            else{
            $$->set_data_type("int");}
         }    
         ;
            
rel_expression    : simple_expression
        {
            outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"rel_expr");
            $$->set_data_type($1->get_data_type());
        }
        | simple_expression RELOP simple_expression
        {
            outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
            outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
            if ($3->get_data_type()=="void"){
                $$->set_data_type("void");
            }
            else{
            $$->set_data_type("int");}
         
        }
        ;
                
simple_expression : term
          {
            outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"simp_expr");
            if ($1->get_data_type() == "void") {
                $$->set_data_type("void");
        }else{
            $$->set_data_type($1->get_data_type());}
          }
          | simple_expression ADDOP term 
          {
            outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
            outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
                if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
                    $$->set_data_type("void");
                }
                else if ($1->get_data_type() == "float" || $3->get_data_type() == "float") {
                    $$->set_data_type("float");
                } else {
                    $$->set_data_type("int");
                }
            $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");
          }
          ;
                    
term :    unary_expression
     {
            outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"term");
            $$->set_data_type($1->get_data_type());

     }
     |  term MULOP unary_expression
     {
            outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
            outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");
                if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
                print_error("Operation on void function");
                error_count++;
                $$->set_data_type("void");
            }
            else if ($2->get_name() == "%") {
                // Both operands must be integers
                if ($1->get_data_type() != "int" || $3->get_data_type() != "int") {
                    print_error("Modulus operator on non integer type");
                    error_count++;
                    $$->set_data_type("Undeclared");
                }
                // Division by zero
                if ($3->get_name() == "0") {
                   print_error("Modulus by 0");
                    error_count++;
                    $$->set_data_type("Undeclared");

                }
                else{
                $$->set_data_type("int");}
            } 
            // Division by zero check
            if ($2->get_name() == "/" && $3->get_name() == "0") {
                print_error("Division by 0");;
                error_count++;
                $$->set_data_type("Undeclared");}


     }
     ;

unary_expression : ADDOP unary_expression
         {
            outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
            outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
            $$->set_data_type($2->get_data_type());
         }
         | NOT unary_expression 
         {
            outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
            outlog<<"!"<<$2->get_name()<<endl<<endl;
            $$ = new symbol_info("!"+$2->get_name(),"un_expr");
            if ($1->get_data_type() == "void") {
                $$->set_data_type("void");}
            else{
                $$->set_data_type("int");
            }
        
         }
         | factor 
         {
            outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name(),"un_expr");
            $$->set_data_type($1->get_data_type());
         }
         ;
    
factor    : variable
    {
        outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"fctr");
        $$->set_data_type($1->get_data_type());
    }
     | ID LPAREN argument_list RPAREN
    {
        outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
        outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;

        symbol_info* temp = new symbol_info($1->get_name(), "ID");
        symbol_info* func = sym_table->lookup(temp);
        $$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");
        
        if (func != nullptr) {
            if (func->get_symbol_type() != "function") {
                print_error("Undeclared function "+$1->get_name());
                error_count++;
                $$->set_data_type("Undeclared");
            } else {
                vector<string> arg_types = $3->get_param_type();
                vector<string> param_types = func->get_param_type();

                if (param_types.size() != arg_types.size()) {
                    print_error("Inconsistencies in number of arguments in function call: "+$1->get_name());
                    error_count++;
                } else {
                    for (size_t i = 0; i < param_types.size(); i++) {
                        if (param_types[i] != arg_types[i]) {
                            error_count++;
                            print_error("argument "+ std::to_string(i+1) +" type mismatch in function call: "+ $1->get_name());
                        }
                    }
                }
                $$->set_data_type(func->get_data_type());
                if (func->get_data_type() == "void") {

                    $$->set_data_type("void");
                }
            }
        } else {
            error_count++;
            print_error("Undeclared function "+$1->get_name());
            $$->set_data_type("Undeclared");
        }
    }
    | LPAREN expression RPAREN
    {
        outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
        outlog<<"("<<$2->get_name()<<")"<<endl<<endl;
        $$ = new symbol_info("("+$2->get_name()+")","fctr");
        $$->set_data_type($2->get_data_type());
    }
    | CONST_INT 
    {
        outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"fctr");
        $$->set_data_type("int");
    }
    | CONST_FLOAT
    {
        outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"fctr");
        $$->set_data_type("float");
    }
    | variable INCOP 
    {
        outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
        outlog<<$1->get_name()<<"++"<<endl<<endl;
        $$ = new symbol_info($1->get_name()+"++","fctr");
        $$->set_data_type($1->get_data_type());
    }
    | variable DECOP
    {
        outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
        outlog<<$1->get_name()<<"--"<<endl<<endl;
        $$ = new symbol_info($1->get_name()+"--","fctr");
        $$->set_data_type($1->get_data_type());
    }
    ;
    
argument_list : arguments
    {
        outlog << "At line no: " << lines << " argument_list : arguments" << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "arg_list");
        $$->set_param_type($1->get_param_type());  
    }
    | 
    {
        outlog << "At line no: " << lines << " argument_list : empty" << endl << endl;
        $$ = new symbol_info("", "arg_list");
        $$->set_param_type({});  
    }
    ;

arguments : arguments COMMA logic_expression
    {
        outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression" << endl << endl;
        outlog << $1->get_name() << "," << $3->get_name() << endl << endl;
        
       
        vector<string> arg_types = $1->get_param_type();
        arg_types.push_back($3->get_data_type());
        
        $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "arg");
        $$->set_param_type(arg_types);
    }
    | logic_expression
    {
        outlog << "At line no: " << lines << " arguments : logic_expression" << endl << endl;
        outlog << $1->get_name() << endl << endl;
        

        vector<string> arg_types;
        arg_types.push_back($1->get_data_type());
        
        $$ = new symbol_info($1->get_name(), "arg");
        $$->set_param_type(arg_types);
    }
    ;
 

%%

int main(int argc, char *argv[])
{
    if(argc != 2) 
    {
        cout<<"Please input file name"<<endl;
        return 0;
    }
    yyin = fopen(argv[1], "r");
    outlog.open("20301079_log.txt", ios::trunc);
    error.open("20301079_error.txt", ios::trunc);
    if(yyin == NULL)
    {
        cout<<"Couldn't open file"<<endl;
        return 0;
    }
    
	sym_table= new symbol_table(10,outlog);
    sym_table->enter_scope();

    yyparse();
    
    outlog<<endl<<"Total lines: "<<lines<<endl;
    error<<endl<<"Total errors: "<<error_count<<endl;
    outlog.close();
    error.close();

    fclose(yyin);
    
    delete sym_table;
    return 0;
}