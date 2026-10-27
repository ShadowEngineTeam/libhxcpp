#include <hxcpp.h>
#include <hx/zip/Zip.hpp>
#include <zlib-ng.h>

// zlib takes a null buffer as a request for the initial value, which is what
// an empty array's data is, so nothing at all leaves a checksum as it was.
// The value goes through uint32_t so a checksum past 2^31 does not sign-extend

int hx::zip::Zip_obj::updateAdler32(int adler, cpp::marshal::View<uint8_t> data)
{
	if (data.length == 0)
	{
		return adler;
	}

	return static_cast<int>(::zng_adler32_z(static_cast<uint32_t>(adler), data.ptr, static_cast<size_t>(data.length)));
}

int hx::zip::Zip_obj::updateCrc32(int crc, cpp::marshal::View<uint8_t> data)
{
	if (data.length == 0)
	{
		return crc;
	}

	return static_cast<int>(::zng_crc32_z(static_cast<uint32_t>(crc), data.ptr, static_cast<size_t>(data.length)));
}
