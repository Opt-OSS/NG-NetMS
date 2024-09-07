#include "Initializer.h"
#include "Database.h"
#include "Model.h"
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

using boost::property_tree::ptree;

const string& OPT_SNMP = "_snmp_version";

Initializer::Initializer(shared_ptr<Database>& db, const string& configFileName) :
	m_Config(configFileName),
	m_Database(db)
{
}

bool Initializer::DropTables( )
{
    return m_Database->DeleteTables( );
}

bool Initializer::CreateTables( )
{
    if( !m_Database->CreateTables( ) )
    {
        return false;
    }

    if( !m_Database->CreateHistoryTable( SnmpVT::BIGINT ) )
    {
        return false;
    }

    if( !m_Database->CreateHistoryTable( SnmpVT::DOUBLE ) )
    {
        return false;
    }

    return true;
}

/*
 * Get options from JSON configuration file
 * Create/Update database tables
 */
bool Initializer::Update()
{
	try
	{
        ptree ptCommon;
        list<string> vendors;
        map<string, string> optMapCommon;   //Common level options
		read_json(m_Config, ptCommon);
		for (const ptree::value_type& v : ptCommon)
		{
			if (!v.second.empty())
			{
				vendors.push_back(v.first);
				continue;	//Node is a tree
			}

			optMapCommon.insert(std::make_pair(v.first, v.second.get<string>("")));
		}
		
		//Create default vendor & model
		AddModel("default", "default", optMapCommon);
		
		for (auto& vendor : vendors)
		{
			list<string> models;
			map<string, string> optMapVendor = optMapCommon;
			ptree ptVendor = ptCommon.get_child(vendor);
			
			for (const ptree::value_type& v : ptVendor)
			{
				if (!v.second.empty())
				{
					models.push_back(v.first);
					continue;	//Node is a tree
				}

				auto it = optMapVendor.find(v.first);
				if (it != optMapVendor.end())
					it->second = v.second.get<string>("");
				else
					optMapVendor.insert(std::make_pair(v.first, v.second.get<string>("")));
			}
		
			//Create default model
			AddModel(vendor, "default", optMapVendor);
			
			for (auto& model : models)
			{
				map<string, string> optMapModel = optMapVendor;
				ptree ptModel = ptVendor.get_child(model);

				for (const ptree::value_type& v : ptModel)
				{
					if (!v.second.empty())
					{
						models.push_back(v.first);
						continue;	//Node is a tree
					}

					auto it = optMapModel.find(v.first);
					if (it != optMapModel.end())
						it->second = v.second.get<string>("");
					else
						optMapModel.insert(std::make_pair(v.first, v.second.get<string>("")));
				}
				
				AddModel(vendor, model, optMapVendor);
			}
		}
	}
	catch (int e)
	{
		//TODO Lod it
		return false;
	}
	
	return true;
}


void inline SplitValue(const string& value, ModelOption& opt)
{
	std::stringstream ss(value);
    if (!std::getline(ss, opt._oid, ' '))
		opt._oid.clear();
	
	if (!std::getline(ss, opt._unit, ' '))
		opt._unit = "NA";
}

inline bool findInResults(pqxx::result result, const string& name)
{
    if (result.empty() || result[0][0].is_null())
        return false;
        
    for (auto aRow : result)
    {
        if (name == aRow["name"].as<string>())
            return true;
    }
    
    return false;
}

bool Initializer::AddModel(const string& vendor, const string& model, map<string, string>& options)
{
	Model m;
    pqxx::result result;

	m._vendor = vendor;
	m._model = model;
    if (m_Database->FindModel(m))
    {
        m_Database->ReadOriginModelOptions(result, m._id);
    }
    else
    {
        auto it = options.find(OPT_SNMP);
        m._snmpVersion = it != options.end() ? it->second : "2c";
        if (!m_Database->AddModel(m))
            return false;
    }
    
    //Add model options to the database
    ModelOption o;
    o._modelId = m._id;
    for (auto& option : options)
    {
        if (option.first == OPT_SNMP)
            continue;

        if (findInResults(result, option.first))
            continue;

        o._name = option.first;
        SplitValue(option.second, o);
        m_Database->SetModelOption(o);
    }
    
    m_Database->Save();
    return true;
}
