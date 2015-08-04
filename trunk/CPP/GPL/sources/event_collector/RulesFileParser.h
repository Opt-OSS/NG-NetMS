#pragma once

#include "EventType.h"
#include <string>
#include <memory>
#include <map>

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

      typedef map<string, shared_ptr<EventType> > EventTypeMap;

    public:
        static ResultCodes parse( string Name );
        static EventTypeMap& GetEventTypeMap( );

    public:
        static bool m_ParceError;
};

