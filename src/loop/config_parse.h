#ifndef NBODY_CONFIG_PARSE_H
#define NBODY_CONFIG_PARSE_H

#include <fstream>
#include <string>
#include <unordered_map>

inline bool ParseBoolean(const std::string& str) {
    return str == "true" || str == "1";
}

inline std::string Trim(const std::string& s) {
    const char* whitespace = " \t\n\r\f\v";
    size_t start = s.find_first_not_of(whitespace);

    if (start == std::string::npos) return "";
    size_t end = s.find_last_not_of(whitespace);

    return s.substr(start, end - start + 1);
}

std::unordered_map<std::string, std::string> ParseINI(const std::string& filepath) {
    std::unordered_map<std::string, std::string> config;
    std::ifstream file(filepath);
    std::string line;
    std::string current_section = "";

    while (std::getline(file, line)) {
        auto comment_pos = line.find('#');

        if (comment_pos != std::string::npos) line = line.substr(0, comment_pos);

        line = Trim(line);
        if (line.empty()) continue;

        if (line.front() == '[' && line.back() == ']') {
            current_section = line.substr(1, line.size() - 2);
        } else {

            auto eq_pos = line.find('=');
            if (eq_pos != std::string::npos) {

                std::string key = Trim(line.substr(0, eq_pos));
                std::string val = Trim(line.substr(eq_pos + 1));

                if (val.front() == '"' && val.back() == '"') val = val.substr(1, val.size() - 2);

                std::string full_key = current_section.empty() ? key : current_section + "." + key;
                config[full_key] = val;
            }
        }
    }
    return config;
}

#endif //NBODY_CONFIG_PARSE_H
