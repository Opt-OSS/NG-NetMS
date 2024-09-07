#pragma once

#include <string>
#include <memory>
#include "EventType.h"
#include "Notifier.h"
#include "IClassifier.h"

using namespace std;

class Classifier: public IClassifier
{
    public:
        Classifier( bool Debug );
        virtual ~Classifier();
        IClassifier::ResultCodes Initialize( string RuleFile );
        bool Classify( Event& event );
        void RegisterListener( ClassifierListener &Listener );
        void UnregisterListener( ClassifierListener &Listener );

    private:
        bool m_Debug;
        Notifier<ClassifierListener, ClassifierListener::ClassifierEvent&> m_Notifier;
};
