%{
#include <iostream> 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <iostream>
#include <sstream> 
#include <vector>
#include "y.tab.h"
extern FILE* yyin;
extern int line_number;
extern int column_number; 
extern int yylex(void);

void yyerror(const char * s) {
    printf("Error: On line %d, column %d: %s \n", line_number, column_number, s);
}


char *identToken;
int numberToken;
int count_names = 0;

enum Type { Integer, Array };

struct CodeNode {
        std::string code;
        std::string name;
};

struct Symbol {
  std::string name;
  Type type;
};

struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

std::vector <Function> symbol_table;

Function *get_function() {
  int last = symbol_table.size()-1;
  if (last < 0) {
    printf("***Error. Attempt to call get_function with an empty symbol table\n");
    printf("Create a 'Function' object using 'add_function_to_symbol_table' before\n");
    printf("calling 'find' or 'add_variable_to_symbol_table'");
    exit(1);
  }
  return &symbol_table[last];
}


bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value; 
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}

bool has_main(){
        bool TF = false;
        for (int i = 0; i<symbol_table.size(); i++){
                Function *f = &symbol_table[i];
                if (f->name == "main")
                        TF = true;
        }
        return TF;
}

std::string create_temp() {
        static int num = 0;
        std::ostringstream ss;
        ss << num;
        std::string value = "_temp" + ss.str();
        num += 1;
        return value;
}

std::string decl_temp_code(std::string &temp){
        return std::string(". ") + temp + std::string("\n");
}
%}

%union {

        char *op_val;
        struct CodeNode *node;
}

%error-verbose
%start prog_start

%token WRITE READ WHILE BREAK CONTINUE IF ELSE INSERT EXTRACT RETURN INTEGER
%token ADDITION SUBTRACTION MULTIPLICATION DIVISION MOD ASSIGN
%token EQUALS_TO LESS_THAN GREATER_THAN LESS_THAN_OR_EQUAL_TO GREATER_THAN_OR_EQUAL_TO NOT OPEN_PARAMETER
%token CLOSE_PARAMETER OPEN_SCOPE CLOSE_SCOPE OPEN_BRACKET CLOSE_BRACKET END_STATEMENT COMMA ENDL
%type <node> functions
%type <node> function
%type <node> function_call
%type <node> statements
%type <node> statement
%type <node> assign_statement
%type <node> else_statement
%type <node> print_statement
%type <node> input_statement
%type <node> if_statement
%type <node> while_statement
%type <node> break_statement
%type <node> continue_statement
%type <node> return_statement
%type <node> int_declaration
%type <node> array_declaration
%type <node> assign_int
%type <node> assign_array
%type <node> add_expression
%type <node> args
%token <op_val> ALPHA
%token <op_val> DIGIT
%type <node> mult_expression 
%type <node> expression 
%type <node> binary_expression 
%type <node> base_expression  
%type <node> param
%type <node> params
%type <node> repeat_args
%type <node> return_expression
%%

prog_start: 
        %empty /* epsilon */ 
        {} 
        | functions 
        {
               CodeNode *node = $1; 
                //printf("All generated code: \n");
                printf("%s\n", node->code.c_str());      

        }
        ;

functions: 
        function 
        {
                CodeNode *func = $1;
                std::string code = func->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
        }
        | function functions 
        {
                CodeNode *func = $1;
                CodeNode *funcs = $2;
                std::string code = func->code + std::string("\n") + funcs->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
        }
        ;

function: 
        INTEGER ALPHA {std::string func_name = $2;add_function_to_symbol_table(func_name);} OPEN_PARAMETER args CLOSE_PARAMETER OPEN_SCOPE statements CLOSE_SCOPE 
        {
                std::string func_name = $2;
                CodeNode *params = $5;
                CodeNode *stmts = $8;
                std::string code = std::string("func ") + func_name + std::string("\n");
                //code += func_name; //not needed
                //code += params->code;
                code += stmts->code;
                code += std::string("endfunc");
                
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node; 
        }
	;

statements: 
        statement statements 
        {
                CodeNode *stmt1 = $1;
                CodeNode *stmt2 = $2;
                CodeNode *node = new CodeNode;
                node->code = stmt1->code + stmt2->code;
                $$ = node; 
        }
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

