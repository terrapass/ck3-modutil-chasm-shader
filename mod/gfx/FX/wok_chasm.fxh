PixelShader
{
	Code
	[[
		//
		// Defines
		//

		#define WOK_CHASM_ENABLED
		#define WOK_CHASM_SYMMETRY_ENABLED
		#define WOK_CHASM_SYMMETRY_GUIDES_ENABLED

		//
		// Config
		//

		static const float CHASM_MAX_FAKE_DEPTH   = 8.0;
		static const float CHASM_SAMPLE_RANGE     = 16.0;
		static const float CHASM_SAMPLE_STEP      = 0.25;
		static const float CHASM_SAMPLE_PRECISION = 0.125;

		static const float3 CHASM_BOTTOM_COLOR = float3(0.0, 0.0, 0.0);

		static const float2 CHASM_SYMMETRY_CENTER = float2(2250.0, 1050.0);
		static const float  CHASM_SYMMETRY_RANGE  = 120.0;

		static const float3 CHASM_SYMMETRY_GUIDES_COLOR = float3(1.0, 1.0, 1.0);

		//
		// Constants
		//

		static const float CHASM_VALUE_EPSILON = 0.001;

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
			float2 Offset = float2(R*cos(Phi), R*sin(Phi));

			return WoKSampleRedPropsChannelCartesian(Center - Offset);
		}

		float WoKSampleChasmValueSymmetricalImpl(float2 SymmetryCenter, float SymmetryRange, float2 WorldSpacePosXZ)
		{
			float PI_BY_4 = PI/4.0;

			float2 ToSymmetryCenter = SymmetryCenter - WorldSpacePosXZ;

			// Polar coords
			float R   = length(ToSymmetryCenter);
			float Phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x) + 2*PI;

			float SymmetryPhi         = mod(Phi, PI_BY_4);
			float SymmetryMirroredPhi = lerp(SymmetryPhi, PI_BY_4 - SymmetryPhi, step(PI_BY_4, mod(Phi, 2*PI_BY_4)));

			float SelectedPhi = lerp(SymmetryMirroredPhi, Phi, step(SymmetryRange, R));

			return WoKSampleRedPropsChannelPolar(SymmetryCenter, R, SelectedPhi);
		}

		float WoKSampleChasmValue(float2 WorldSpacePosXZ)
		{
			#ifdef WOK_CHASM_SYMMETRY_ENABLED
			return WoKSampleChasmValueSymmetricalImpl(CHASM_SYMMETRY_CENTER, CHASM_SYMMETRY_RANGE, WorldSpacePosXZ);
			#else
			return WoKSampleRedPropsChannelCartesian(WorldSpacePosXZ);
			#endif
		}

		void WoKDrawChasmSymmetryGuides(float2 WorldSpacePosXZ, inout float3 PixelColor)
		{
			float2 ToSymmetryCenter = CHASM_SYMMETRY_CENTER - WorldSpacePosXZ;
			float  R   = length(ToSymmetryCenter);
			float  Phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x);

			if (R < 5.0 || (R > CHASM_SYMMETRY_RANGE && R < CHASM_SYMMETRY_RANGE + 1.5) ||
				((Phi > PI/4 && Phi < PI/4 + 0.01) || (Phi > 0.0 && Phi < 0.0 + 0.01)) && R < CHASM_SYMMETRY_RANGE)
			{
				PixelColor = CHASM_SYMMETRY_GUIDES_COLOR;
			}
		}

		//
		// Interface
		//

		void WoKTryApplyChasmEffect(in float3 WorldSpacePos, inout float3 DetailDiffuse, inout float3 DetailNormal, inout float4 DetailMaterial)
		{
			#ifdef WOK_CHASM_ENABLED

			#ifdef WOK_CHASM_SYMMETRY_ENABLED
			float ChasmValue = WoKSampleChasmValue(WorldSpacePos.xz);
			#else
			float ChasmValue = DetailMaterial.r;
			#endif // WOK_CHASM_SYMMETRY_ENABLED

			if (ChasmValue > CHASM_VALUE_EPSILON) // if we are somewhere inside the chasm
			{
				float3 FromCamera       = WorldSpacePos - CameraPosition;
				float3 FromCameraNorm   = normalize(FromCamera);
				float3 FromCameraXZ     = float3(FromCamera.x, 0.0, FromCamera.z);
				float3 FromCameraXZNorm = normalize(FromCameraXZ);
				float  CameraAngleSin   = length(cross(FromCameraNorm, FromCameraXZNorm));
				float  CameraAngleCos   = dot(FromCameraNorm, FromCameraXZNorm);
				float  CameraAngleTan   = CameraAngleSin/CameraAngleCos;

				float2 SampleDistanceUnit = normalize(FromCamera.xz);

				float SurfaceDistanceToBrink = CHASM_SAMPLE_RANGE;

				for (float SampleDistance = 0.0; SampleDistance < CHASM_SAMPLE_RANGE; SampleDistance += CHASM_SAMPLE_STEP)
				{
					float2 SampleWorldSpacePosXZ = WorldSpacePos.xz + SampleDistance*SampleDistanceUnit;
					float  SampledChasmValue     = WoKSampleChasmValue(SampleWorldSpacePosXZ);

					if (SampledChasmValue < CHASM_VALUE_EPSILON)
					{
						SurfaceDistanceToBrink = SampleDistance;
						break;
					}
				}

				// Binary search to reach CHASM_SAMPLE_PRECISION for distance to brink
				// (doesn't work on DirectX currently - gradient operation in a variable-iteration loop)
				#ifndef PDX_DIRECTX_11
				float MinSurfaceDistanceToBrink = SurfaceDistanceToBrink - CHASM_SAMPLE_STEP;
				while (SurfaceDistanceToBrink - MinSurfaceDistanceToBrink > CHASM_SAMPLE_PRECISION)
				{
					float  Midpoint                = 0.5*(MinSurfaceDistanceToBrink + SurfaceDistanceToBrink);
					float2 MidpointWorldSpacePosXZ = WorldSpacePos.xz + Midpoint*SampleDistanceUnit;
					float  MidpointChasmValue      = WoKSampleChasmValue(MidpointWorldSpacePosXZ);

					float StepValue           = step(CHASM_VALUE_EPSILON, MidpointChasmValue);
					SurfaceDistanceToBrink    = lerp(SurfaceDistanceToBrink, Midpoint, 1.0 - StepValue);
					MinSurfaceDistanceToBrink = lerp(MinSurfaceDistanceToBrink, Midpoint, StepValue);
				}
				#endif

				float FakeDepth = CameraAngleTan*SurfaceDistanceToBrink;
				//float FakeDepth = SurfaceDistanceToBrink/CameraAngleCos;

				//static const float3 DEBUG_DISTANCE_BASE_COLOR = (171.0, 119.0, 75.0) / 255.0;

				//
				// Fade to black as "depth" increases
				//

				static const float BASE_COLOR_MULTIPLIER = 0.8;

				float DepthColorMultiplier = 1.0 - saturate(FakeDepth / CHASM_MAX_FAKE_DEPTH);
				//float DepthColorMultiplier = 1.0 - smoothstep(0.0, CHASM_MAX_FAKE_DEPTH, FakeDepth);
				float ChasmColorMultiplier = BASE_COLOR_MULTIPLIER*DepthColorMultiplier;

				//
				// Texture mapping of the chasm walls
				//

				// TODO: The entire MOD block needs to be moved up so that we modify DetailDiffuse and DetailNormal
				//       instead of FinalColor directly. This should allow for proper lighting (assuming corrected normals)
				//       and would save up on double sampling work we're doing here.
				float2 BrinkOffset         = SampleDistanceUnit*SurfaceDistanceToBrink;
				float2 DiffuseSampleOffset = -1.0*float2(0.0, FakeDepth); // TODO: Sample in one of 2 or 4 different directions, depending on the side of the chasm we're on
				float2 DiffuseSamplePosXZ  = WorldSpacePos.xz + BrinkOffset + DiffuseSampleOffset;
				CalculateDetails( DiffuseSamplePosXZ, DetailDiffuse, DetailNormal, DetailMaterial );
			DetailDiffuse = lerp(CHASM_BOTTOM_COLOR, DetailDiffuse, ChasmColorMultiplier);
		}


			#ifdef WOK_CHASM_SYMMETRY_GUIDES_ENABLED
			WoKDrawChasmSymmetryGuides(WorldSpacePos.xz, DetailDiffuse);
			#endif // WOK_CHASM_SYMMETRY_GUIDES_ENABLED

			#endif // WOK_CHASM_ENABLED
		}
	]]
}
