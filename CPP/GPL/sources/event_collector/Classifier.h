#pragma once

#include <string>
#include <memory>
#include "EventType.h"
#include "Notifier.h"
#include "IClassifier.h"
#include "EventDecorator.hpp"

using namespace std;

class Classifier: public IClassifier
{
    public:
        Classifier( bool Debug, std::shared_ptr<EventDecorator>& decorator);
        ~Classifier();
        IClassifier::ResultCodes Initialize( string RuleFile ) override;
        bool Classify( Event& event ) override;
        void RegisterListener( ClassifierListener &Listener ) override;
        void UnregisterListener( ClassifierListener &Listener ) override;

    private:
        bool m_Debug;
        Notifier<ClassifierListener, ClassifierListener::ClassifierEvent&> m_Notifier;
        std::shared_ptr<EventDecorator> m_decorator;
};
