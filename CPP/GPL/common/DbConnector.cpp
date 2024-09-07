#include "DbConnector.h"

#include <algorithm>
#include <pqxx/pqxx>
#include <sstream>

DbConnector::DbConnector(const DbSettings& DbConnection) throw():
	m_DbConnectionData(DbConnection), m_Connection(nullptr), m_Connected(false)
{
	try
	{
		m_Connection = new pqxx::asyncconnection(DbConnectionDataToString(m_DbConnectionData));
	}
	catch (const exception& e)
	{
	}
}

DbReturnCode DbConnector::Connect()
{
	try
	{
		m_Connection = new pqxx::asyncconnection(DbConnectionDataToString(m_DbConnectionData));
		m_Connection->activate();
	}
	catch (const exception& e)
	{
		m_Connected = false;
		return DbReturnCode(DbReturnCode::Code::ERROR, e.what());
	}

	m_Connected = true;
	return DbReturnCode(DbReturnCode::Code::OK);
}

pqxx::asyncconnection* DbConnector::GetConnection()
{
	return m_Connection;
}

bool DbConnector::IsConnected()
{
	return m_Connected;
}

DbConnector::~DbConnector() throw()
{
	if (m_Connection)
	{
		delete m_Connection;
	}
}

string DbConnector::DbConnectionDataToString(const DbSettings& DbConnection)
{
	stringstream ss;
	if (DbConnection.GetHost().size())
	{
		ss << "host=" << DbConnection.GetHost() << " ";
	}

	if (0 != DbConnection.GetPort())
	{
		ss << "port=" << DbConnection.GetPort() << " ";
	}

	if (DbConnection.GetDbName().size())
	{
		ss << "dbname=" << DbConnection.GetDbName() << " ";
	}

	if (DbConnection.GetDbUser().size())
	{
		ss << "user=" << DbConnection.GetDbUser() << " ";
	}

	if (DbConnection.GetDbPassword().size())
	{
		ss << "password=" << DbConnection.GetDbPassword() << " ";
	}

	if (0 != DbConnection.GetTimeout())
	{
		ss << "connect_timeout=" << DbConnection.GetTimeout();
	}

	return ss.str();
}
