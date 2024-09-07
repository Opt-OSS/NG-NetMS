#pragma once

#include <set>

using namespace std;

template<typename ListenerType, typename EventType> class Notifier
{
public:
	void Register(ListenerType& Listener) { mSubscribers.insert(&Listener); }

	void Unregister(ListenerType& Listener) { mSubscribers.erase(&Listener); }

	void Notify(EventType Event)
	{
		for (auto it = mSubscribers.begin(); it != mSubscribers.end(); ++it)
		{
			ListenerType* listener = *it;
			listener->Notify(Event);
		}
	}

private:
	set<ListenerType*> mSubscribers;
};
