#pragma once

#include <sys/inotify.h>
#include <limits.h>
#include <unistd.h>
#include <string>
#include <iostream>
#include <fstream>
#include <memory>

// Logger
#include "Logger.h"

class IFilePollReaderHandler
{
public:
	virtual void OnReadLine( const std::string& Line ) = 0;
};

class FilePollReader
{
public:
	FilePollReader();
	void SetFileName(const std::string& FileName);
    void SetLogger(std::shared_ptr<Logger>        Logger);
	bool Run( );
	void Stop();
	void RegisterHandlers(IFilePollReaderHandler* Handlers);

private:
	bool  ReadData();

private:
	std::shared_ptr<Logger>        m_Logger;
	IFilePollReaderHandler* m_Handlers;
	std::string		m_FileName;
	std::string		m_BaseFolder;
	std::ifstream	m_File;
	int 			m_InotifyFd;
	int				m_WatchDescriptor;
	size_t bytes_read = 0;
};

