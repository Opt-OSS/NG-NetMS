#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <utility>
#include <vector>
#include <regex>
#include <iostream>

struct ParsedEntry {
    std::string name;
    int can_id{};
    std::string description;
};

class CANGlobalsParser {
public:
    CANGlobalsParser(std::string  filePath) : m_filePath(std::move(filePath)) {
    }

    bool Parse() {
        std::ifstream file(m_filePath);

        if (!file.is_open()) {
            std::cerr << "Error: Could not open file " << m_filePath << std::endl;
            return false;
        }

        std::string line;
        std::regex line_regex(R"(^([^=]+)=\d+\|(\d+)\|\d+\|\d+\|\d+\|\d+\|?(.*)?)");
        std::smatch match;
        while (std::getline(file, line)) {
            // Skip lines that don't contain variables
            if (line.empty() || line[0] == '[') {
                continue;
            }

            // Apply the regex to parse name, can_id, and description
            if (std::regex_search(line, match, line_regex)) {
                ParsedEntry entry;
                entry.name = match[1].str();
                entry.can_id = std::stoi(match[2].str());
                entry.description = match[3].str();
                m_parsedEntries.push_back(entry);
            }
        }
        file.close();
        return true;
    }

    const std::vector<ParsedEntry>& GetParsedEntries() const {
        return m_parsedEntries;
    }

private:
    std::string m_filePath;
    std::vector<ParsedEntry> m_parsedEntries;
};
