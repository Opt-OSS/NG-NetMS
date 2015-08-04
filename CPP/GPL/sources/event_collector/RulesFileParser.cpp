#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vector>
#include <iostream>

extern "C"
{
    #include <pcre.h>
}

#include "RulesFileParser.h"
#include "Event.h"

using namespace std;

//static
bool RulesFileParser::m_ParceError = false;

struct Value;

int yyparse(void);

static RulesFileParser::EventTypeMap newTypes;

class EventTypeBuilder
{
    public:
        static EventTypeBuilder& GetInstance( )
        {
            static EventTypeBuilder builder;
            return builder;
        }

        void Reset( )
        {
            m_Name           = "";
            m_Condition      = nullptr;
            m_Protocol       = "";
            m_Severity       = 0;
            m_Discard        = false;
            m_Action         = "";
            m_EventType      = "";
            m_NameCount      = 0;
            m_ConditionCount = 0;
            m_ProtocolCount  = 0;
            m_SeverityCount  = 0;
            m_DiscardCount   = 0;
            m_ActionCount    = 0;
        }

        void SetName( string& Name )
        {
            m_Name = Name;
            m_NameCount++;
        }

        bool SetCondition( Operator* Condition )
        {
            m_Condition = Condition;
            return 0 == m_ConditionCount++;
        }

        bool SetProtocol( string Protocol )
        {
            m_Protocol = Protocol;
            return 0 == m_ProtocolCount++;
        }

        bool SetSeverity( int Severity )
        {
            m_Severity = Severity;
            return 0 == m_SeverityCount++;
        }

        bool SetDiscard( bool Discard )
        {
            m_Discard = Discard;
            return 0 == m_DiscardCount++;
        }

        bool SetAction( string Action )
        {
            m_Action = Action;
            return 0 == m_ActionCount++;
        }

        void SetEventType( string EventType )
        {
            m_EventType = EventType;
        }

        bool Validate( )
        {
           if( m_ConditionCount <= 1 &&
               m_ProtocolCount <= 1 &&
               m_SeverityCount <= 1 &&
               m_DiscardCount <= 1 &&
               m_ActionCount <= 1 &&
               nullptr != m_Condition )
             {
                return true;
             }

             return false;
        }

        shared_ptr<EventType> BuildEventType( string eventType )
        {
            EventProtocol ep =EventProtocol::SYSLOG;
            if( "snmp" == m_Protocol )
            {
                ep = EventProtocol::SNMP;
            }

            EventType* event = new EventType( eventType, ep, m_Condition, m_Severity, m_Action, m_Discard );
            Reset( );
            return shared_ptr<EventType>( event );
        }

    private:
        EventTypeBuilder( ):
        m_Condition( nullptr ),
        m_Severity( 0 ),
        m_Discard( false ),
        m_NameCount( 0 ),
        m_ConditionCount( 0 ),
        m_ProtocolCount( 0 ),
        m_SeverityCount( 0 ),
        m_DiscardCount( 0 ),
        m_ActionCount( 0 )
        {

        }

    private:
        string          m_Name;
        const Operator* m_Condition;
        string          m_Protocol;
        int             m_Severity;
        bool            m_Discard;
        string          m_Action;
        string          m_EventType;

        int             m_NameCount;
        int             m_ConditionCount;
        int             m_ProtocolCount;
        int             m_SeverityCount;
        int             m_DiscardCount;
        int             m_ActionCount;
};

RulesFileParser::EventTypeMap& RulesFileParser::GetEventTypeMap( )
{
    return newTypes;
}

RulesFileParser::ResultCodes RulesFileParser::parse( string Name )
{
    extern FILE* yyin;
    yyin = fopen( Name.c_str(), "r" );
    if( !yyin )
    {
        return ResultCodes::RESULT_CODE_CANT_OPEN_FILE;
    }

    if( yyparse() )
    {
	newTypes.clear();
	return ResultCodes::RESULT_CODE_PARSE_ERROR;
    }

    if( RulesFileParser::m_ParceError )
    {
        return ResultCodes::RESULT_CODE_PARSE_ERROR;
    }

    return ResultCodes::RESULT_CODE_OK;
}

int storeCondition(void const* cond)
{
    return EventTypeBuilder::GetInstance().SetCondition( static_cast<Operator*>( const_cast<void *>( cond ) ) );
}

int storeSeverity(const char* sev)
{
    return EventTypeBuilder::GetInstance().SetSeverity( atoi( sev ) );
}

int storeProtocol(const char* proto)
{
    return EventTypeBuilder::GetInstance().SetProtocol( proto );
}

int storeAction(const char* action)
{
    return EventTypeBuilder::GetInstance().SetAction( action );
}

int storeDiscard(void)
{
    return EventTypeBuilder::GetInstance().SetDiscard( true );
}

