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
		static const float CHASM_SAMPLE_PRECISION = 0.03125;

		static const float CHASM_BRINK_COORD_STEP = 2.5*CHASM_SAMPLE_PRECISION;

		static const float  CHASM_BRINK_COLOR_LERP_VALUE = 0.8;
		static const float3 CHASM_BOTTOM_COLOR           = float3(0.0, 0.0, 0.0);
		static const float3 CHASM_BOTTOM_NORMAL          = float3(0.0, -1.0, 0.0);

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
			// Based on vanilla CalculateDetailsLowSpec() but interested only in red channel of the properties texture

			float2 DetailCoordinates = WorldSpacePosXZ * WorldSpaceToDetail;
			float2 DetailCoordinatesScaled = DetailCoordinates * DetailTextureSize;
			float2 DetailCoordinatesScaledFloored = floor( DetailCoordinatesScaled );
			float2 DetailCoordinatesFrac = DetailCoordinatesScaled - DetailCoordinatesScaledFloored;
			DetailCoordinates = DetailCoordinatesScaledFloored * DetailTexelSize + DetailTexelSize * 0.5;

			float4 Factors = float4(
				(1.0 - DetailCoordinatesFrac.x) * (1.0 - DetailCoordinatesFrac.y),
				DetailCoordinatesFrac.x * (1.0 - DetailCoordinatesFrac.y),
				(1.0 - DetailCoordinatesFrac.x) * DetailCoordinatesFrac.y,
				DetailCoordinatesFrac.x * DetailCoordinatesFrac.y
			);

			float4 DetailIndex = PdxTex2DLod0( DetailIndexTexture, DetailCoordinates ) * 255.0;
			float4 DetailMask = PdxTex2DLod0( DetailMaskTexture, DetailCoordinates ) * Factors[0];

			float2 Offsets[3];
			Offsets[0] = float2( DetailTexelSize.x, 0.0 );
			Offsets[1] = float2( 0.0, DetailTexelSize.y );
			Offsets[2] = float2( DetailTexelSize.x, DetailTexelSize.y );

			for ( int k = 0; k < 3; ++k )
			{
				float2 DetailCoordinates2 = DetailCoordinates + Offsets[k];

				float4 DetailIndices = PdxTex2DLod0( DetailIndexTexture, DetailCoordinates2 ) * 255.0;
				float4 DetailMasks = PdxTex2DLod0( DetailMaskTexture, DetailCoordinates2 ) * Factors[k+1];

				for ( int i = 0; i < 4; ++i )
				{
					for ( int j = 0; j < 4; ++j )
					{
						if ( DetailIndex[j] == DetailIndices[i] )
						{
							DetailMask[j] += DetailMasks[i];
						}
					}
				}
			}

			float2 DetailUV = CalcDetailUV( WorldSpacePosXZ );

			float4 DiffuseTexture0 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[0] ) ) * smoothstep( 0.0, 0.1, DetailMask[0] );
			float4 DiffuseTexture1 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[1] ) ) * smoothstep( 0.0, 0.1, DetailMask[1] );
			float4 DiffuseTexture2 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[2] ) ) * smoothstep( 0.0, 0.1, DetailMask[2] );
			float4 DiffuseTexture3 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[3] ) ) * smoothstep( 0.0, 0.1, DetailMask[3] );

			float4 BlendFactors = CalcHeightBlendFactors( float4( DiffuseTexture0.a, DiffuseTexture1.a, DiffuseTexture2.a, DiffuseTexture3.a ), DetailMask, DetailBlendRange );

			float DetailMaterialR = 0.0;

			for (int i = 0; i < 4; ++i)
			{
				float BlendFactor = BlendFactors[i];
				if (BlendFactor > CHASM_VALUE_EPSILON)
				{
					float3 ArrayUV = float3( DetailUV, DetailIndex[i] );
					float4 MaterialTexture = PdxTex2DLod0( MaterialTextures, ArrayUV );

					DetailMaterialR += MaterialTexture.r * BlendFactor;
				}
			}

			return DetailMaterialR;
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

		void WoKUpdateChasmWallFakeNormal(
			inout float3 FakeNormal,
			in    float2 BrinkWorldSpacePosXZ,
			in    float  SampleDeltaX,
			in    float  SampleDeltaZ
		)
		{
			static const float3 NIL = float3(0.0, 0.0, 0.0);

			FakeNormal += lerp(
				NIL,
				normalize(float3(sign(SampleDeltaX), 0.0, sign(SampleDeltaZ))),
				step(
					CHASM_VALUE_EPSILON,
					WoKSampleChasmValue(BrinkWorldSpacePosXZ + float2(SampleDeltaX, SampleDeltaZ))
				)
			);
		}

		float3 WoKDetermineChasmWallFakeNormal(float2 BrinkWorldSpacePosXZ)
		{
			static const float SAMPLE_DELTA_COORD = CHASM_SAMPLE_STEP;

			float3 FakeNormal = float3(0.0, -0.001, 0.0); // y is non-zero for normalize() to behave in edge cases

			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, SAMPLE_DELTA_COORD, 0.0);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, -SAMPLE_DELTA_COORD, 0.0);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, 0.0, SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, 0.0, -SAMPLE_DELTA_COORD);

			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, SAMPLE_DELTA_COORD, SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, -SAMPLE_DELTA_COORD, SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, SAMPLE_DELTA_COORD, -SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, -SAMPLE_DELTA_COORD, -SAMPLE_DELTA_COORD);

			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, SAMPLE_DELTA_COORD, 0.5*SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, -SAMPLE_DELTA_COORD, 0.5*SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, SAMPLE_DELTA_COORD, -0.5*SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, -SAMPLE_DELTA_COORD, -0.5*SAMPLE_DELTA_COORD);

			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, 0.0, 0.5*SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, 0.0, 0.5*SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, 0.0, -0.5*SAMPLE_DELTA_COORD);
			WoKUpdateChasmWallFakeNormal(FakeNormal, BrinkWorldSpacePosXZ, 0.0, -0.5*SAMPLE_DELTA_COORD);

			return normalize(FakeNormal);
		}

		void WoKApplyChasmEffect(
			in    float3 WorldSpacePos,
			inout float3 BaseNormal,
			inout float3 DetailDiffuse,
			inout float3 DetailNormal,
			inout float4 DetailMaterial
		)
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

			float FakeDepth         = CameraAngleTan*SurfaceDistanceToBrink;
			float RelativeFakeDepth = saturate(FakeDepth / CHASM_MAX_FAKE_DEPTH);
			//float FakeDepth = SurfaceDistanceToBrink/CameraAngleCos;

			//
			// Texture mapping of the chasm walls
			//

			float2 BrinkOffset          = SampleDistanceUnit*SurfaceDistanceToBrink;
			float2 BrinkWorldSpacePosXZ = WorldSpacePos.xz + BrinkOffset;

			// Quantize to minimize "zebra" effect in favor of more vertical lines
			BrinkWorldSpacePosXZ.x -= mod(BrinkWorldSpacePosXZ.x, CHASM_BRINK_COORD_STEP);
			BrinkWorldSpacePosXZ.y -= mod(BrinkWorldSpacePosXZ.y, CHASM_BRINK_COORD_STEP);

			float3 WallNormal = WoKDetermineChasmWallFakeNormal(BrinkWorldSpacePosXZ);

			BaseNormal = lerp(WallNormal, CHASM_BOTTOM_NORMAL, RelativeFakeDepth);

			float2 SampleOffset           = -1.0*float2(0.0, FakeDepth); // TODO: Sample in one of 2 or 4 different directions, depending on the side of the chasm we're on
			float2 SampleWorldSpacePosXZ  = BrinkWorldSpacePosXZ + SampleOffset;

			CalculateDetails(SampleWorldSpacePosXZ, DetailDiffuse, DetailNormal, DetailMaterial);

			//
			// Fade diffuse color to CHASM_BOTTOM_COLOR as "depth" increases
			//

			float DepthBasedColorLerpValue = 1.0 - RelativeFakeDepth;
			//float DepthBasedColorLerpValue = 1.0 - smoothstep(0.0, CHASM_MAX_FAKE_DEPTH, FakeDepth);
			float ChasmColorLerpValue = CHASM_BRINK_COLOR_LERP_VALUE*DepthBasedColorLerpValue;

			DetailDiffuse = lerp(CHASM_BOTTOM_COLOR, DetailDiffuse, ChasmColorLerpValue);
		}

		//
		// Interface
		//

		void WoKTryApplyChasmEffect(
			in    float3 WorldSpacePos,
			inout float3 BaseNormal,
			inout float3 DetailDiffuse,
			inout float3 DetailNormal,
			inout float4 DetailMaterial
		)
		{
			#ifdef WOK_CHASM_ENABLED

				#ifdef WOK_CHASM_SYMMETRY_ENABLED
					float ChasmValue = WoKSampleChasmValue(WorldSpacePos.xz);
				#else
					float ChasmValue = DetailMaterial.r;
				#endif // WOK_CHASM_SYMMETRY_ENABLED

				if (ChasmValue > CHASM_VALUE_EPSILON) // if we are somewhere inside the chasm
					WoKApplyChasmEffect(WorldSpacePos, BaseNormal, DetailDiffuse, DetailNormal, DetailMaterial);

				#ifdef WOK_CHASM_SYMMETRY_GUIDES_ENABLED
					WoKDrawChasmSymmetryGuides(WorldSpacePos.xz, DetailDiffuse);
				#endif // WOK_CHASM_SYMMETRY_GUIDES_ENABLED

			#endif // WOK_CHASM_ENABLED
		}
	]]
}
