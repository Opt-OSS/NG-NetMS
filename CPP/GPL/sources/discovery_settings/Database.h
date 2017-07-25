#pragma once

#include "DbSettings.h"
#include "DbReturnCode.h"
#include "DiscoverySettings.h"

class Database
{
    public:
        void Connect( const DbSettings& Settings );
        DbReturnCode SetDiscoverySettings( DiscoverySettings& Settings );
        DbReturnCode GetDiscoverySettings( DiscoverySettings& Settings );

        DbReturnCode GetGeneralEncryptedSetting( string Name, string& Value );
        DbReturnCode SetGeneralEncryptedSetting( string Name, string Value  );
    private:
        DbReturnCode IsGeneralSettingExist( string Name, bool &Exist );
        DbReturnCode GetDatabaseKey( string &Key );

    private:
        DbSettings m_DbConnectionData;
};
