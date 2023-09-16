includes = {
	#"gh_constants.fxh"
}

Code [[
	//
	// Macros
	//

	#ifndef PDX_OPENGL
		#define GH_LOOP [loop]
		#define GH_UNROLL [unroll]
		#define GH_UNROLL_EXACT(ITERATIONS_COUNT) [unroll(ITERATIONS_COUNT)]
	#else
		#define GH_LOOP
		#define GH_UNROLL
		#define GH_UNROLL_EXACT(ITERATIONS_COUNT)
	#endif

	#ifndef PDX_OPENGL
		#define GH_PdxTex2DArrayLoad(samp,uvi,lod) (samp)._Texture.Load( int4((uvi), (lod)) )
	#else
		#define GH_PdxTex2DArrayLoad texelFetch
	#endif

	//
	// Interface
	//

	int GH_DecodeIntFromRgba(float4 Rgba)
	{
		static const float THRESHOLD = 0.5f;

		// Decode Rgba into an integer between 0 and 15 inclusive
		return (int(step(THRESHOLD, Rgba.r)) << 0)
				| (int(step(THRESHOLD, Rgba.g)) << 1)
				| (int(step(THRESHOLD, Rgba.b)) << 2)
				| (int(step(THRESHOLD, Rgba.a)) << 3);
	}

	int GH_DecodeIntFromRgb(float3 Rgb)
	{
		// Decode Rgb into an integer between 0 and 7 inclusive
		return GH_DecodeIntFromRgba(float4(Rgb, 0.0f));
	}
]]
