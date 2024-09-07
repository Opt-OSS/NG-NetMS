#pragma once

#include <string>

#include "Database.h"

using std::string;

class Initializer
{
public:
	Initializer(shared_ptr<Database>& db, const string& configFileName);
	bool DropTables();
	bool CreateTables();
	bool Update();

private:
	bool AddModel(const string& vendor, const string& model, map<string, string>& options);

private:
	string m_Config;
	shared_ptr<Database> m_Database;
};
