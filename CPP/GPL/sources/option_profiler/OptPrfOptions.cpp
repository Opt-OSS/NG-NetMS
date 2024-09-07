#include "OptPrfOptions.h"

#include <boost/program_options/options_description.hpp>
#include <boost/program_options/parsers.hpp>
#include <boost/program_options/variables_map.hpp>
#include <boost/token_functions.hpp>
#include <boost/tokenizer.hpp>
#include <iostream>
#include <map>

using namespace boost;
using namespace boost::program_options;

OptPrfOptions::OptPrfOptions(): m_OptionsFile("db.cfg"), m_Drop(false), m_Debug(false), m_LogFile("ngnms_collector.log")
{
}

bool OptPrfOptions::Parse(int argc, char* argv[])
{
	try
	{
		options_description desc("Program Usage", 1024, 512);

		desc.add_options()("help", "Produce help message")(
			"options,o", value<string>(&m_OptionsFile), "Configuration file with encrypted data base options. Default is ./db.cfg"
		)("drop,d", "Create/renew Analyzer database tables")("verbose,v", "Verbose debug messages")(
			"log-file,l", value<string>(&m_LogFile), "Log file location. Default is ./ngnetms_opt_prf.log"
		);

		variables_map vm;
		store(parse_command_line(argc, argv, desc), vm);

		if (vm.count("help"))
		{
			std::cout << desc << "\n";
			return false;
		}

		m_Drop = vm.count("drop") ? true : false;
		m_Debug = vm.count("verbose") ? true : false;

		notify(vm);
	}
	catch (std::exception& e)
	{
		std::cerr << "Error: " << e.what() << "\n";
		return false;
	}
	catch (...)
	{
		std::cerr << "Unknown error!"
				  << "\n";
		return false;
	}

	return true;
}

string OptPrfOptions::GetOptionsFile()
{
	return m_OptionsFile;
}

bool OptPrfOptions::GetDrop()
{
	return m_Drop;
}

bool OptPrfOptions::GetDebug()
{
	return m_Debug;
}

string OptPrfOptions::GetLogFile()
{
	return m_LogFile;
}
