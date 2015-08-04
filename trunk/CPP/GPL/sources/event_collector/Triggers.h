#pragma once

#include <string>
#include "Event.h"

using namespace std;

class Triggers
{
    public:
        void Execute( const string& ActionScript, const Event& event );
};

