#pragma once

#include <hxcpp.h>
#include <hx/zip/Compress.hpp>
#include <zlib-ng.h>

namespace hx
{
	namespace zip
	{
		namespace zlib
		{
			struct ZLibCompress final : Compress_obj
			{
				zng_stream* handle;
				int flush;

				ZLibCompress(zng_stream* inHandle);

				Result execute(cpp::marshal::View<uint8_t> src, cpp::marshal::View<uint8_t> dst) override;
				void setFlushMode(Flush mode) override;
				int getBounds(int length) override;
				void close() override;
			};
		}
	}
}