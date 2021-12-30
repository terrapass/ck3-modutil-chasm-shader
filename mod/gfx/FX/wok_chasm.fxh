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
		float WoKSampleChasmValuePolar(float2 Center, float r, float phi)
		{
			float3 IgnoredDetailDiffuse;
			float3 IgnoredDetailNormal;

			float4 DetailMaterial;

			const float2 Offset = float2(r*cos(phi), r*sin(phi));

			CalculateDetails( Center + Offset, IgnoredDetailDiffuse, IgnoredDetailNormal, DetailMaterial );

			return DetailMaterial.r;
		}

		float WoKSampleChasmValue(float2 WorldSpacePosXZ)
		{
			// TODO: Currently this does a lot of extra work.
			//       Optimize by rewriting from scratch to just obtain the red channel from map properties texture.

			static const float2 SYMMETRY_CENTER = float2(2250.0, 1050.0);

			const float2 ToSymmetryCenter = SYMMETRY_CENTER - WorldSpacePosXZ;

			// Polar coords
			const float r   = length(ToSymmetryCenter);
			const float phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x);

			return WoKSampleChasmValuePolar(SYMMETRY_CENTER, r, phi);
		}
	]]
}
