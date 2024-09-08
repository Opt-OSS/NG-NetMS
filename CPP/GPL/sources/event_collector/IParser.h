#pragma once

#include <string>
#include "Notifier.h"
#include "Event.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <vector>
#include <iostream>
#include <sstream>
#include <chrono>
#include <vector>
#include <iomanip>

using namespace std;

class ParserListener
{
    public:
        virtual ~ParserListener() { }
        virtual void Notify( Event& event ) = 0;
};

class IParser
{
    public:
        virtual ~IParser(){}
        virtual bool Parse( string Message, bool HasSourceIp, string SourceIP ) = 0;
        virtual bool ProcessEndOfData( ) = 0;
        virtual void SourceAttached( string IpAddress ) = 0;
        virtual void SourceDetached( string IpAddress ) = 0;
        virtual void RegisterListener( ParserListener &Listener ) = 0;
        virtual void UnregisterListener( ParserListener &Listener ) = 0;

};
