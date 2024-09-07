#pragma once

#include <string>

using namespace std;

class Cryptography
{
public:
	static string ConfigFileEncrypt(string Text);
	static string ConfigFileDecrypt(string EncryptedText);
	static string DatabaseEncrypt(string Key, string Text);
	static string DatabaseDecrypt(string Key, string EncryptedText);
};
