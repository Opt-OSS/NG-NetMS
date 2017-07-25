#pragma once

#include "EventType.h"
#include <string>
#include <memory>
#include <vector>

using namespace std;

class RulesFileParser
{
    public:
      enum class ResultCodes
      {
          RESULT_CODE_OK,
          RESULT_CODE_CANT_OPEN_FILE,
          RESULT_CODE_PARSE_ERROR
      };

      typedef vector< pair<string, shared_ptr<EventType> > > EventTypeList;

    public:
        static ResultCodes parse( string Name );
        static EventTypeList& GetEventTypeMap( );

    public:
        static bool m_ParceError;
};

