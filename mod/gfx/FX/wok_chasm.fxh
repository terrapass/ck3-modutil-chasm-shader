Includes = {}

Code
[[
	// TODO
]]

VertexShader
{
	Code
	[[
		#define WOK_EPSILON 0.00001
	]]
}

PixelShader
{
	Code
	[[
		float WoKSampleChasmValue(float2 WorldSpacePosXZ)
		{
			// TODO: Currently this does a lot of extra work.
			//       Optimize by rewriting from scratch to just obtain the red channel from map properties texture.

			float3 IgnoredDetailDiffuse;
			float3 IgnoredDetailNormal;

			float4 DetailMaterial;
			CalculateDetails( WorldSpacePosXZ, IgnoredDetailDiffuse, IgnoredDetailNormal, DetailMaterial );

			return DetailMaterial.r;
		}
	]]
}
