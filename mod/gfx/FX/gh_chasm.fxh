Includes = {
	"cw/pdxterrain.fxh"
	"gh_utils.fxh"
}

TextureSampler GH_RiftLayer0
{
	Index = 40
	MagFilter = "Linear"
	MinFilter = "Linear"
	MipFilter = "Linear"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
	Type = "Cube"
	File = "gfx/map/environment/gh_rift_layer_0.dds"
	srgb = yes
}

TextureSampler GH_RiftLayer1
{
	Index = 41
	MagFilter = "Linear"
	MinFilter = "Linear"
	MipFilter = "Linear"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
	Type = "Cube"
	File = "gfx/map/environment/gh_rift_layer_1.dds"
	srgb = yes
}

TextureSampler GH_ChasmTypesMap
{
	Index = 42
	MagFilter = "Point"
	MinFilter = "Point"
	MipFilter = "Point"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
	File = "gfx/map/terrain/GH_chasm_types.png"
}

TextureSampler GH_ChasmsMap
{
	Index = 43
	MagFilter = "Linear"
	MinFilter = "Linear"
	MipFilter = "Linear"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
	File = "gfx/map/terrain/GH_chasms.png"
	#srgb = yes
}

PixelShader
{
	Code
	[[
		//
		// Defines
		//

		#define GH_CHASM_ENABLED
		//#define GH_CHASM_SYMMETRY_ENABLED
		//#define GH_CHASM_SYMMETRY_GUIDES_ENABLED

		// Enables painting chasms in mapeditor at the cost of worse performance.
		// After finishing chasm painting, all of the chasmic terrain brushes' *_mask.png textures
		// need to be manually transfered to the image file loaded into GH_ChasmsMap texture (see above).
		//#define GH_CHASM_EDIT_MODE

		// This is intended to be defined from *LowSpec map Effects in pdxterrain.shader
		// so that a less performance-intensive config is used for players with low graphics settings.
		//#define GH_TERRAIN_LOW_SPEC

		//
		// Config
		//

		// Controls how smooth the color change between flat terrain and chasm wall should be,
		// normals notwithstanding. 1.0 means completely smooth, the closer to 0.0 the more abrupt.
		static const float  CHASM_BRINK_COLOR_LERP_VALUE = 0.8;

		static const float3 CHASM_BOTTOM_COLOR = float3(0.0, 0.0, 0.0);

		static const float2 CHASM_SYMMETRY_CENTER = float2(6945.0, 1102.0);
		static const float  CHASM_SYMMETRY_RANGE  = 155.0;

		static const float3 CHASM_SYMMETRY_GUIDES_COLOR = float3(1.0, 1.0, 1.0);

		static const float CHASM_WALL_NORMALS_SAMPLE_DISTANCE = 0.5;

		// Sampled chasm values are raised to this power to smooth out chasm brinks.
		// Values at or below 1.0f produce Minecraft-y chasms, higher values smooth
		// them out but generally reduce overall chasm width.
		static const float GH_CHASM_BRINK_SMOOTHING_EXPONENT = 6.75f;

		#ifndef GH_TERRAIN_LOW_SPEC
			// Higher fidelity setup

			static const float CHASM_MAX_FAKE_DEPTH   = 6.0;
			static const float CHASM_MAX_SAMPLE_RANGE = 64.0;
			static const float CHASM_SAMPLE_STEP      = 0.3;
			static const float CHASM_SAMPLE_PRECISION = 0.005;

			static const int CHASM_WALL_NORMALS_SAMPLE_COUNT = 12;
		#else
			// Higher FPS setup

			static const float CHASM_MAX_FAKE_DEPTH   = 6.0;
			static const float CHASM_MAX_SAMPLE_RANGE = 16.0;
			static const float CHASM_SAMPLE_STEP      = 0.6;
			static const float CHASM_SAMPLE_PRECISION = 0.25;

			static const int CHASM_WALL_NORMALS_SAMPLE_COUNT = 0;
		#endif // !GH_TERRAIN_LOW_SPEC

		//
		// Constants
		//

		static const float CHASM_VALUE_EPSILON = 0.001;

		static const float GH_CHASM_DISCARD_RELATIVE_DEPTH = 0.95f;

		// ENUM: Chasm type
		static const uint GH_CHASM_TYPE_BLACK       = 0;
		static const uint GH_CHASM_TYPE_STARRY      = 1;
		static const uint GH_CHASM_TYPE_TRANSPARENT = 2;
		// END ENUM

		//
		// Service
		//

		void GH_GetVanillaDetailValues(in float2 WorldSpacePosXZ, out float2 DetailCoordinates, out float4 Factors, out float2 Offsets[3])
		{
			DetailCoordinates = WorldSpacePosXZ * WorldSpaceToDetail;

			float2 DetailCoordinatesScaled = DetailCoordinates * DetailTextureSize;
			float2 DetailCoordinatesScaledFloored = floor( DetailCoordinatesScaled );
			float2 DetailCoordinatesFrac = DetailCoordinatesScaled - DetailCoordinatesScaledFloored;
			DetailCoordinates = DetailCoordinatesScaledFloored * DetailTexelSize + DetailTexelSize * 0.5;

			Factors = float4(
				(1.0 - DetailCoordinatesFrac.x) * (1.0 - DetailCoordinatesFrac.y),
				DetailCoordinatesFrac.x * (1.0 - DetailCoordinatesFrac.y),
				(1.0 - DetailCoordinatesFrac.x) * DetailCoordinatesFrac.y,
				DetailCoordinatesFrac.x * DetailCoordinatesFrac.y
			);

			Offsets[0] = float2( DetailTexelSize.x, 0.0 );
			Offsets[1] = float2( 0.0, DetailTexelSize.y );
			Offsets[2] = float2( DetailTexelSize.x, DetailTexelSize.y );
		}

		float GH_SampleRedPropsChannelCartesian(float2 WorldSpacePosXZ)
		{
			// Based on vanilla CalculateDetailsLowSpec() but interested only in red channel of the properties texture

			float2 DetailCoordinates;
			float4 Factors;
			float2 Offsets[3];
			GH_GetVanillaDetailValues(WorldSpacePosXZ, DetailCoordinates, Factors, Offsets);

			float4 DetailIndex = PdxTex2DLod0( DetailIndexTexture, DetailCoordinates ) * 255.0;
			float4 DetailMask = PdxTex2DLod0( DetailMaskTexture, DetailCoordinates ) * Factors[0];

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

		float GH_SampleChasmValueCartesian(float2 WorldSpacePosXZ)
		{
			// Partially based on vanilla CalculateDetailsLowSpec(),
			// but interested only in chasm value as specified by GH_ChasmsMap texture

			float2 DetailCoordinates;
			float4 Factors;
			float2 Offsets[3];
			GH_GetVanillaDetailValues(WorldSpacePosXZ, DetailCoordinates, Factors, Offsets);

			float ChasmValue = PdxTex2DLod0( GH_ChasmsMap, float2(DetailCoordinates.x, 1.0f - DetailCoordinates.y) ).r * Factors[0];

			for ( int k = 0; k < 3; ++k )
			{
				float2 DetailCoordinates2 = DetailCoordinates + Offsets[k];

				float AddedChasmValue = PdxTex2DLod0( GH_ChasmsMap, float2(DetailCoordinates2.x, 1.0f - DetailCoordinates2.y) ).r * Factors[k+1];

				ChasmValue += AddedChasmValue;
			}

			// Exponentiating ChasmValue smoothes out chasm brinks... for some reason
			return pow(ChasmValue, GH_CHASM_BRINK_SMOOTHING_EXPONENT);
		}

		#ifdef GH_CHASM_EDIT_MODE
			#define GH_SAMPLE_CHASM_VALUE_CARTESIAN GH_SampleRedPropsChannelCartesian
		#else
			#define GH_SAMPLE_CHASM_VALUE_CARTESIAN GH_SampleChasmValueCartesian
		#endif // GH_CHASM_EDIT_MODE

		float GH_SampleChasmValuePolar(float2 Center, float R, float Phi)
		{
			float2 Offset = float2(R*cos(Phi), R*sin(Phi));

			return GH_SAMPLE_CHASM_VALUE_CARTESIAN(Center - Offset);
		}

		float GH_SampleChasmValueSymmetrical(float2 SymmetryCenter, float SymmetryRange, float2 WorldSpacePosXZ)
		{
			static const float PI_BY_4 = PI/4.0;

			float2 ToSymmetryCenter = SymmetryCenter - WorldSpacePosXZ;

			// Polar coords
			float R   = length(ToSymmetryCenter);
			float Phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x) + 2*PI;

			float SymmetryPhi         = mod(Phi, PI_BY_4);
			float SymmetryMirroredPhi = lerp(SymmetryPhi, PI_BY_4 - SymmetryPhi, step(PI_BY_4, mod(Phi, 2*PI_BY_4)));

			float SelectedPhi = lerp(SymmetryMirroredPhi, Phi, step(SymmetryRange, R));

			return GH_SampleChasmValuePolar(SymmetryCenter, R, SelectedPhi);
		}

		float GH_SampleChasmValue(float2 WorldSpacePosXZ)
		{
			#ifdef GH_CHASM_SYMMETRY_ENABLED
				return GH_SampleChasmValueSymmetrical(CHASM_SYMMETRY_CENTER, CHASM_SYMMETRY_RANGE, WorldSpacePosXZ);
			#else
				return GH_SAMPLE_CHASM_VALUE_CARTESIAN(WorldSpacePosXZ);
			#endif
		}

		void GH_DrawChasmSymmetryGuides(float2 WorldSpacePosXZ, inout float3 PixelColor)
		{
			float2 ToSymmetryCenter = CHASM_SYMMETRY_CENTER - WorldSpacePosXZ;
			float  R   = length(ToSymmetryCenter);
			float  Phi = atan2(ToSymmetryCenter.y, ToSymmetryCenter.x);

			if (R < 2.0 || (R > CHASM_SYMMETRY_RANGE && R < CHASM_SYMMETRY_RANGE + 1.0) ||
				((Phi > PI/4 && Phi < PI/4 + 0.01) || (Phi > 0.0 && Phi < 0.0 + 0.01)) && R < CHASM_SYMMETRY_RANGE)
			{
				PixelColor = CHASM_SYMMETRY_GUIDES_COLOR;
			}
		}

		float3 GH_DetermineChasmWallNormal(float2 BrinkWorldSpacePosXZ)
		{
			static const float SAMPLE_ANGLE_INCREMENT = 2.0*PI/float(CHASM_WALL_NORMALS_SAMPLE_COUNT);

			float3 RawNormal = float3(0.0, 0.0, 0.0);

			// TODO: Optimize. We probably can get away with sampling only in the semicircle facing the camera,
			//       since we can't see away-facing chasm walls anyhow.

			GH_UNROLL
			for (int i = 0; i < CHASM_WALL_NORMALS_SAMPLE_COUNT; i++)
			{
				float  SampleAngle      = float(i)*SAMPLE_ANGLE_INCREMENT;
				float2 SampleDirection  = float2(cos(SampleAngle), sin(SampleAngle));
				float2 SampleOffset     = CHASM_WALL_NORMALS_SAMPLE_DISTANCE*SampleDirection;
				float  SampleChasmValue = GH_SampleChasmValue(BrinkWorldSpacePosXZ + SampleOffset);

				RawNormal += SampleChasmValue*float3(SampleDirection.x, 0.0, SampleDirection.y);
			}

			return normalize(RawNormal);
		}

		void GH_PrepareChasmEffectImpl(
			in    float3 WorldSpacePos,
			/*in    int    TerrainVariantIndex,*/
			inout float3 BaseNormal,
			inout float4 DetailDiffuse,
			inout float3 DetailNormal,
			inout float4 DetailMaterial,
			out   float  RelativeChasmDepth
		)
		{
			float3 FromCamera       = WorldSpacePos - CameraPosition;
			float3 FromCameraNorm   = normalize(FromCamera);
			float3 FromCameraXZ     = float3(FromCamera.x, 0.0, FromCamera.z);
			float3 FromCameraXZNorm = normalize(FromCameraXZ);
			float  CameraAngleSin   = length(cross(FromCameraNorm, FromCameraXZNorm));
			float  CameraAngleCos   = dot(FromCameraNorm, FromCameraXZNorm);
			float  CameraAngleTan   = CameraAngleSin/max(CameraAngleCos, 0.05);

			float2 SampleDistanceUnit = FromCameraXZNorm.xz;
			float  SampleRange        = min(CHASM_MAX_FAKE_DEPTH/CameraAngleTan, CHASM_MAX_SAMPLE_RANGE);

			float SurfaceDistanceToBrink = SampleRange;

			for (float SampleDistance = 0.0; SampleDistance < SampleRange; SampleDistance += CHASM_SAMPLE_STEP)
			{
				float2 SampleWorldSpacePosXZ = WorldSpacePos.xz + SampleDistance*SampleDistanceUnit;
				float  SampledChasmValue     = GH_SampleChasmValue(SampleWorldSpacePosXZ);

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
				float  MidpointChasmValue      = GH_SampleChasmValue(MidpointWorldSpacePosXZ);

				float StepValue           = step(CHASM_VALUE_EPSILON, MidpointChasmValue);
				SurfaceDistanceToBrink    = lerp(SurfaceDistanceToBrink, Midpoint, 1.0 - StepValue);
				MinSurfaceDistanceToBrink = lerp(MinSurfaceDistanceToBrink, Midpoint, StepValue);
			}

			float FakeDepth = CameraAngleTan*SurfaceDistanceToBrink;
			//float FakeDepth = SurfaceDistanceToBrink/CameraAngleCos;

			//
			// Texture mapping of the chasm walls
			//

			float2 BrinkOffset          = SampleDistanceUnit*SurfaceDistanceToBrink;
			float2 BrinkWorldSpacePosXZ = WorldSpacePos.xz + BrinkOffset;

			// Sample in the negative Y direction by default, so that texture mapping
			// looks fine from the most common camera viewing angles players use during the game,
			// even if we choose not to determine the actual chasm wall normal.
			float2 SampleOffset = float2(0.0, -FakeDepth);

			if (CHASM_WALL_NORMALS_SAMPLE_COUNT > 0)
			{
				BaseNormal = GH_DetermineChasmWallNormal(BrinkWorldSpacePosXZ);

				SampleOffset = FakeDepth*BaseNormal.xz;
			}

			float2 SampleWorldSpacePosXZ = BrinkWorldSpacePosXZ + SampleOffset;

			CalculateDetails(SampleWorldSpacePosXZ, /*TerrainVariantIndex,*/ DetailDiffuse, DetailNormal, DetailMaterial);

			RelativeChasmDepth = FakeDepth / CHASM_MAX_FAKE_DEPTH;
		}

		//
		// Interface
		//

		void GH_PrepareChasmEffect(
			in    float3 WorldSpacePos,
			/*in    int    TerrainVariantIndex,*/
			inout float3 BaseNormal,
			inout float4 DetailDiffuse,
			inout float3 DetailNormal,
			inout float4 DetailMaterial,
			out   float  RelativeChasmDepth
		)
		{
			#ifdef GH_CHASM_ENABLED

				#if defined(GH_CHASM_EDIT_MODE) && !defined(GH_CHASM_SYMMETRY_ENABLED)
					// We can skip the initial chasm value sampling when GH_CHASM_EDIT_MODE is active,
					// because in this mode we use red properties channel as chasm value,
					// which is already known for the current pixel.
					float ChasmValue = DetailMaterial.r;
				#else
					float ChasmValue = GH_SampleChasmValue(WorldSpacePos.xz);
				#endif // GH_CHASM_EDIT_MODE && !GH_CHASM_SYMMETRY_ENABLED

				if (ChasmValue <= CHASM_VALUE_EPSILON) // if we are outside the chasm
				{
					RelativeChasmDepth = 0.0;

					return;
				}

				GH_PrepareChasmEffectImpl(
					WorldSpacePos,
					/*TerrainVariantIndex,*/
					BaseNormal,
					DetailDiffuse,
					DetailNormal,
					DetailMaterial,
					RelativeChasmDepth
				);

			#else

				RelativeChasmDepth = 0.0;

			#endif // GH_CHASM_ENABLED
		}

		uint GH_GetChasmType(float2 WorldSpacePosXZ)
		{
			float3 EncodedChasmType = PdxTex2DLod0(GH_ChasmTypesMap, GH_WorldSpacePosXZToMapUV(WorldSpacePosXZ)).rgb;

			return uint(GH_DecodeIntFromRgb(EncodedChasmType));
		}

		void GH_TryDiscardChasmPixel(float RelativeChasmDepth, uint ChasmType)
		{
			// Discard pixels at the bottom of the chasm, so we can "see through" the bottom.
			// (Note that unlike setting alpha to 0 this also prevents a depth buffer write.)
			if (ChasmType == GH_CHASM_TYPE_TRANSPARENT && RelativeChasmDepth > GH_CHASM_DISCARD_RELATIVE_DEPTH)
				discard;
		}

		void GH_AdjustChasmFinalColor(inout float3 FinalColor, in float RelativeChasmDepth, in float3 WorldSpacePos, in uint ChasmType)
		{
			#ifdef GH_CHASM_ENABLED
				if (RelativeChasmDepth < 0.005)
					return;

				float BaseColorLerpValue  = lerp(1.0, CHASM_BRINK_COLOR_LERP_VALUE, RelativeChasmDepth);
				float FinalColorLerpValue = BaseColorLerpValue*(1.0 - RelativeChasmDepth);

				// Fade color to CHASM_BOTTOM_COLOR as "depth" increases
				FinalColor = lerp(CHASM_BOTTOM_COLOR, FinalColor, FinalColorLerpValue);

				if (ChasmType == GH_CHASM_TYPE_STARRY)
				{
					float3 FromCameraDir0 = normalize(WorldSpacePos + float3(0.0f, 0.0f, 0.0f) - CameraPosition);
					float4 RiftLayer0     = PdxTexCube(GH_RiftLayer0, FromCameraDir0);
					float3 FromCameraDir1 = normalize(WorldSpacePos + float3(0.0f, 1000.0f, 0.0f) - CameraPosition);
					float4 RiftLayer1     = PdxTexCube(GH_RiftLayer1, FromCameraDir1);

					float3 RiftColor = RiftLayer0.rgb + RiftLayer1.rgb*RiftLayer1.a;

					FinalColor = lerp(FinalColor, RiftColor, smoothstep(0.8f, 1.0f, RelativeChasmDepth));
				}

				#ifdef GH_CHASM_SYMMETRY_GUIDES_ENABLED
					GH_DrawChasmSymmetryGuides(WorldSpacePosXZ, FinalColor);
				#endif // GH_CHASM_SYMMETRY_GUIDES_ENABLED

			#endif // GH_CHASM_ENABLED
		}
	]]
}
