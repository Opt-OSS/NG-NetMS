#pragma once

#include <memory>
#include <string>

#include "EventType.h"
#include "IClassifier.h"
#include "Notifier.h"

using namespace std;

class Classifier : public IClassifier
{
public:
	Classifier(bool Debug);
	virtual ~Classifier();
	IClassifier::ResultCodes Initialize(string RuleFile) override;
	bool Classify(Event &event) override;
	void RegisterListener(ClassifierListener &Listener) override;
	void UnregisterListener(ClassifierListener &Listener) override;

private:
	bool m_Debug;
	Notifier<ClassifierListener, ClassifierListener::ClassifierEvent &> m_Notifier;
};