statement: 
        int_declaration 
        {
                CodeNode *int_declar = $1;
                CodeNode *node = new CodeNode;
                node->code = int_declar->code;
                $$ = node;
        }
        | array_declaration 
        {
                CodeNode *array_declar = $1;
                CodeNode *node = new CodeNode;
                node->code = array_declar->code;
                $$ = node;
        }
        | print_statement 
        {
                CodeNode *print_stmt = $1;
                CodeNode *node = new CodeNode;
                node->code = print_stmt->code;
                $$ = node;
        }
        | input_statement 
        {
                CodeNode *input_stmt = $1;
                CodeNode *node = new CodeNode;
                node->code = input_stmt->code;
                $$ = node;
        }
        | if_statement 
        {
                CodeNode *if_stmt = $1;
                CodeNode *node = new CodeNode;
                node->code = if_stmt->code;
                $$ = node;
        }
        | while_statement 
        {
                CodeNode *while_stmt = $1;
                CodeNode *node = new CodeNode;
                node->code = while_stmt->code;
                $$ = node;
        }
        | break_statement 
        {
                CodeNode *break_stmt = $1;
                CodeNode *node = new CodeNode;
                node->code = break_stmt->code;
                $$ = node;
        }
        | continue_statement 
        {
                CodeNode *continue_stmt = $1;
                CodeNode *node = new CodeNode;
                node->code = continue_stmt->code;
                $$ = node;
        }
        | function_call 
        {
                CodeNode *func_call = $1;
                CodeNode *node = new CodeNode;
                node->code = func_call->code;
                $$ = node;
        }
        | return_statement 
        {
                CodeNode *return_stmt = $1;
                CodeNode *node = new CodeNode;
                node->code = return_stmt->code;
                $$ = node;
        }
        | assign_int 
        {
                CodeNode *assign_int = $1;
                CodeNode *node = new CodeNode;
                node->code = assign_int->code;
                $$ = node;
        }
        | assign_array 
        {
                CodeNode *assign_array = $1;
                CodeNode *node = new CodeNode;
                node->code = assign_array->code;
                $$ = node;
        }
        ;

int_declaration: 
        INTEGER ALPHA {std::string var_name = $2;Type type = Integer; add_variable_to_symbol_table(var_name, type);} assign_statement END_STATEMENT 
        {
                CodeNode *assign_statement = $4;
                std::string value = $2;
                Type t = Integer;
                add_variable_to_symbol_table(value, t);

                std::string code = std::string(". ") + value + std::string("\n");
                CodeNode *node = new CodeNode;
                node->code += code;
                node->code += assign_statement->code;
                node->code = code;
                $$ = node;
        }
        ;

array_declaration: 
        INTEGER ALPHA {std::string var_name = $2;Type type = Integer; add_variable_to_symbol_table(var_name, type);} OPEN_BRACKET add_expression CLOSE_BRACKET assign_statement END_STATEMENT 
        {
                std::string value = $2;
                CodeNode *add_exp = $5;
                std::string code = std::string(".[] ") + value + std::string(" \n");
                code += add_exp->code;
                
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node; 
        }
	;

assign_statement: 
        ASSIGN add_expression 
        {	
		CodeNode *node = new CodeNode;
                CodeNode *add_expression = $2;

                std::string code = std::string("=");
                code += add_expression->code;
                node->code = code;    
                $$ = node; 
        }
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

print_statement: 
        WRITE EXTRACT binary_expression END_STATEMENT 
        {
		            CodeNode *node = new CodeNode; 
		            CodeNode *binary_expression = $3; 
		            std::string code = std::string(".> ") + binary_expression->code + std::string("\n"); 
                node->code = code;   		
		            $$ = node; 
        }
        | 
        WRITE EXTRACT binary_expression EXTRACT ENDL END_STATEMENT 
        {
		            CodeNode *node = new CodeNode; 
		            CodeNode *binary_expression = $3;   
		            std::string code = std::string(".> ") + binary_expression->code + std::string("\n"); 
                node->code = code;
		            $$ = node;
        }
        ;

