#include "FilePollReader.h"

#include <iostream>
#include <sys/stat.h>
#include <sstream>

using namespace std;

FilePollReader::FilePollReader() :
		m_Handlers(nullptr), m_InotifyFd(0), m_WatchDescriptor(0) {

}
void FilePollReader::SetLogger(std::shared_ptr<Logger> Logger) {
	m_Logger = Logger;
}
;

void FilePollReader::SetFileName(const string& FileName) {
	m_FileName = FileName;

	std::size_t position = m_FileName.find_last_of('/');
	if (string::npos == position) {
		m_BaseFolder = "./";
	} else {
		m_BaseFolder = m_FileName.substr(0, position + 1);
	}
}

bool FilePollReader::Run() {
	bytes_read = 0;
	m_InotifyFd = inotify_init();
	m_Logger->LogDebug("watching "+m_FileName+" in folder " + m_BaseFolder);
	//watch any changes in direcotory where file is located
	m_WatchDescriptor = inotify_add_watch(m_InotifyFd, m_BaseFolder.c_str(),
	IN_ALL_EVENTS);
	if (m_WatchDescriptor == -1) {
		m_Logger->LogDebug(": Bad WatchDescriptor ");
		return false;
	}
	//if file exists, read all events
	m_File.open(m_FileName.c_str(), ifstream::in);
	if (m_File.is_open()) {

		ReadData();
	}
	//waiting for inotify
	for (;;) {
		const int buffetLen = (10
				* (sizeof(struct inotify_event) + NAME_MAX + 1));
		shared_ptr<char> buffer(new char[buffetLen]);

		ssize_t numRead = read(m_InotifyFd, buffer.get(), buffetLen);
		if (numRead <= 0) {
			cout << "Error" << endl;
			return true;
		}

		for (char *p = buffer.get(); p < buffer.get() + numRead;) {
			struct inotify_event *event = (struct inotify_event *) p;
			p += sizeof(struct inotify_event) + event->len;

			string filename = m_FileName;
			std::size_t position = m_FileName.find_last_of('/');
			if (string::npos != position) {
				filename = m_FileName.substr(position + 1);
			}

			string eventFilename = event->name;

			if (eventFilename != filename) {
				continue;
			}

			//				m_Logger->LogDebug(": Reading Data");
			if (!m_File.is_open()) {
				m_Logger->LogError("Tried to read from closed stream");
				return false; //try to reopen file
			}
			// Process events
			if (event->mask
					& (IN_DELETE | IN_MOVE_SELF | IN_MOVED_FROM | IN_DELETE_SELF)) {
				m_Logger->LogDebug(": Closing file " + m_FileName);
				m_File.close();
				//restart polling in case file moved| deleted
				return false;
			}

			if (event->mask & IN_MODIFY) {

				if (!ReadData()) {

					struct stat stat_buf;
					int rc = stat(m_FileName.c_str(), &stat_buf);

					if (!rc && stat_buf.st_size < bytes_read) {
						m_Logger->LogDebug(
								" File size " + std::to_string(stat_buf.st_size)
										+ " less than current stream position "
										+ std::to_string(bytes_read)
										+ ",possibly truncated, try to reopen file");
						m_File.close();
						return false;
					}
				}
			}

			if (event->mask & IN_CREATE) {
				m_Logger->LogDebug(": Opening file " + m_FileName);
				m_File.open(m_FileName.c_str(), ifstream::in);
			}
		}
	}

	return true;
}

void FilePollReader::Stop() {
	if (m_InotifyFd && m_WatchDescriptor) {
		inotify_rm_watch(m_InotifyFd, m_WatchDescriptor);
		close(m_InotifyFd);
	}
}

void FilePollReader::RegisterHandlers(IFilePollReaderHandler* Handlers) {
	m_Handlers = Handlers;
}

bool FilePollReader::ReadData() {
	if (!m_File.is_open()) {

		return false; //reopen file
	}
	bool has_bytes = false;
	for (;;) {
		string line;
		getline(m_File, line);
		int this_line_size = line.size(); //gcount is not affected by getline()
		has_bytes = has_bytes || this_line_size;
		bytes_read += this_line_size ? this_line_size + 1 : 0; //+1 for new-line character
//		m_Logger->LogDebug(
//				"read  bytes:" + std::to_string(this_line_size) + " up to "
//						+ std::to_string(bytes_read));

		if (m_File.eof()) {
			m_File.clear();
			break;
		} else {
			if (m_Handlers) {
				m_Handlers->OnReadLine(line);
			}
		}
	}
	return has_bytes;
}

