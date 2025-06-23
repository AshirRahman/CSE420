#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    string symbol_type;// Write necessary attributes to store what type of symbol it is (variable/array/function)
    string data_type;  // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    vector<string> param_name;
    vector<string> param_type; // Write necessary attributes to store the parameters of a function
    int array_size; // Write necessary attributes to store the array size if the symbol is an array

public:
    symbol_info(string name, string type, string symbol_type="", string data_type="", vector<string> param_name=vector<string>(),vector<string> param_type=vector<string>(), int array_size = -1)
    {
        this->name = name;
        this->type = type;
        this->symbol_type = symbol_type;
        this-> data_type = data_type;
        this->param_name = param_name;
        this->param_type = param_type;
        this->array_size = array_size;
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    string get_symbol_type()
    {
        return symbol_type;
    }
    vector<string> get_param_name()
    {
        return param_name;
    }
    vector<string> get_param_type()
    {
        return param_type;
    }
    string get_data_type()
    {
        return data_type;
    }
    int get_array_size()
    {
        return array_size;
    }
    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }
    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }
    void set_param_name(vector<string> param_name)
    {
        this->param_name = param_name;
    }
    void set_param_type(vector<string> param_type)
    {
        this->param_type = param_type;
    }
    void set_array_size(int array_size)
    {
        this->array_size = array_size;
    }

    ~symbol_info()
    {
        
    }
};