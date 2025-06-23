#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        int hash_value = 0;
        for (char c : name) {
            hash_value = (hash_value * 31 + c) % bucket_count;
        }
        return hash_value;
    }

public:
scope_table() : bucket_count(0), unique_id(0), parent_scope(nullptr) {
}
scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    : bucket_count(bucket_count), unique_id(unique_id), parent_scope(parent_scope) {

    table.resize(bucket_count);
}

~scope_table() {
    for (int i = 0; i < bucket_count; ++i)
    {
        for (auto symbol : table[i])
        {
            delete symbol;
        }
    }
    table.clear();
}

scope_table* get_parent_scope() {
    return parent_scope;
}

int get_unique_id() {
    return unique_id;
}


symbol_info* lookup_in_scope(symbol_info* symbol) {
    string name = symbol->get_name();
    int bucket_no = hash_function(name);
    
    int position = 0;
    for (auto sym : table[bucket_no]) {
        if (sym->get_name() == name) {
            return sym;
        }
        position++;
    }
    
    return nullptr;
}

bool insert_in_scope(symbol_info* symbol) {
    
    if (lookup_in_scope(symbol) != nullptr) {
        return false; 
    }
    
    string name = symbol->get_name();
    int bucket_no = hash_function(name);
    
    
    table[bucket_no].push_back(symbol);
    
    return true;
}


bool delete_from_scope(symbol_info* symbol) {
    string name = symbol->get_name();
    int bucket_no = hash_function(name);
    
    auto& bucket = table[bucket_no];
    int position = 0;
    
    for (auto it = bucket.begin(); it != bucket.end(); ++it, ++position) {
        if ((*it)->get_name() == name) {
            bucket.erase(it);
            return true;
        }
    }
    
    return false; 
}


void print_scope_table(ofstream& outlog) {
    outlog << "ScopeTable # " + to_string(unique_id) << endl;
    
    for (int i = 0; i < bucket_count; i++) {
        if (!table[i].empty()) {
            outlog << i << " --> " << endl;
            for (auto symbol : table[i]) {
                outlog << "< " << symbol->get_name() << " : " << symbol->get_type() << " >" << endl;
                

                if (symbol->get_symbol_type() == "function") {
                    outlog << "Function Definition" << endl;
                    outlog << "Return Type: " << symbol->get_data_type() << endl;
                    
                    vector<string>param_name = symbol->get_param_name();
                    vector<string>param_type = symbol->get_param_type();
                    outlog << "Number of Parameters: " << param_name.size() << endl;
                    

                    if (!param_name.empty()) {

                        
                        outlog << "Parameter Details: ";
                        
                        for (size_t j = 0; j < param_name.size(); ++j) {
                            outlog << param_type[j] <<" "<< param_name[j];
                            if (j < param_name.size() - 1) {
                                outlog << ", ";
                            }
                        }
                        outlog << endl;
                    }
                } 
                else if (symbol->get_symbol_type() == "array") {
                    outlog << "Array" << endl;
                    outlog << "Type: " << symbol->get_data_type() << endl;
                    outlog << "Size: " << symbol->get_array_size() << endl;
                }
                else if (symbol->get_symbol_type() == "variable") {
                    outlog << "Variable" << endl;
                    outlog << "Type: " << symbol->get_data_type() << endl;
                }
            }
        }
    }
    outlog << endl;
}



};