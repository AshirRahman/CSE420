#include "symbol_info.h"
#include <list>
#include <fstream>
#include <string>
#include <iomanip> 
extern ofstream outlog; 
class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        int hash_idx = 0;
        for (char w:name){
            hash_idx += w;
        }
        hash_idx = hash_idx % bucket_count;
        return hash_idx;
    }

    public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();

    // you can add more methods if you need
};

scope_table::scope_table()
    {
        bucket_count = 10;
        unique_id = 1;
        table.resize(bucket_count);
        outlog << "New ScopeTable with ID " << unique_id << " created" << endl
               << endl;
    }

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
        outlog << "New ScopeTable with ID " << unique_id << " created" << endl
               << endl;
    }

scope_table *scope_table::get_parent_scope()
    {
        return parent_scope;
    }

int scope_table::get_unique_id()
    {
        return unique_id;
    }
symbol_info *scope_table::lookup_in_scope(symbol_info* symbol)
    {
        int hash_val = hash_function(symbol->get_name());

        for (symbol_info *current : table[hash_val])
        {
            if (current->get_name() == symbol->get_name())
            {
                return current;
            }
        }
        return NULL;
    }
bool scope_table::insert_in_scope(symbol_info* symbol)
    {
        if (lookup_in_scope(symbol) != NULL)
        {
            return false;
        }

        int hash_value = hash_function(symbol->get_name());
        table[hash_value].push_back(symbol);
        return true;
    }
bool scope_table::delete_from_scope(symbol_info* symbol)
    {
        int hash_val = hash_function(symbol->get_name());

        auto &bucket = table[hash_val];
        for (auto it = bucket.begin(); it != bucket.end(); ++it)
        {
            if ((*it)->get_name() == symbol->get_name())
            {
                bucket.erase(it);
                return true;
            }
        }
        return false;
    }
void scope_table::print_scope_table(ofstream& outlog)
    {
        outlog << "ScopeTable # " << unique_id << endl;
        for (int i = 0; i < bucket_count; i++)
        {
            if (!table[i].empty())
            {
                outlog << i << " --> " << endl; 
                for (auto current : table[i])
                {
                    outlog << "< " << current->get_name() << " : " << current->get_type() << " >" << endl;

                    if (current->get_is_function())
                    {

                        outlog << "Function Definition" << endl;
                        outlog << "Return Type: " << current->get_return_type() << endl;
                        vector<pair<string, string>> params = current->get_parameters();
                        outlog << "Number of Parameters: " << params.size() << endl;
                        outlog << "Parameter Details: ";
                        for (int j = 0; j < params.size(); j++)
                        {
                            outlog << params[j].first << " " << params[j].second;
                            if (j < params.size() - 1)
                                outlog << ", ";
                        }
                        outlog << endl;
                    }
                    else if (current->get_is_array())
                    {
                        outlog << "Array" << endl;
                        outlog << "Type: " << current->get_data_type() << endl;
                        outlog << "Size: " << current->get_array_size() << endl;
                    }
                    else
                    {

                        outlog << "Variable" << endl;
                        outlog << "Type: " << current->get_data_type() << endl;
                    }
                }
            }
        }
        outlog << endl; 
    }
scope_table::~scope_table()
    {
        outlog << "Scopetable with ID " << unique_id << " removed" << endl
               << endl;
        for (auto &bucket : table)
        {
            for (auto symbol : bucket)
            {
                delete symbol;
            }
            bucket.clear();
        }
        table.clear();
    }

