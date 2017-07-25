#pragma once

#include <string>
#include <vector>
#include <memory>

using namespace std;

class IJunosFacilityGroup
{
    public:
      virtual ~IJunosFacilityGroup( ) { }
      virtual string GetGroupName() = 0;
      virtual vector<string>& GetFacilityNames() = 0;
};

class JunosFacilityGroups
{
    public:
      JunosFacilityGroups( );
      vector< shared_ptr<IJunosFacilityGroup> >& GetGroups( );
      size_t GetGroupNameMaxLenght( );

    private:
      size_t m_GroupNameMaxLenght;
      vector< shared_ptr<IJunosFacilityGroup> > m_Groups;
};

