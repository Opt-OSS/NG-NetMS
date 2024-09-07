#include "SnmpObserver.h"

int main(int argc, char** argv)
{
	return SnmpObserver::GetInstance().Execute(argc, argv);
}
