#pragma once

#ifndef HXCPP_H
#include <hxcpp.h>
#endif

#include <cpp/marshal/View.hpp>

HX_DECLARE_CLASS2(hx, zip, Zip)

namespace hx
{
	namespace zip
	{
		enum Flush {
			None,
			Sync,
			Full,
			Finish,
			Block
		};

		struct Result final {
			const bool done;
			const int read;
			const int write;

			Result(int inDone, int inRead, int inWrite);
		};

		struct Zip_obj : hx::Object
		{
			virtual Result execute(cpp::marshal::View<uint8_t> src, cpp::marshal::View<uint8_t> dst) = 0;
			virtual void setFlushMode(Flush mode) = 0;
			virtual void close() = 0;

			// The stream's adler32: the checksum of the data it has taken in or
			// given out, or, from an inflate stream that asks for a preset
			// dictionary, the dictionary's id
			virtual int getAdler32() = 0;

			// A checksum carried on over data, as zlib's adler32 and crc32 do
			static int updateAdler32(int adler, cpp::marshal::View<uint8_t> data);
			static int updateCrc32(int crc, cpp::marshal::View<uint8_t> data);
		};
	}
}
