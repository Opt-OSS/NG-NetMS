#include "OriginManager.h"
#include "Origin.h"
#include "DbReturnCode.h"
#include "Profiler.h"
#include <iostream>
#include <algorithm>
#include <map>
#include <thread>
#include <mutex>
#include <chrono>
#include <queue>

using namespace chrono;

const int       ORIGIN_UNKNOWN  = -1;
const int64_t   MIN_INTERVAL    = 1;
const string&   DEF_VM_NAME     = "default"; // Default vendor/model name

std::queue<string> logMessages;
std::mutex         mtxMessage;

std::map<int, int> newOptTypes;
std::mutex         mtxOptTypes;


OriginManager::OriginManager(shared_ptr<Database>& db, shared_ptr<LogWriter>& logger, int imax) : 
    m_Database(db),
    m_Logger(logger),
    m_MaxInterval(imax)
{
}

/*
 * Remove spaces from the end
 */
inline std::string& rtrim(std::string &s)
{
    s.erase(std::find_if(s.rbegin(), s.rend(), std::not1(std::ptr_fun<int, int>(std::isspace))).base(), s.end());
    return s;
}

inline void threadLog(const string& mess, int id)
{
    std::lock_guard<std::mutex> locker(mtxMessage);
    logMessages.push("[ID:" + to_string(id) + "] " + mess);
}


inline void writeLog(shared_ptr<LogWriter>& logger)
{
    std::lock_guard<std::mutex> locker(mtxMessage);
    while(!logMessages.empty())
    {
        logger->LogInfo(logMessages.front());
        logMessages.pop();
    }
}

inline void updateTypes(shared_ptr<Database>& db)
{
    std::lock_guard<std::mutex> locker(mtxOptTypes);
    if (!newOptTypes.empty())
    {
        for(auto& opt : newOptTypes)
            db->SetOptionType(opt.first, opt.second);

        db->Save();
        newOptTypes.clear();
    }
}

void OriginManager::Run()
{
	m_Logger->LogInfo( "Running" );
    using namespace chrono;
    system_clock::time_point tp = system_clock::now();

    while (true) 
    {
        writeLog(m_Logger);
        updateTypes(m_Database);
        dump(m_Profiler, m_Database, system_clock::to_time_t(tp));

        tp += seconds(MIN_INTERVAL);
        this_thread::sleep_until(tp);
    }
}


void originThread(Origin &origin, Profiler &profiler, int imax)
{
    stringstream ss;
    ss << "Thread was started:" << endl;
    ss << "IP = " << origin.GetIpAddr( ) << endl;
    ss << "Version = " << origin.GetVersion( ) << endl;
    ss << "Community = " << origin.GetCommunity( ) << endl;
    for( auto option : origin.GetOptions( ) )
    {
        ss << "OID = " << option._oid << " track = " << option._track << endl;
    }
    ss << endl;
    threadLog( ss.str( ), origin.GetId( ) );

    // Check options through SNMP
    int64_t interval = MIN_INTERVAL;
    system_clock::time_point tp;
    while (!origin.TestOptions(newOptTypes, mtxOptTypes))
    {
        tp = system_clock::now();
        if (interval < imax)
        {
            tp += seconds(interval *= 2);
            threadLog("Can not check origin options. The next try in " + to_string(interval) + "s.", origin.GetId());
        }

        this_thread::sleep_until(tp);
    }

    if (!origin.GetMonitorableCount())
    {
        threadLog("There is no monitorable options. Tread will be stopped.", origin.GetId());
        return;
    }

    vector<SnmpOption> &options = origin.GetOptions();
    for (auto& opt : options)
    {
        opt._valueId = profiler.Add(opt._id, opt._optionType);
    }

    interval = MIN_INTERVAL;
    tp = system_clock::now();
    while (true) 
    {
        switch (origin.UpdateValues())
        {
            case RET_TIMEOUT:
            {
                if (interval < imax)
                {
                    interval *= 2;
                    threadLog("Can not update origin options. The next try in " + to_string(interval) + "s.", origin.GetId());
                }
            }
            break;
            case RET_ERROR:
            {
                origin.TestOptions(newOptTypes, mtxOptTypes);
                if (!origin.GetMonitorableCount())
                {
                    threadLog("There is no monitorable options. Tread will be stopped.", origin.GetId());
                    return;
                }
            }
            break;
            case RET_SUCCESS:
            {
                for (auto& opt : options)
                {
                    profiler.Update(opt._valueId, opt._value.bigintV);
                }

                interval = MIN_INTERVAL;
            }
            break;
            case RET_FAIL:
            {
                threadLog("Can not open SNMP session. Tread will be stopped.", origin.GetId());
                return;
            }
        }
        
        tp += seconds(interval);
        this_thread::sleep_until(tp);
    }
}

