PixelShader
{
	Code
	[[
		//
		// Config
		//

		static const bool   WOK_CHASM_IS_SYMMETRY_ENABLED = true;
		static const float2 WOK_CHASM_SYMMETRY_CENTER     = float2(2250.0, 1050.0);
		static const float  WOK_CHASM_SYMMETRY_RANGE      = 120.0;
		static const float3 WOK_CHASM_SYMMETRY_GUIDES_RGB = float3(1.0, 1.0, 1.0);

		//
		// Service
		//

		float WoKSampleRedPropsChannelCartesian(float2 WorldSpacePosXZ)
		{
			// TODO: Currently this does a lot of extra work.
			//       Optimize by writing our own sampling function from scratch
			//       that would just obtain the red channel from map properties texture.

			float3 IgnoredDetailDiffuse;
			float3 IgnoredDetailNormal;

			float4 DetailMaterial;

			CalculateDetails(WorldSpacePosXZ, IgnoredDetailDiffuse, IgnoredDetailNormal, DetailMaterial);

			return DetailMaterial.r;
		}

		float WoKSampleRedPropsChannelPolar(float2 Center, float R, float Phi)
		{
			const float2 Offset = float2(R*cos(Phi), R*sin(Phi));

			return WoKSampleRedPropsChannelCartesian(Center - Offset);
		}

		float WoKSampleChasmValueSymmetricalImpl(float2 SymmetryCenter, float SymmetryRange, float2 WorldSpacePosXZ)
		{
			static const float PI_BY_4 = PI/4.0;

			const float2 ToSymmetryCenter = SymmetryCenter - WorldSpacePosXZ;

			// Polar coords
			const float R   = length(ToSymmetryCenter);
			const float Phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x) + 2*PI;

			const float SymmetryPhi         = mod(Phi, PI_BY_4);
			const float SymmetryMirroredPhi = lerp(SymmetryPhi, PI_BY_4 - SymmetryPhi, step(PI_BY_4, mod(Phi, 2*PI_BY_4)));

			const float SelectedPhi = lerp(SymmetryMirroredPhi, Phi, step(SymmetryRange, R));

			return WoKSampleRedPropsChannelPolar(SymmetryCenter, R, SelectedPhi);
		}

		//
		// Interface
		//

		float WoKSampleChasmValue(float2 WorldSpacePosXZ)
		{
			if (WOK_CHASM_IS_SYMMETRY_ENABLED)
				return WoKSampleChasmValueSymmetricalImpl(WOK_CHASM_SYMMETRY_CENTER, WOK_CHASM_SYMMETRY_RANGE, WorldSpacePosXZ);

			return WoKSampleRedPropsChannelCartesian(WorldSpacePosXZ);
		}

		void WoKDrawChasmSymmetryGuides(float2 WorldSpacePosXZ, inout float3 PixelColor)
		{
			const float2 ToSymmetryCenter = WOK_CHASM_SYMMETRY_CENTER - WorldSpacePosXZ;
			const float  R   = length(ToSymmetryCenter);
			const float  Phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x);

			if (R < 5.0 || (R > WOK_CHASM_SYMMETRY_RANGE && R < WOK_CHASM_SYMMETRY_RANGE + 1.5) ||
				((Phi > PI/4 && Phi < PI/4 + 0.01) || (Phi > 0.0 && Phi < 0.0 + 0.01)) && R < WOK_CHASM_SYMMETRY_RANGE)
			{
				PixelColor = WOK_CHASM_SYMMETRY_GUIDES_RGB;
			}
		}
	]]
}
