#include "scope_table.h"

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;
    ofstream& outlog;


public:
symbol_table(int bucket_count, ofstream& logStream) 
: bucket_count(bucket_count), current_scope_id(0), outlog(logStream) { 
    current_scope = new scope_table(bucket_count, 1, nullptr);
    if (!current_scope) {
        cerr << "Error: Failed to allocate memory for scope_table." << endl;
}
}


~symbol_table() {

    scope_table* temp = current_scope;
    while (temp != nullptr) {
        scope_table* parent = temp->get_parent_scope();
        delete temp;
        temp = parent;
    }
    current_scope = nullptr;
}

void enter_scope() {

    current_scope_id++;
    scope_table* new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
    current_scope = new_scope;
    
    // outlog << "New ScopeTable with id " << current_scope_id << " created" << endl;
}

void exit_scope() {
    if (current_scope != nullptr) {
        int exiting_id = current_scope->get_unique_id();
        scope_table* parent = current_scope->get_parent_scope();
        delete current_scope;
        current_scope = parent;
        // outlog << "Scopetable with id " << exiting_id << " removed" << endl;
    }
    
}

bool insert(symbol_info* symbol) {
    if (current_scope == nullptr) {
        // outlog << "No scope available for insertion" << endl;
        return false;
    }
    
    return current_scope->insert_in_scope(symbol);
}


bool remove(symbol_info* symbol) {
    if (current_scope == nullptr) {
        // outlog << "No scope available for removal" << endl;
        return false;
    }
    
    return current_scope->delete_from_scope(symbol);
}

symbol_info* lookup(symbol_info* symbol) {
    if (symbol == nullptr) {
        // outlog << "Error: lookup called with null symbol" << endl;
        return nullptr;
    }
    
    
    scope_table* temp = current_scope;
    symbol_info* sym = nullptr;
    
    while (temp != nullptr && sym == nullptr) {
        sym = temp->lookup_in_scope(symbol);
        if (sym == nullptr) {
            temp = temp->get_parent_scope();
        } else {
            // outlog << "Symbol '" << symbol->get_name() << "' found in ScopeTable# " << temp->get_unique_id() << endl;
        }
    }
    
    if (sym == nullptr) {
        outlog << "Symbol '" << symbol->get_name() << "' not found in any scope" << endl;
    }
    
    return sym;
}

void print_current_scope() {
    if (current_scope != nullptr) {
        current_scope->print_scope_table(outlog);
    } else {
        outlog << "No current scope to print" << endl;
    }
}

void print_all_scopes(ofstream& outlog) {
    outlog << "################################" << endl << endl;
    scope_table* temp = current_scope;
    while (temp != nullptr) {
        temp->print_scope_table(outlog);
        temp = temp->get_parent_scope();
    }
    outlog << "################################" << endl << endl;
}
};