bool OriginManager::LoadOrigins()
{
    pqxx::result pqOrigins;
    pqxx::result models;
    map<int, Model> sharedModels;
    string originVendor, originModel, ipAddr;

    m_Logger->LogInfo("Before Read Origins");
    if(false == m_Database->ReadOrigins(pqOrigins))
    {
        return false;
    }

    m_Logger->LogInfo("Before origins empty");
    if (pqOrigins.empty())
    {
        m_Logger->LogError("There is no origins in the database.");
        return true;
    }
	
    try
    {
    	m_Logger->LogInfo("Before read origin models");
        if(m_Database->ReadOriginModels(models))
        {
            Model m;
            for (auto aRow : models)
            {
                m._id = aRow["id"].as<int>();
                m._vendor = aRow["vendor"].as<string>();
                m._model = aRow["model"].as<string>();
                m._snmpVersion = aRow["snmp_version"].as<string>();


                m_Logger->LogInfo("Before read origin model options");

                pqxx::result pqOriginModelOptions;
                if(m_Database->ReadOriginModelOptions(pqOriginModelOptions, m._id))
                {
                    ModelOption o;
                    for (auto aRow : pqOriginModelOptions)
                    {
                        o._id = aRow["id"].as<int>();
                        o._modelId = aRow["origin_models_id"].as<int>();
                        o._type = aRow["type"].as<int>();
                        o._name = aRow["name"].as<string>();
                        o._oid = aRow["oid"].as<string>();
                        o._unit = aRow["unit"].as<string>();
                        m._modelOptions[o._id] = ModelOption(o);
                    }
                }
                else
                {
                    m_Logger->LogInfo("Model " + m._model + " (id:" + to_string(m._id) + ") does not have any monitorable option.");
                    continue;
                }
				
                sharedModels[m._id] = Model(m);
                m._modelOptions.clear();        //Clear options for the next model
            }
        }

        m_Logger->LogInfo("before create new origins");

        bool vendorFound;
        string community;
        for (auto aRow : pqOrigins)
        {
        	m_Logger->LogInfo("-");
            m_Origins.push_back(Origin());		// Create new origin
            Origin &origin = m_Origins.back();
            m_Logger->LogInfo("-");
            origin.SetId(aRow["router_id"].as<int>());
            ipAddr = aRow["ip_addr"].as<string>();
            origin.SetIp(rtrim(ipAddr));
            m_Logger->LogInfo("-");
            if (m_Database->GetComunityStr(origin.GetId(), community))
            {
                origin.SetCommunity(rtrim(community));
            }
            m_Logger->LogInfo("-");
            if (aRow["eq_vendor"].is_null())
            {
                originVendor = DEF_VM_NAME;
            }
            else
            {
                originVendor = aRow["eq_vendor"].as<string>();
                originVendor = rtrim(originVendor);
            }
            m_Logger->LogInfo("-");
            
            if (aRow["eq_type"].is_null())
            {
                originModel = DEF_VM_NAME;
            }
            else
            {
                originModel = aRow["eq_type"].as<string>();
                originModel = rtrim(originModel);
            }
            m_Logger->LogInfo("-");

            origin.SetModelId( 0 );
            vendorFound = false;
            int commonModelId = 1;
            for (auto& mit : sharedModels)
            {
                if (mit.second._vendor != originVendor)
                    continue;
                else
                    vendorFound = true;

                if (vendorFound && mit.second._model == DEF_VM_NAME)
                    commonModelId = mit.first;

                if (mit.second._model != originModel)
                    continue;

                origin.SetModelId(mit.first);
                break;
            }
            m_Logger->LogInfo("end");
            if ( !origin.GetModelId( ) )
            {
                //create new model/options
                Model m;
                m._vendor = originVendor;
                m._model = originModel;
                m._snmpVersion = "2c";		//TODO
                m_Database->AddModel(m);
                origin.SetModelId(m._id);

                ModelOption o;
                for (auto& opt : sharedModels[commonModelId]._modelOptions)	//form
                {
                    o = opt.second;					//get option from the default template
                    o._modelId = m._id;				//set the new model ID
                    m_Database->AddModelOption(o);	//save as new, update id
                    m._modelOptions[o._id] = ModelOption(o);	//add option to the model
                }

                sharedModels[m._id] = Model(m);
            }

            m_Logger->LogInfo("Before read observer options");
            origin.SetVersion(sharedModels[origin.GetModelId()]._snmpVersion);  //Set SNMP version
            pqxx::result pqObserverOptions;
            if(m_Database->ReadObserverOptions(pqObserverOptions, origin.GetId()))
            {
                SnmpOption o;
                auto& model = sharedModels[origin.GetModelId()];
                model.OidsRenew();
                for (auto aRow : pqObserverOptions)
                {
                    o._modelOptionId = aRow["origin_model_options_id"].as<int>();
                    auto it = model._modelOptions.find(o._modelOptionId);
                    if (it == model._modelOptions.end())
                    {
                        //TODO Log it.
                        //m_Database->DelObserverOption(o._modelOptionId);	//Remove observer option from database
                        continue;
                    }
                    o._track = aRow["track"].as<bool>();
                    if (!o._track)
                        continue;	//skip untracked options

                    o._id = aRow["id"].as<int>();
                    o._originId = aRow["routers_id"].as<int>();

                    o._optionType = SnmpVT(it->second._type);
                    o._oid = it->second._oid;
                    origin.AddOption(o);
                    model._optionIDs.remove(o._modelOptionId);	//Math was found
                }

                //Add all new options
                for(auto& oid : model._optionIDs)
                {
                    SnmpOption opt;
                    opt._id = 0;
                    opt._track = true;
                    opt._originId = origin.GetId();
                    opt._modelOptionId = oid;
                    opt._optionType = SnmpVT(model._modelOptions[oid]._type);
                    opt._oid = model._modelOptions[oid]._oid;

                    m_Database->AddObserverOption(opt);
                    origin.AddOption(opt);
                }
            }
            m_Logger->LogInfo("Before optionscount");
            if (!origin.GetOptionsCount())
            {
                m_Origins.pop_back();
                continue;
            }

            if (!origin.GetMonitorableCount())
            {
                    m_Origins.pop_back();
                    continue;
            }
        }//for row in origins loop
	}
    catch (const exception &e)
    {
        m_Logger->LogError( e.what());
        return false;
    }

	return true;
}

bool OriginManager::LoadOriginThreads()
{
    for (auto &o : m_Origins)
    {
#if 0
        if (o.GetId() != 6468)
            continue;
#endif   
        m_Threads.push_back(std::thread(originThread, std::ref(o), std::ref(m_Profiler), m_MaxInterval));
        writeLog(m_Logger);
    }

    for (auto &t : m_Threads)
    {
        t.detach();
        writeLog(m_Logger);
    }
}
