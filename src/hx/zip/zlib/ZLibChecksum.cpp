#include <hxcpp.h>
#include <hx/zip/Zip.hpp>
#include <zlib.h>

// zlib takes a null buffer as a request for the initial value, which is what
// an empty array's data is, so nothing at all leaves a checksum as it was.
// The value goes through unsigned int, not straight to uLong, which is 64
// bits on LP64 systems and would sign-extend a checksum past 2^31

int hx::zip::Zip_obj::updateAdler32(int adler, cpp::marshal::View<uint8_t> data)
{
	if (data.length == 0)
	{
		return adler;
	}

	return static_cast<int>(::adler32(static_cast<unsigned int>(adler), data.ptr, static_cast<uInt>(data.length)));
}

int hx::zip::Zip_obj::updateCrc32(int crc, cpp::marshal::View<uint8_t> data)
{
	if (data.length == 0)
	{
		return crc;
	}

	return static_cast<int>(::crc32(static_cast<unsigned int>(crc), data.ptr, static_cast<uInt>(data.length)));
}