int storeEvent( const char* event )
{
    EventTypeBuilder::GetInstance().SetEventType( event );

    if( !EventTypeBuilder::GetInstance().Validate( ) )
    {
        RulesFileParser::m_ParceError = true;
        return 0;
    }

    shared_ptr<EventType> eventType = EventTypeBuilder::GetInstance().BuildEventType( event );
    newTypes[ eventType->getName( ) ] = eventType;
    return 1;
}

struct Value
{
    ~Value();
    enum
    {
	VAL_VAR,
	VAL_STRING
    } type;

    union
    {
	const char* str;
	const char* var;
    } v;
};

Value::~Value()
{
    switch(type)
    {
        case Value::VAL_VAR:
            free((void*)v.str);
            break;
        case Value::VAL_STRING:
            free((void*)v.var);
            break;
        default:
            break;
    }
}

class OperatorAnd : public Operator
{
    public:
        OperatorAnd(const Operator* l, const Operator* r) : Operator( r,l )
        {

        }

        virtual int Calculate(const Event* ev) const
        {
            return m_Left->Calculate(ev) && m_Right->Calculate(ev);
        }

        virtual string GetName( ) const
        {
            return "And";
        }
};

class OperatorOr : public Operator
{
    public:
        OperatorOr(const Operator* l, const Operator* r) : Operator( r,l )
        {

        }

        virtual int Calculate(const Event* ev) const
        {
            return m_Left->Calculate(ev) || m_Right->Calculate(ev);
        }

        virtual string GetName( ) const
        {
            return "Or";
        }
};

class OperatorNot : public Operator
{
    public:
        OperatorNot(const Operator* l) : Operator( l )
        {

        }

        virtual int Calculate( const Event* ev ) const
        {
            return m_Left->Calculate(ev) == 0;
        }

        virtual string GetName( ) const
        {
            return "Not";
        }
};

class OperatorMatch : public Operator
{
    public:
        OperatorMatch(const Value* _val, const Value* _regex) :
        Operator(0,0), val(_val), regex(_regex)
        {
            const char *error;
            int erroffset;

            re = pcre_compile( regex->v.str, 0, &error, &erroffset, NULL );
            if (re == NULL)
            {
   //             croak("error in reg expr \"%s\" around pos %d\n", erroffset, error);
            }
        }

        ~OperatorMatch()
        {
            delete val;
            delete regex;
        }

        const string getField(const Event& ev, const string& Name ) const
        {
            if( "$msg" == Name )
            {
                return ev.getDescr();
            }

            if( "$origin" == Name )
            {
                return ev.getOrigin();
            }

            if( "$facility" == Name )
            {
                return ev.getFacility();
            }

            if( "$timestamp" == Name )
            {
                return ev.getTs();
            }

            if( "$code" == Name )
            {
                return ev.getCode();
            }

            return string( "" );
        }

        virtual int Calculate(const Event* ev) const
        {
            const char* str = getField( *ev, val->v.var).c_str();
            int rc = pcre_exec( re, NULL, str, strlen(str), 0, 0, NULL, 0 );
            if (rc < 0)
            {
                if(rc != PCRE_ERROR_NOMATCH)
                {
                  //  croak("Matching \"%s\":error %d\n", getField( *ev, val->v.var).c_str(), rc);
                }

                return 0;
            }

            return 1;
        }

        virtual string GetName( ) const
        {
            return "Match";
        }

    private:
        const Value* val;
        const Value* regex;
        pcre *re;
};

Operator* makeAndOp( void* a, void* b )
{
    return new OperatorAnd( static_cast<Operator*>(a),static_cast<Operator*>(b));
}

Operator* makeOrOp( void* a, void* b )
{
    return new OperatorOr(static_cast<Operator*>(a),static_cast<Operator*>(b));
}

Operator* makeNotOp( void* a )
{
    return new OperatorNot(static_cast<Operator*>(a));
}

Operator* makeMatchOp( void* a, void* b )
{
   return new OperatorMatch(static_cast<Value*>(a),static_cast<Value*>(b));
}

static bool validateField( const string& FieldName ) // Refactor it !!!
{
    vector<string> fieldNames;
    fieldNames.push_back( "$msg" );
    fieldNames.push_back( "$origin" );
    fieldNames.push_back( "$facility" );
    fieldNames.push_back( "$code" );
    fieldNames.push_back( "$timestamp" );

    for( const auto fieldName : fieldNames )
    {
        if( fieldName == FieldName )
        {
            return true;
        }
    }

    return false;
}

Value* makeVar( const char* name )
{
    Value* val = new Value;
    val->type = Value::VAL_VAR;
    val->v.var = name;

    if( !validateField( name ) )
    {
 	//croak("error: invalid field name \"%s\"\n", name);
    }

    return val;
}

Value* makeStr(const char* str)
{
    Value* val = new Value;
    val->type = Value::VAL_STRING;
    val->v.str = str;
    return val;
}
