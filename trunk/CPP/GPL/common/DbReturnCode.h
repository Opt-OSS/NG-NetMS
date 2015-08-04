#pragma once

#include <string>

using namespace std;

class DbReturnCode
{
    public:
        enum class Code
        {
            OK,
            ERROR,
            QUERY_ERROR
        };

        DbReturnCode( Code Code ):
        m_ReturnCode( Code )
        {

        }

        DbReturnCode( Code Code, string Details ):
        m_Details( Details ),
        m_ReturnCode( Code )

        {

        }

        bool IsOk()
        {
            return Code::OK == m_ReturnCode;
        }

        bool IsFail()
        {
            return !IsOk();
        }

        Code GetReturnCode()
        {
            return m_ReturnCode;
        }

        string GetDetails()
        {
            return m_Details;
        }

    private:
        string     m_Details;
        Code 	   m_ReturnCode;
};
