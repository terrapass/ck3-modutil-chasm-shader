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
		static const float2 SYMMETRY_CENTER = float2(2250.0, 1050.0);
		static const float  SYMMETRY_RANGE  = 120.0;

		float WoKSampleChasmValuePolar(float2 Center, float SymmetryRange, float r, float phi)
		{
			static const float PI_BY_4 = PI/4;

			float3 IgnoredDetailDiffuse;
			float3 IgnoredDetailNormal;

			float4 DetailMaterial;

			const float RemainderPhi = mod(phi, PI_BY_4);
			const float SymmetryPhi  = lerp(RemainderPhi, PI_BY_4 - RemainderPhi, step(PI_BY_4, mod(phi, 2*PI_BY_4)));

			const float CorrectedPhi = lerp(SymmetryPhi, phi, step(SymmetryRange, r));

			const float2 Offset = float2(r*cos(CorrectedPhi), r*sin(CorrectedPhi));

			CalculateDetails( Center - Offset, IgnoredDetailDiffuse, IgnoredDetailNormal, DetailMaterial );

			return DetailMaterial.r;
		}

		float WoKSampleChasmValue(float2 WorldSpacePosXZ)
		{
			// TODO: Currently this does a lot of extra work.
			//       Optimize by rewriting from scratch to just obtain the red channel from map properties texture.

			const float2 ToSymmetryCenter = SYMMETRY_CENTER - WorldSpacePosXZ;

			// Polar coords
			const float r   = length(ToSymmetryCenter);
			const float phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x) + PI;

			return WoKSampleChasmValuePolar(SYMMETRY_CENTER, SYMMETRY_RANGE, r, phi);
		}
	]]
}
