#pragma once

#include <MessageQueue.h>

#include <memory>
#include <pqxx/pqxx>
#include <string>

#include "DbConnector.h"
#include "DbSettings.h"
#include "LogWriter.h"
#include "Model.h"
#include "SnmpOption.h"

using std::shared_ptr;
using namespace ngnms;

/*! This class provides methods for interaction with Database.
 * Class contains predefined templates for SQL requests.
 *
 * Notes:
 */
class Database
{
public:
	Database(shared_ptr<LogWriter>& logger, bool mdef);
	bool Connect(const DbSettings& Settings);
	bool DeleteTables();
	bool CreateTables();
	bool CreateHistoryTable(const SnmpVT& t);
	bool ReadOrigins(pqxx::result& result);
	bool ReadOriginModels(pqxx::result& result);
	bool ReadOriginModelOptions(pqxx::result& result, const int modelId);
	bool ReadObserverOptions(pqxx::result& result, const int rid);
	bool AddModel(Model& model);
	bool FindModel(Model& model);
	bool AddModelOption(ModelOption& opt);
	bool AddObserverOption(SnmpOption& opt);
	bool DelObserverOption(const int oid);
	bool SetModelOption(ModelOption& opt);
	bool GetComunityStr(int oid, string& comunity);
	bool SetOptionType(const int id, const int type);
	bool LoadDatabaseKey();
	void SetValue(SnmpValue& value, const time_t& ts);
	bool Save();

private:
	shared_ptr<DbConnector> m_Connector;
	shared_ptr<LogWriter> m_Logger;
	DbSettings m_DbConnectionData;
	string m_Query;
	bool m_Ret;
	bool m_Printed;
	bool m_MDef;
	std::vector<int> m_VTypes;
	string m_Key;

	bool Save(pqxx::result& result);
	bool Add(int& id);
};
