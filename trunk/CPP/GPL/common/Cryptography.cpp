#include "Cryptography.h"
#include <iostream>
#include <sstream>
#include <iomanip>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-function"
#include <crypto++/modes.h>
#include <crypto++/aes.h>
#include <crypto++/des.h>
#include <crypto++/osrng.h>
#include <crypto++/hex.h>
#include <crypto++/camellia.h>
#include <crypto++/filters.h>
#include <crypto++/base64.h>
#include <memory>

using namespace CryptoPP;

static byte key[ Camellia::DEFAULT_KEYLENGTH ]; // TODO: Generate in during compile time
static byte iv[ Camellia::BLOCKSIZE ];

string Cryptography::ConfigFileEncrypt( string Text )
{
    try
    {
        CBC_Mode< Camellia >::Encryption e;
        e.SetKeyWithIV(key, sizeof( key ), iv);
        string encriptedText;
        StringSource(Text, true, new StreamTransformationFilter( e, new StringSink(encriptedText)  ) );

        stringstream encryptedHex;
        encryptedHex << setbase( 16 );
        for( unsigned char octet : encriptedText  )
        {
            unsigned int code = static_cast<unsigned int>( octet );
            encryptedHex.fill( '0');
            encryptedHex.width( 2 );
            encryptedHex << (code & 0xff);
        }

        return encryptedHex.str();
    }
    catch( const CryptoPP::Exception& e )
    {
        return Text;
    }
}

string Cryptography::ConfigFileDecrypt( string EncryptedHex )
{
    try
    {
        string encriptedText;
        for( size_t i = 0; i < EncryptedHex.length(); i+=2 )
        {
            stringstream ss;
            ss << EncryptedHex[i] << EncryptedHex[i+1];
            ss << setbase( 16 );
            unsigned int code;
            ss >> code;

            encriptedText += static_cast<unsigned char>( code );
        }

        byte iv[ CryptoPP::AES::BLOCKSIZE ];
        memset( iv, 0x00, CryptoPP::AES::BLOCKSIZE );

        string decryptedtext;
        CBC_Mode< Camellia >::Decryption e;
        e.SetKeyWithIV(key, sizeof( key ), iv);
        StringSource(encriptedText, true, new StreamTransformationFilter( e, new StringSink(decryptedtext)  ) );

        return decryptedtext;
    }
    catch( const CryptoPP::Exception& e )
    {
        return EncryptedHex;
    }
}

static void CreateKeyFromString( SecByteBlock &Key, string StrKey )
{
    StrKey.resize ( 2*Key.size(), '0' );

    for( size_t i = 0; i < Key.size(); ++i )
    {
        string hexStr;
        hexStr += StrKey[ 2 * i ];
        hexStr += StrKey[ 2 * i + 1 ];

        unsigned int octet;
        std::stringstream ss;
        ss << std::hex << hexStr;
        ss >> octet;

        Key.BytePtr( )[i] = static_cast<byte>( octet );
    }
}

string Cryptography::DatabaseEncrypt( string Key, string Text )
{
    size_t desizedLenght = Text.length() + 8 - Text.length() % 8;
    Text.resize ( desizedLenght, ' ' );

    try
    {
        SecByteBlock key( DES_EDE3::DEFAULT_KEYLENGTH );
        CreateKeyFromString( key, Key );

        ECB_Mode< DES_EDE3 >::Encryption e;
        e.SetKey( key, key.size() );

        string Cipher;
        StringSource(Text, true, new StreamTransformationFilter( e, new Base64Encoder( new StringSink(Cipher) ), BlockPaddingSchemeDef::NO_PADDING  ) );
        return  Cipher;
    }
    catch( CryptoPP::Exception& e )
    {
        return  string( "" );
    }
}

string Cryptography::DatabaseDecrypt( string Key, string EncryptedText )
{
    try
    {
        SecByteBlock key( DES_EDE3::DEFAULT_KEYLENGTH );
        CreateKeyFromString( key, Key );

        ECB_Mode< DES_EDE3 >::Decryption d;
        d.SetKey( key, key.size() );

        string Recovered;
        CryptoPP::StringSource decryptor(EncryptedText, true, new CryptoPP::Base64Decoder( new CryptoPP::StreamTransformationFilter(d,
                        new CryptoPP::StringSink(Recovered), BlockPaddingSchemeDef::NO_PADDING ) ) );

        return Recovered;
    }
    catch( CryptoPP::Exception& e )
    {
        return  string( "" );
    }
}

#pragma GCC diagnostic pop
