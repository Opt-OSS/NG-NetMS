#include <boost/program_options/options_description.hpp>
#include <boost/program_options/parsers.hpp>
#include <boost/program_options/variables_map.hpp>
#include <boost/token_functions.hpp>
#include <boost/tokenizer.hpp>

#include "ConfigFileWriter.h"

using namespace boost;
using namespace boost::program_options;

#include <exception>
#include <fstream>
#include <iostream>
#include <sstream>

#include "Configuration.h"
#include "DbConnector.h"
#include "DbSettings.h"

class NgnmsDbSettings
{
public:
	NgnmsDbSettings():
		m_Port(DB_PORT), m_Timeout(DB_TIMEOUT), m_Host(DB_HOST), m_DbName(DB_NAME), m_DbUser(DB_USER), m_DbPassword(DB_PASSWORD)
	{
	}

	void Execute(int argc, char* argv[])
	{
		cout << "DB Settings " << VERSION_MAJOR << "." << VERSION_MINOR << " " << BUILD_DATE << " " << BUILD_TIME << endl;

		try
		{
			options_description desc("Program Usage", 1024, 512);

			stringstream hostDesription;
			stringstream portDesription;
			stringstream nameDesription;
			stringstream userDesription;
			stringstream passwordDesription;
			stringstream timeoutDesription;

			hostDesription << "Host for DB connection. Default is " << DB_HOST;
			portDesription << "Port for DB connection. Default is " << DB_PORT;
			nameDesription << "DB name. Default is " << DB_NAME;
			userDesription << "DB user. Default is " << DB_USER;
			passwordDesription << "Data base password. Default is " << DB_PASSWORD;
			timeoutDesription << "DB connection timeout. Default is " << DB_TIMEOUT << " seconds";

			desc.add_options()("help", "produce help message")("host,h", value<string>(&m_Host), hostDesription.str().c_str())(
				"port,p", value<int>(&m_Port), portDesription.str().c_str()
			)("name,n", value<string>(&m_DbName), nameDesription.str().c_str())(
				"user,u", value<string>(&m_DbUser), userDesription.str().c_str()
			)("password,p", value<string>(&m_DbPassword), passwordDesription.str().c_str()
			)("timeout,t", value<int>(&m_Timeout), timeoutDesription.str().c_str());

			variables_map vm;
			store(parse_command_line(argc, argv, desc), vm);

			if (vm.count("help"))
			{
				std::cout << desc << "\n";
				return;
			}

			notify(vm);
		}
		catch (std::exception& e)
		{
			std::cerr << "Error: " << e.what() << "\n";
			return;
		}
		catch (...)
		{
			std::cerr << "Unknown error!"
					  << "\n";
			return;
		}

		DbSettings dbSettings(m_Host, m_Port, m_DbName, m_DbUser, m_DbPassword, m_Timeout);
		dbSettings.SaveToFile(DB_CFG_FILE_NAME);

		DbConnector connector(dbSettings);
		DbReturnCode rc = connector.Connect();
		if (rc.IsFail())
		{
			cout << "Warning: Database connection: Failed!" << endl;
		}
		else
		{
			cout << "Info: Database connection: OK!" << endl;
		}

		cout << "Database settings stored into file (" << DB_CFG_FILE_NAME << ")" << endl;
	}

	static NgnmsDbSettings& GetInstance()
	{
		static NgnmsDbSettings instance;
		return instance;
	}

private:
	int m_Port;
	int m_Timeout;
	string m_Host;
	string m_DbName;
	string m_DbUser;
	string m_DbPassword;
};

int main(int argc, char* argv[])
{
	NgnmsDbSettings::GetInstance().Execute(argc, argv);
}