input_statement: 
        READ INSERT ALPHA END_STATEMENT 
        {
         	      CodeNode* node = new CodeNode; 
		            std::string value = $3; 
		            std::string code = std::string(".<") + value + std::string("\n"); 
		            node->code = code; 
		            $$ = node;        
        }
        ;

if_statement: 
        IF expression OPEN_SCOPE statements CLOSE_SCOPE else_statement 
        {
                CodeNode *node = new CodeNode; 
                CodeNode *expr = $2; 
                CodeNode *stmts = $4; 
                CodeNode *else_statement = $6; 

                std::string code = std::string("if ") + std::string("\n")  + std::string("else\n") + std::string("endif\n");
                code += expr->code;
                code += stmts->code;
                code += else_statement->code;
                node->code = code; 
                $$ = node;         
        }
        ;

else_statement: 
        ELSE OPEN_SCOPE statements CLOSE_SCOPE 
        {
		CodeNode* node = new CodeNode; 
		CodeNode* stmts = $3;
		std::string code = std::string("else\n"); 
		code += stmts->code; 
		code += std::string("endif\n");  
		node->code = code; 
		$$ = node; 
        }
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

while_statement: 
        WHILE OPEN_PARAMETER binary_expression CLOSE_PARAMETER OPEN_SCOPE statements CLOSE_SCOPE 
        {
		/*CodeNode* statements = $6; 	
                CodeNode* binary_expression = $3;
                code += std::string(":= beginloop\n"); 
                code += std::strig(".temp\n"); 
                code += std::string("< temp, ") + std::string("\n"); 
                code += std::string("?:= loopbody, temp\n"); 
                code += std::string(":= endloop\n"); 
                code += std::string(": loopbody\n"); 
                code += statements->code; 
                code += std::string(":= beginloop\n"); 
                code += std::string(": endloop\n"); 
                CodeNode* node = new CodeNode; 
                node->code = code; 
                $$ = node;*/
        }
        ;

break_statement: 
        BREAK END_STATEMENT 
        { 	
		CodeNode* node = new CodeNode; 
		node->code = std::string(":= endloop\n");  
		$$ = node; 		
        }
        ;  

continue_statement: 
        CONTINUE END_STATEMENT 
        {
		CodeNode* node = new CodeNode; 
		node->code = std::string(":= beginloop\n"); 
		$$ = node; 
        }
        ;

expression: 
        OPEN_PARAMETER binary_expression CLOSE_PARAMETER 
        {
		CodeNode* binary_expression = $2; 
		CodeNode* node = new CodeNode; 
		node->code = binary_expression->code; 
                node->name = binary_expression->name; 
		$$ = node; 
        }
        | DIGIT 
        {
                CodeNode* node = new CodeNode;
                std::string digit = $1;
                node->name = digit;
                $$ = node;
        }    
        | ALPHA 
        {
                CodeNode* node = new CodeNode;
                std::string alpha = $1;
                node->code = alpha;
                $$ = node;
        }
        | ALPHA OPEN_BRACKET add_expression CLOSE_BRACKET 
        {
		std::string value = $1; 
		CodeNode* add_expression = $3; 
		std::string code = value + std::string("[") + add_expression->code + std::string("]"); 
		CodeNode* node = new CodeNode; 
		node->code = code; 
		$$ = node; 
        }
        | function_call 
        {
		CodeNode* function_call = $1; 
		CodeNode* node = new CodeNode; 
		node->code = function_call->code; 
		$$ = node; 
        }
        ;

