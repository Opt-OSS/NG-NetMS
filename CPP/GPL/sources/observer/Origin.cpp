#include "Origin.h"
#include "SnmpOption.h"
#include "OriginManager.h"
#include <stddef.h>
#include <list>
#include <vector>
#include <functional>
#include <iostream>
#include <net-snmp/net-snmp-config.h>
#include <net-snmp/net-snmp-includes.h>
#include <string>
#include <algorithm>

using namespace std;

Origin::Origin() :
    m_Id(0),
    m_ModelId(0),
    m_SnmpVersion(eVersion::v2c),
    m_Community("public")
{
}

void Origin::SetId( int id )
{
    m_Id = id;
}

void Origin::SetIp( const string& ip )
{
    m_IpAddr = ip;
}

void Origin::SetModelId( const int mid )
{
    m_ModelId = mid;
}

void Origin::SetCommunity( const string& comm )
{
    m_Community = comm;
}

void Origin::SetVersion( const string& version )
{
    if ( version == "1" )
    {
        m_SnmpVersion = eVersion::v1;
    }
    else if (version == "2c")
    {
        m_SnmpVersion = eVersion::v2c;
    }
    else if (version == "2u")
    {
        m_SnmpVersion = eVersion::v2u;
    }
    else if (version == "3")
    {
        m_SnmpVersion = eVersion::v3;
    }
    else
    {
        m_SnmpVersion = eVersion::v2c; // as default
    }
}

void Origin::AddOption(SnmpOption& option)
{
    m_Options.push_back(option);
}

int Origin::GetId() const
{
    return m_Id;
}

string Origin::GetIpAddr() const
{
    return m_IpAddr;
}

int Origin::GetModelId() const
{
    return m_ModelId;
}

int Origin::GetVersion() const
{
    return m_SnmpVersion;
}

vector<SnmpOption>& Origin::GetOptions()
{
    return m_Options;
}

int Origin::GetOptionsCount() const
{
    return m_Options.size();
}

string Origin::GetCommunity() const
{
    return m_Community;
}
   
inline SnmpVT Asn2IntType( const u_char at )
{ 
    switch(at)
    {
        case ASN_INTEGER:
        case 66:	//Gauge32:
        case ASN_CONTEXT:
            return SnmpVT::BIGINT;
        case ASN_OCTET_STR:	//without break
            return SnmpVT::STRING;
        default:
            return SnmpVT::UNKNOWN;
    }
}

int Origin::GetMonitorableCount() const
{
    int count = 0;
    for( const auto& opt : m_Options )
    {
        if (opt._track)
        {
            ++count;
        }
    }

    return count;
}

bool Origin::TestOptions( std::map<int, int>& newTypes, std::mutex& mtx )
{
    struct snmp_session session;
    snmp_sess_init( &session );
    session.version = m_SnmpVersion;
    session.community = (u_char*)const_cast<char*>(m_Community.c_str());
    session.community_len = strlen((char*)session.community);
    session.peername = const_cast<char*>(m_IpAddr.c_str());

    void *sessp = snmp_sess_open( &session );
    if ( sessp == NULL )
    {
        return false;
    }

    vector<SnmpOption> optionsForDeletion;
    for( vector<SnmpOption>::iterator it= m_Options.begin() ; it < m_Options.end(); ++it )
    {
        struct snmp_pdu *pdu = snmp_pdu_create(SNMP_MSG_GET);

        oid id_oid[MAX_OID_LEN];
        size_t id_len = MAX_OID_LEN;
        read_objid(it->_oid.c_str(), id_oid, &id_len);
        snmp_add_null_var(pdu, id_oid, id_len);

        struct snmp_pdu *response = NULL;
        switch( snmp_sess_synch_response( sessp, pdu, &response ) )
        {
            case STAT_ERROR:
            {
                optionsForDeletion.push_back( *it );
            }
            break;
            case STAT_TIMEOUT: 
            {
                snmp_sess_close(sessp);
                return false;
            }
            break;
            case STAT_SUCCESS:
            {
                  if (response->variables->val_len)
                  {
                      if (it->_optionType != Asn2IntType(response->variables->type))
                      {
                          it->_optionType = Asn2IntType(response->variables->type);

                          std::lock_guard<std::mutex> locker( mtx );
                          newTypes[it->_modelOptionId] = it->_optionType;
                      }
                  }
                  else
                  {
                      optionsForDeletion.push_back( *it );
                  }
            }
            break;
        }
		
        snmp_free_pdu(response);
    }
	
    m_Options.erase( remove_if( m_Options.begin(), m_Options.end( ), [&]( const SnmpOption& o )->bool { for( auto e :optionsForDeletion ){ if( o == e ) return true; } return false;  } ), m_Options.end( ) );
    snmp_sess_close(sessp);
    return true;
}

eRetCode Origin::UpdateValues()
{
    struct snmp_session session;
    snmp_sess_init( &session );
    session.version = m_SnmpVersion;
    session.community = (u_char*)const_cast<char*>(m_Community.c_str());
    session.community_len = strlen((char*)session.community);
    session.peername = const_cast<char*>(m_IpAddr.c_str());

    void *sessp = snmp_sess_open(&session);
    if (sessp == NULL)
    {
        /* Error codes found in open calling argument */
        return RET_FAIL;
    }

    struct snmp_pdu *pdu = snmp_pdu_create(SNMP_MSG_GET);
    for (auto& opt : m_Options)
    {
        oid id_oid[MAX_OID_LEN];
        size_t id_len = MAX_OID_LEN;
        read_objid(opt._oid.c_str(), id_oid, &id_len);
        snmp_add_null_var(pdu, id_oid, id_len);
    }
	
    struct snmp_pdu *response;
    switch (snmp_sess_synch_response(sessp, pdu, &response))
    {
        case STAT_TIMEOUT:
            snmp_free_pdu(response);
            snmp_sess_close(sessp);
            return RET_TIMEOUT;
        case STAT_ERROR:
            snmp_free_pdu(response);
            snmp_sess_close(sessp);
            return RET_ERROR;
        case STAT_SUCCESS:
        {
            struct variable_list *vars = response->variables;
            for ( auto& opt : m_Options )
            {
                if( vars->val_len )
                {
                    opt._value.bigintV = *(vars->val.integer);
                }
                vars = vars->next_variable;
            }
        }
        break;
    }
	
    snmp_free_pdu( response );
    snmp_sess_close(sessp);
    return RET_SUCCESS;
}
