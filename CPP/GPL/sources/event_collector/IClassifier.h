#pragma once

#include <string>

#include "Event.h"

using namespace std;

class ClassifierListener
{
public:
	class ClassifierEvent
	{
	public:
		ClassifierEvent(Event& event, string ActionScript, bool Discard):
			m_Event(event), m_ActionScript(ActionScript), m_Discard(Discard)
		{
		}

		const Event& GetEvent() const { return m_Event; }

		const string& GetActionScript() const { return m_ActionScript; }

		bool GetDiscard() { return m_Discard; }

	private:
		Event m_Event;
		string m_ActionScript;
		bool m_Discard;
	};

	virtual ~ClassifierListener() {}
	virtual void Notify(ClassifierEvent& event) = 0;
};

class IClassifier
{
public:
	enum class ResultCodes
	{
		RESULT_CODE_OK,
		RESULT_CODE_CANT_OPEN_FILE,
		RESULT_CODE_PARSE_ERROR
	};

public:
	virtual ~IClassifier() {}
	virtual ResultCodes Initialize(string RuleFile) = 0;
	virtual bool Classify(Event& event) = 0;
	virtual void RegisterListener(ClassifierListener& Listener) = 0;
	virtual void UnregisterListener(ClassifierListener& Listener) = 0;
};