binary_expression: 
        add_expression 
        {
                CodeNode *add_expression = $1;
                CodeNode *node = new CodeNode;
                node->code = add_expression->code;
                node->name = add_expression->name;
                $$ = node;
        }
        | binary_expression EQUALS_TO add_expression 
        {
                std::string temp = create_temp();
                CodeNode* node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = std::string("== ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
        
        }
        | binary_expression NOT add_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = std::string("!= ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        | binary_expression LESS_THAN add_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = std::string("< ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        | binary_expression LESS_THAN_OR_EQUAL_TO add_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = std::string("<= ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        | binary_expression GREATER_THAN add_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = std::string("> ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        | binary_expression GREATER_THAN_OR_EQUAL_TO add_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = std::string(">= ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        ;

add_expression: 
        mult_expression 
        {
                CodeNode *mult_expression = $1;
                CodeNode *node = new CodeNode;
                node->code = mult_expression->code;
                node->name = mult_expression->name;
                $$ = node;
        }
        | add_expression ADDITION mult_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code;
                node->code = decl_temp_code(temp) + std::string("+ ") + temp + std::string(", ") + $1->code + std::string(", ") + $3->code + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        | add_expression SUBTRACTION mult_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code;
                node->code = decl_temp_code(temp) + std::string("- ") + temp + std::string(", ") + $1->code + std::string(", ") + $3->code + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        ;

mult_expression: 
        base_expression 
        {
                CodeNode *base_expression = $1;
                CodeNode *node = new CodeNode;
                node->code = base_expression->code;
                node->name = base_expression->name;
                $$ = node;
        }
        | mult_expression MULTIPLICATION base_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = decl_temp_code(temp) + std::string("* ") + temp + std::string(", ") + $1->code + std::string(", ") + $3->code + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        | mult_expression DIVISION base_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = decl_temp_code(temp) + std::string("/ ") + temp + std::string(", ") + $1->code + std::string(", ") + $3->code + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        | mult_expression MOD base_expression 
        {
                std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + decl_temp_code(temp);
                node->code = decl_temp_code(temp) + std::string("% ") + temp + std::string(", ") + $1->code + std::string(", ") + $3->code + std::string("\n");
                node->name = temp;
                $$ = node;
        }
        ;

//alex does below this
base_expression: 
        expression
        {
	        CodeNode* expression = $1;
                CodeNode* node = new CodeNode;
                node->code = expression->code;
                node->name = expression->name;
                $$ = node;
        }
        ;

assign_int: 
        ALPHA ASSIGN add_expression END_STATEMENT 
        {
                //need to pass name of temp var that we made to here
                //addexp->name holds the temp var
                std::string value = $1;
                CodeNode *addexp = $3;
                CodeNode *node = new CodeNode;

                //new code
                node->code = addexp->code; 
                node->code += std::string("= ") + value + std::string(", ") + addexp->name + std::string("\n");
                $$ = node;
        }       
        ;

assign_array: 
        ALPHA OPEN_BRACKET DIGIT CLOSE_BRACKET ASSIGN add_expression END_STATEMENT 
        {
                /*std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code + $6->code + decl_temp_code(temp);
                node->code = std::string("[]= ") + temp + std::string(", ") + $3->name + std::string(", ") + $6->name + std::string("\n");
                node->name = temp;
                $$ = node;*/
        }
        ;

function_call: 
        ALPHA OPEN_PARAMETER param CLOSE_PARAMETER 
        {
                /*std::string temp = create_temp();
                CodeNode *node = new CodeNode;
                node->code = $1->code + decl_temp_code(temp);
                node->code = std::string("call ") + $1->name + std::string(", ") + temp + std::string("\n");
                node->name = temp;
                $$ = node;*/
        }

param: 
        binary_expression params 
        {

        }
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

params: 
        COMMA binary_expression params 
        {
                
        }
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

args: 
        arg repeat_args 
        {

        } 
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

repeat_args: 
        COMMA arg repeat_args 
        {
                
        }
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

arg: 
        INTEGER ALPHA 
        {
                
        }
        ;

return_statement: 
        RETURN return_expression END_STATEMENT 
        {
                CodeNode *node = new CodeNode;
                CodeNode *ret = new CodeNode;
                node->code = std::string("ret ") + ret->code + std::string("\n");
                $$ = node;
        }
        ;

return_expression: 
        add_expression 
        {
                
        }
        | %empty 
        {
                CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;
%%

int main(int argc, char** argv) {
	if (argc >= 2) {
		yyin = fopen(argv[1], "r");
		if (yyin == NULL)
			yyin = stdin;
	}
	else {
		yyin = stdin;
	}
	yyparse();

        return 1;
}
