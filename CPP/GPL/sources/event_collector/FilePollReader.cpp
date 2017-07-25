#include "FilePollReader.h"

#include <iostream>

using namespace std;

FilePollReader::FilePollReader():
m_Handlers(nullptr),
m_InotifyFd(0),
m_WatchDescriptor(0)
{

}

void FilePollReader::SetFileName(const string& FileName)
{
	m_FileName = FileName;

	std::size_t position = m_FileName.find_last_of('/');
	if(string::npos == position )
	{
		m_BaseFolder = "./";
	}
	else
	{
		m_BaseFolder = m_FileName.substr(0, position+1);
	}
}

bool FilePollReader::Run( )
{
	m_InotifyFd = inotify_init();
	m_WatchDescriptor = inotify_add_watch( m_InotifyFd, m_BaseFolder.c_str(), IN_ALL_EVENTS );
	if (m_WatchDescriptor == -1)
	{
		return false;
	}

	m_File.open(m_FileName.c_str(), ifstream::in);
	if(m_File.is_open())
	{
		ReadData();
	}

	for (;;)
	{
		const int buffetLen = (10 * (sizeof(struct inotify_event) + NAME_MAX + 1));
		shared_ptr<char> buffer( new char[buffetLen] );

		ssize_t numRead = read( m_InotifyFd, buffer.get(), buffetLen );
		if (numRead <= 0)
		{
			cout << "Error" << endl;
			return true;
		}

		for (char *p = buffer.get(); p < buffer.get() + numRead; )
		{
			struct inotify_event *event = (struct inotify_event *) p;
			p += sizeof(struct inotify_event) + event->len;

			string filename =  m_FileName;
			std::size_t position = m_FileName.find_last_of('/');
			if(string::npos != position )
			{
				filename = m_FileName.substr(position+1 );
			}

			string eventFilename = event->name;
			if( eventFilename != filename )
			{
				continue;
			}

			// Process events
			if (event->mask & IN_CLOSE_WRITE)
			{
				m_File.close();
			}

			if (event->mask & IN_MODIFY)
			{
				ReadData();
			}

			if (event->mask & IN_CREATE)
			{
				m_File.open(m_FileName.c_str(), ifstream::in);
			}
		}
	}

	return true;
}

void FilePollReader::Stop()
{
	if( m_InotifyFd && m_WatchDescriptor)
	{
		inotify_rm_watch(m_InotifyFd, m_WatchDescriptor);
		close(m_InotifyFd);
	}
}

void FilePollReader::RegisterHandlers(IFilePollReaderHandler* Handlers)
{
	m_Handlers = Handlers;
}

void FilePollReader::ReadData()
{
	for(;;)
	{
		string line;
		getline( m_File, line );
		if( m_File.eof( ) )
		{
			m_File.clear();
			break;
		}
		else
		{
			if(m_Handlers)
			{
				m_Handlers->OnReadLine(line);
			}
		}
	}
}

