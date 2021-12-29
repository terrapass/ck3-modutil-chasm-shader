Includes = {
	"cw/pdxterrain.fxh"
	"cw/heightmap.fxh"
	"cw/shadow.fxh"
	"cw/utility.fxh"
	"cw/camera.fxh"
	"jomini/jomini_fog.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_fog_of_war.fxh"
	"jomini/jomini_water.fxh"
	"standardfuncsgfx.fxh"
	"bordercolor.fxh"
	"lowspec.fxh"
	"dynamic_masks.fxh"
	# MOD(shattered-plains)
	"wok_chasm.fxh"
	# END MOD
}

VertexStruct VS_OUTPUT_PDX_TERRAIN
{
	float4 Position			: PDX_POSITION;
	float3 WorldSpacePos	: TEXCOORD1;
	float4 ShadowProj		: TEXCOORD2;
};

VertexStruct VS_OUTPUT_PDX_TERRAIN_LOW_SPEC
{
	float4 Position			: PDX_POSITION;
	float3 WorldSpacePos	: TEXCOORD1;
	float4 ShadowProj		: TEXCOORD2;
	float3 DetailDiffuse	: TEXCOORD3;
	float4 DetailMaterial	: TEXCOORD4;
	float3 ColorMap			: TEXCOORD5;		
	float3 FlatMap			: TEXCOORD6;
	float3 Normal			: TEXCOORD7;
};

VertexShader =
{
	TextureSampler DetailTextures
	{
		Ref = PdxTerrainTextures0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		type = "2darray"
	}
	TextureSampler NormalTextures
	{
		Ref = PdxTerrainTextures1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		type = "2darray"
	}
	TextureSampler MaterialTextures
	{
		Ref = PdxTerrainTextures2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		type = "2darray"
	}
	TextureSampler DetailIndexTexture
	{
		Ref = PdxTerrainTextures3
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler DetailMaskTexture
	{
		Ref = PdxTerrainTextures4
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler ColorTexture
	{
		Ref = PdxTerrainColorMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler FlatMapTexture
	{
		Ref = TerrainFlatMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	Code
	[[
		// MOD(shattered-plains)
		//#define PdxTex2D(samp,uv) (samp)._Texture.Sample( (samp)._Sampler, (uv) )
		#ifdef PDX_DIRECTX_11
		#define WoKTex2D(samp,coords) (samp)._Texture[ coords ]
		#else // OpenGL
		//#define WoKTex2D(samp,coords) // TODO
		#endif

		// void WoKGetChasmAmount( float2 WorldSpacePosXZ, out float ChasmAmount )
		// {
		// 	float2 DetailCoordinates = WorldSpacePosXZ * WorldSpaceToDetail;
		// 	float2 DetailCoordinatesScaled = DetailCoordinates * DetailTextureSize;
		// 	float2 DetailCoordinatesScaledFloored = floor( DetailCoordinatesScaled );
		// 	float2 DetailCoordinatesFrac = DetailCoordinatesScaled - DetailCoordinatesScaledFloored;
		// 	//DetailCoordinates = DetailCoordinatesScaledFloored * DetailTexelSize + DetailTexelSize * 0.5;
			
		// 	float4 Factors = float4(
		// 		(1.0 - DetailCoordinatesFrac.x) * (1.0 - DetailCoordinatesFrac.y),
		// 		DetailCoordinatesFrac.x * (1.0 - DetailCoordinatesFrac.y),
		// 		(1.0 - DetailCoordinatesFrac.x) * DetailCoordinatesFrac.y,
		// 		DetailCoordinatesFrac.x * DetailCoordinatesFrac.y
		// 	);

		// 	uint2 DetailCoordinatesInt = uint2(DetailCoordinatesScaledFloored);

		// 	float4 DetailIndex = WoKTex2D( DetailIndexTexture, DetailCoordinatesInt ) * 255.0;
		// 	float4 DetailMask = WoKTex2D( DetailMaskTexture, DetailCoordinatesInt ) * Factors[0];

		// 	// TODO
		// 	ChasmAmount = 0.0; // Also return instead of out maybe?
		// }

		// // FIXME: These definitions duplicate a later definition in this file.
		// // TODO:  Deduplicate and extract into a *.fxh file.
		// // A low spec vertex buffer version of CalculateDetails

		// float4 WoKCalcHeightBlendFactors( float4 MaterialHeights, float4 MaterialFactors, float BlendRange )
		// {
		// 	float4 Mat = MaterialHeights + MaterialFactors;
		// 	float BlendStart = max( max( Mat.x, Mat.y ), max( Mat.z, Mat.w ) ) - BlendRange;
			
		// 	float4 MatBlend = max( Mat - vec4( BlendStart ), vec4( 0.0 ) );
			
		// 	float Epsilon = 0.00001;
		// 	return float4( MatBlend ) / ( dot( MatBlend, vec4( 1.0 ) ) + Epsilon );
		// }

		// void WoKCalculateDetailsLowSpec( float2 WorldSpacePosXZ, out float3 DetailDiffuse, out float4 DetailMaterial )
		// {
		// 	float2 DetailCoordinates = WorldSpacePosXZ * WorldSpaceToDetail;
		// 	float2 DetailCoordinatesScaled = DetailCoordinates * DetailTextureSize;
		// 	float2 DetailCoordinatesScaledFloored = floor( DetailCoordinatesScaled );
		// 	float2 DetailCoordinatesFrac = DetailCoordinatesScaled - DetailCoordinatesScaledFloored;
		// 	DetailCoordinates = DetailCoordinatesScaledFloored * DetailTexelSize + DetailTexelSize * 0.5;
			
		// 	float4 Factors = float4(
		// 		(1.0 - DetailCoordinatesFrac.x) * (1.0 - DetailCoordinatesFrac.y),
		// 		DetailCoordinatesFrac.x * (1.0 - DetailCoordinatesFrac.y),
		// 		(1.0 - DetailCoordinatesFrac.x) * DetailCoordinatesFrac.y,
		// 		DetailCoordinatesFrac.x * DetailCoordinatesFrac.y
		// 	);
			
		// 	float4 DetailIndex = PdxTex2DLod0( DetailIndexTexture, DetailCoordinates ) * 255.0;
		// 	float4 DetailMask = PdxTex2DLod0( DetailMaskTexture, DetailCoordinates ) * Factors[0];
			
		// 	float2 Offsets[3];
		// 	Offsets[0] = float2( DetailTexelSize.x, 0.0 );
		// 	Offsets[1] = float2( 0.0, DetailTexelSize.y );
		// 	Offsets[2] = float2( DetailTexelSize.x, DetailTexelSize.y );
			
		// 	for ( int k = 0; k < 3; ++k )
		// 	{
		// 		float2 DetailCoordinates2 = DetailCoordinates + Offsets[k];
				
		// 		float4 DetailIndices = PdxTex2DLod( DetailIndexTexture, DetailCoordinates2, 4 ) * 255.0;
		// 		float4 DetailMasks = PdxTex2DLod( DetailMaskTexture, DetailCoordinates2, 4 ) * Factors[k+1];
				
		// 		for ( int i = 0; i < 4; ++i )
		// 		{
		// 			for ( int j = 0; j < 4; ++j )
		// 			{
		// 				if ( DetailIndex[j] == DetailIndices[i] )
		// 				{
		// 					DetailMask[j] += DetailMasks[i];
		// 				}
		// 			}
		// 		}
		// 	}

		// 	float2 DetailUV = WorldSpacePosXZ * DetailTileFactor; 
			
		// 	float4 DiffuseTexture0 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[0] ) ) * smoothstep( 0.0, 0.1, DetailMask[0] );
		// 	float4 DiffuseTexture1 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[1] ) ) * smoothstep( 0.0, 0.1, DetailMask[1] );
		// 	float4 DiffuseTexture2 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[2] ) ) * smoothstep( 0.0, 0.1, DetailMask[2] );
		// 	float4 DiffuseTexture3 = PdxTex2DLod0( DetailTextures, float3( DetailUV, DetailIndex[3] ) ) * smoothstep( 0.0, 0.1, DetailMask[3] );
			
		// 	float4 BlendFactors = WoKCalcHeightBlendFactors( float4( DiffuseTexture0.a, DiffuseTexture1.a, DiffuseTexture2.a, DiffuseTexture3.a ), DetailMask, DetailBlendRange );
		// 	//BlendFactors = DetailMask;
			
		// 	DetailDiffuse = DiffuseTexture0.rgb * BlendFactors.x + 
		// 					DiffuseTexture1.rgb * BlendFactors.y + 
		// 					DiffuseTexture2.rgb * BlendFactors.z + 
		// 					DiffuseTexture3.rgb * BlendFactors.w;
			
		// 	DetailMaterial = vec4( 0.0 );
			
		// 	for ( int i = 0; i < 4; ++i )
		// 	{
		// 		float BlendFactor = BlendFactors[i];
		// 		if ( BlendFactor > 0.0 )
		// 		{
		// 			float3 ArrayUV = float3( DetailUV, DetailIndex[i] );
		// 			float4 NormalTexture = PdxTex2DLod0( NormalTextures, ArrayUV );
		// 			float4 MaterialTexture = PdxTex2DLod0( MaterialTextures, ArrayUV );

		// 			DetailMaterial += MaterialTexture * BlendFactor;
		// 		}
		// 	}
		// }
		// END MOD

		VS_OUTPUT_PDX_TERRAIN TerrainVertex( float2 WithinNodePos, float2 NodeOffset, float NodeScale, float2 LodDirection, float LodLerpFactor )
		{
			STerrainVertex Vertex = CalcTerrainVertex( WithinNodePos, NodeOffset, NodeScale, LodDirection, LodLerpFactor );

			#ifdef TERRAIN_FLAT_MAP_LERP
				Vertex.WorldSpacePos.y = lerp( Vertex.WorldSpacePos.y, FlatMapHeight, FlatMapLerp );
			#endif
			#ifdef TERRAIN_FLAT_MAP
				Vertex.WorldSpacePos.y = FlatMapHeight;
			#endif

			// MOD(shattered-plains)
			// #ifndef TERRAIN_FLAT_MAP
			// 	// Option 1: Custom sampling
			// 	float ChasmAmount;
			// 	WoKGetChasmAmount(Vertex.WorldSpacePos.xz, ChasmAmount);

			// 	// Option 2: Abuse low-spec logic
			// 	float3 DetailDiffuse;
			// 	float4 DetailMaterial;
			// 	WoKCalculateDetailsLowSpec( Vertex.WorldSpacePos.xz, DetailDiffuse, DetailMaterial );

			// 	Vertex.WorldSpacePos.y -= 1000.0*DetailMaterial.r;
			// #endif
			// END MOD

			VS_OUTPUT_PDX_TERRAIN Out;
			Out.WorldSpacePos = Vertex.WorldSpacePos;

			Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Vertex.WorldSpacePos, 1.0 ) );
			Out.ShadowProj = mul( ShadowMapTextureMatrix, float4( Vertex.WorldSpacePos, 1.0 ) );

			return Out;
		}
		
		// Copies of the pixels shader CalcHeightBlendFactors and CalcDetailUV functions
		float4 CalcHeightBlendFactors( float4 MaterialHeights, float4 MaterialFactors, float BlendRange )
		{
			float4 Mat = MaterialHeights + MaterialFactors;
			float BlendStart = max( max( Mat.x, Mat.y ), max( Mat.z, Mat.w ) ) - BlendRange;
			
			float4 MatBlend = max( Mat - vec4( BlendStart ), vec4( 0.0 ) );
			
			float Epsilon = 0.00001;
			return float4( MatBlend ) / ( dot( MatBlend, vec4( 1.0 ) ) + Epsilon );
		}
		
		float2 CalcDetailUV( float2 WorldSpacePosXZ )
		{
			return WorldSpacePosXZ * DetailTileFactor;
		}
		
		// A low spec vertex buffer version of CalculateDetails
		void CalculateDetailsLowSpec( float2 WorldSpacePosXZ, out float3 DetailDiffuse, out float4 DetailMaterial )
		{
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
			//BlendFactors = DetailMask;
			
			DetailDiffuse = DiffuseTexture0.rgb * BlendFactors.x + 
							DiffuseTexture1.rgb * BlendFactors.y + 
							DiffuseTexture2.rgb * BlendFactors.z + 
							DiffuseTexture3.rgb * BlendFactors.w;
			
			DetailMaterial = vec4( 0.0 );
			
			for ( int i = 0; i < 4; ++i )
			{
				float BlendFactor = BlendFactors[i];
				if ( BlendFactor > 0.0 )
				{
					float3 ArrayUV = float3( DetailUV, DetailIndex[i] );
					float4 NormalTexture = PdxTex2DLod0( NormalTextures, ArrayUV );
					float4 MaterialTexture = PdxTex2DLod0( MaterialTextures, ArrayUV );

					DetailMaterial += MaterialTexture * BlendFactor;
				}
			}
		}
	
		VS_OUTPUT_PDX_TERRAIN_LOW_SPEC TerrainVertexLowSpec( float2 WithinNodePos, float2 NodeOffset, float NodeScale, float2 LodDirection, float LodLerpFactor )
		{
			STerrainVertex Vertex = CalcTerrainVertex( WithinNodePos, NodeOffset, NodeScale, LodDirection, LodLerpFactor );

			#ifdef TERRAIN_FLAT_MAP_LERP
				Vertex.WorldSpacePos.y = lerp( Vertex.WorldSpacePos.y, FlatMapHeight, FlatMapLerp );
			#endif
			#ifdef TERRAIN_FLAT_MAP
				Vertex.WorldSpacePos.y = FlatMapHeight;
			#endif

			VS_OUTPUT_PDX_TERRAIN_LOW_SPEC Out;
			Out.WorldSpacePos = Vertex.WorldSpacePos;

			Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Vertex.WorldSpacePos, 1.0 ) );
			Out.ShadowProj = mul( ShadowMapTextureMatrix, float4( Vertex.WorldSpacePos, 1.0 ) );
			
			CalculateDetailsLowSpec( Vertex.WorldSpacePos.xz, Out.DetailDiffuse, Out.DetailMaterial );
			
			float2 ColorMapCoords = Vertex.WorldSpacePos.xz * WorldSpaceToTerrain0To1;

#ifndef PDX_OSX
			Out.ColorMap = PdxTex2DLod0( ColorTexture, float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y ) ).rgb;
#else
			// We're limited to the amount of samplers we can bind at any given time on Mac, so instead
			// we disable the usage of ColorTexture (since its effects are very subtle) and assign a
			// default value here instead.
			Out.ColorMap = float3( vec3( 0.5 ) );
#endif

			Out.FlatMap = float3( vec3( 0.5f ) ); // neutral overlay
			#ifdef TERRAIN_FLAT_MAP_LERP
				Out.FlatMap = lerp( Out.FlatMap, PdxTex2DLod0( FlatMapTexture, float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y ) ).rgb, FlatMapLerp );
			#endif

			Out.Normal = CalculateNormal( Vertex.WorldSpacePos.xz );

			return Out;
		}
	]]
	
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_TERRAIN"
		Output = "VS_OUTPUT_PDX_TERRAIN"
		Code
		[[
			PDX_MAIN
			{
				return TerrainVertex( Input.UV, Input.NodeOffset_Scale_Lerp.xy, Input.NodeOffset_Scale_Lerp.z, Input.LodDirection, Input.NodeOffset_Scale_Lerp.w );
			}
		]]
	}

	MainCode VertexShaderSkirt
	{
		Input = "VS_INPUT_PDX_TERRAIN_SKIRT"
		Output = "VS_OUTPUT_PDX_TERRAIN"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDX_TERRAIN Out = TerrainVertex( Input.UV, Input.NodeOffset_Scale_Lerp.xy, Input.NodeOffset_Scale_Lerp.z, Input.LodDirection, Input.NodeOffset_Scale_Lerp.w );

				float3 Position = FixPositionForSkirt( Out.WorldSpacePos, Input.VertexID );
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Position, 1.0 ) );

				return Out;
			}
		]]
	}
	
	MainCode VertexShaderLowSpec
	{
		Input = "VS_INPUT_PDX_TERRAIN"
		Output = "VS_OUTPUT_PDX_TERRAIN_LOW_SPEC"
		Code
		[[
			PDX_MAIN
			{
				return TerrainVertexLowSpec( Input.UV, Input.NodeOffset_Scale_Lerp.xy, Input.NodeOffset_Scale_Lerp.z, Input.LodDirection, Input.NodeOffset_Scale_Lerp.w );
			}
		]]
	}

	MainCode VertexShaderLowSpecSkirt
	{
		Input = "VS_INPUT_PDX_TERRAIN_SKIRT"
		Output = "VS_OUTPUT_PDX_TERRAIN_LOW_SPEC"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDX_TERRAIN_LOW_SPEC Out = TerrainVertexLowSpec( Input.UV, Input.NodeOffset_Scale_Lerp.xy, Input.NodeOffset_Scale_Lerp.z, Input.LodDirection, Input.NodeOffset_Scale_Lerp.w );

				float3 Position = FixPositionForSkirt( Out.WorldSpacePos, Input.VertexID );
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Position, 1.0 ) );

				return Out;
			}
		]]
	}
}


PixelShader =
{
	# PdxTerrain uses texture index 0 - 6

	# Jomini specific
	TextureSampler ShadowMap
	{
		Ref = PdxShadowmap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		CompareFunction = less_equal
		SamplerType = "Compare"
	}

	# Game specific
	TextureSampler FogOfWarAlpha
	{
		Ref = JominiFogOfWar
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler FlatMapTexture
	{
		Ref = TerrainFlatMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler EnvironmentMap
	{
		Ref = JominiEnvironmentMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		Type = "Cube"
	}
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PDX_TERRAIN"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float3 WorldSpacePos = Input.WorldSpacePos;

				clip( vec2(1.0) - WorldSpacePos.xz * WorldSpaceToTerrain0To1 );

				float3 DetailDiffuse;
				float3 DetailNormal;
				float4 DetailMaterial;
				CalculateDetails( WorldSpacePos.xz, DetailDiffuse, DetailNormal, DetailMaterial );

				// MOD(shattered-plains)
				float ChasmValue = DetailMaterial.r;

				//float2 WoKChasmWorldSpacePosOffset = float2(0.0, -(0.5+0.5*sin(GlobalTime))) * ChasmValue;
				float2 WoKChasmWorldSpacePosOffset = float2(0.0, 0.0);

				CalculateDetails( WorldSpacePos.xz + WoKChasmWorldSpacePosOffset, DetailDiffuse, DetailNormal, DetailMaterial );

				// TODO: Start with camera-appropriate fade-to-black as "depth" increases
				//       and worry about UV/normals later.
				// END MOD

				float2 ColorMapCoords = WorldSpacePos.xz * WorldSpaceToTerrain0To1;
#ifndef PDX_OSX
				float3 ColorMap = PdxTex2D( ColorTexture, float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y ) ).rgb;
#else
				// We're limited to the amount of samplers we can bind at any given time on Mac, so instead
				// we disable the usage of ColorTexture (since its effects are very subtle) and assign a
				// default value here instead.
				float3 ColorMap = float3( vec3( 0.5 ) );
#endif
				
				float3 FlatMap = float3( vec3( 0.5f ) ); // neutral overlay
				#ifdef TERRAIN_FLAT_MAP_LERP
					FlatMap = lerp( FlatMap, PdxTex2D( FlatMapTexture, float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y ) ).rgb, FlatMapLerp );
				#endif

				float3 Normal = CalculateNormal( WorldSpacePos.xz );

				float3 ReorientedNormal = ReorientNormal( Normal, DetailNormal );

				DetailDiffuse = ApplyDynamicMasksDiffuse( DetailDiffuse, ReorientedNormal, ColorMapCoords );

				float3 Diffuse = GetOverlay( DetailDiffuse.rgb, ColorMap, ( 1 - DetailMaterial.r ) * COLORMAP_OVERLAY_STRENGTH );


				#ifdef TERRAIN_COLOR_OVERLAY
					float3 BorderColor;
					float BorderPreLightingBlend;
					float BorderPostLightingBlend;
					GetBorderColorAndBlendGame( WorldSpacePos.xz, FlatMap, BorderColor, BorderPreLightingBlend, BorderPostLightingBlend );

					Diffuse = lerp( Diffuse, BorderColor, BorderPreLightingBlend );

					#ifdef TERRAIN_FLAT_MAP_LERP
						float3 FlatColor;
						GetBorderColorAndBlendGameLerp( WorldSpacePos.xz, FlatMap, FlatColor, BorderPreLightingBlend, BorderPostLightingBlend, FlatMapLerp );
						
						FlatMap = lerp( FlatMap, FlatColor, saturate( BorderPreLightingBlend + BorderPostLightingBlend ) );
					#endif
				#endif

				#ifdef TERRAIN_COLOR_OVERLAY
					ApplyHighlightColor( Diffuse, ColorMapCoords );
				#endif

				float ShadowTerm = CalculateShadow( Input.ShadowProj, ShadowMap );

				SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse, ReorientedNormal, DetailMaterial.a, DetailMaterial.g, DetailMaterial.b );
				SLightingProperties LightingProps = GetSunLightingProperties( WorldSpacePos, ShadowTerm );

				float3 FinalColor = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );

				// MOD(shattered-plains)

				// Shift color into grayscale in proportion to chasm value (for debug)
				//FinalColor.r = lerp(FinalColor.r, FinalColor.g, ChasmValue);
				//FinalColor.b = lerp(FinalColor.b, FinalColor.g, ChasmValue);

				//
				// Fade to black as "depth" increases
				//

				static const float CHASM_VALUE_EPSIILON = 0.001;
				static const float CHASM_MAX_FAKE_DEPTH = 8.0;
				static const float CHASM_SAMPLE_RANGE   = 8.0;
				static const float CHASM_SAMPLE_STEP    = 0.25;

				if (ChasmValue > CHASM_VALUE_EPSIILON) // if we are somewhere inside the chasm
				{
					const float3 FromCamera       = WorldSpacePos - CameraPosition;
					const float3 FromCameraNorm   = normalize(FromCamera);
					const float3 FromCameraXZ     = float3(FromCamera.x, 0.0, FromCamera.z);
					const float3 FromCameraXZNorm = normalize(FromCameraXZ);
					const float  CameraAngleSin   = length(cross(FromCameraNorm, FromCameraXZNorm));
					const float  CameraAngleCos   = dot(FromCameraNorm, FromCameraXZNorm);
					const float  CameraAngleTan   = CameraAngleSin/CameraAngleCos;

					const float2 SampleDistanceUnit = normalize(FromCamera.xz);

					float SurfaceDistanceToBrink = CHASM_SAMPLE_RANGE;

					for (float SampleDistance = 0.0; SampleDistance < CHASM_SAMPLE_RANGE; SampleDistance += CHASM_SAMPLE_STEP)
					{
						const float2 SampleWorldSpacePosXZ = WorldSpacePos.xz + SampleDistance*SampleDistanceUnit;
						const float  SampledChasmValue     = WoKSampleChasmValue(SampleWorldSpacePosXZ);

						if (SampledChasmValue < CHASM_VALUE_EPSIILON)
						{
							SurfaceDistanceToBrink = SampleDistance;
							break;
						}
					}

					const float FakeDepth = CameraAngleTan*SurfaceDistanceToBrink;
					//const float FakeDepth = SurfaceDistanceToBrink/CameraAngleCos;

					//static const float3 DEBUG_DISTANCE_BASE_COLOR = (171.0, 119.0, 75.0) / 255.0;

					static const float BASE_COLOR_MULTIPLIER = 0.8;

					const float DepthColorMultiplier = 1.0 - saturate(FakeDepth / CHASM_MAX_FAKE_DEPTH);
					//const float DepthColorMultiplier = 1.0 - smoothstep(0.0, CHASM_MAX_FAKE_DEPTH, FakeDepth);
					const float ChasmColorMultiplier = BASE_COLOR_MULTIPLIER*DepthColorMultiplier;

					//FinalColor = (FakeDepth / CHASM_MAX_FAKE_DEPTH)*(1.0, 1.0, 1.0);
					FinalColor *= ChasmColorMultiplier;
					//FinalColor = CameraAngleTan*(1.0, 1.0, 1.0);
					//FinalColor = SurfaceDistanceToBrink*(0.1, 0.1, 0.1);
				}

				// END MOD

				#ifndef UNDERWATER
					FinalColor = ApplyFogOfWar( FinalColor, WorldSpacePos, FogOfWarAlpha );
					FinalColor = ApplyDistanceFog( FinalColor, WorldSpacePos );
				#endif

				#ifdef TERRAIN_COLOR_OVERLAY
					FinalColor.rgb = lerp( FinalColor.rgb, BorderColor, BorderPostLightingBlend );
				#endif

				#ifdef TERRAIN_COLOR_OVERLAY
					ApplyHighlightColor( FinalColor.rgb, ColorMapCoords, 0.25 );
				#endif

				#ifdef TERRAIN_FLAT_MAP_LERP
					FinalColor = lerp( FinalColor, FlatMap, FlatMapLerp );
				#endif

				float Alpha = 1.0;
				#ifdef UNDERWATER
					Alpha = CompressWorldSpace( WorldSpacePos );
				#endif

				#ifdef TERRAIN_DEBUG
					TerrainDebug( FinalColor, WorldSpacePos );
				#endif

				DebugReturn( FinalColor, MaterialProps, LightingProps, EnvironmentMap );
				return float4( FinalColor, Alpha );
			}
		]]
	}

	MainCode PixelShaderLowSpec
	{
		Input = "VS_OUTPUT_PDX_TERRAIN_LOW_SPEC"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				clip( vec2(1.0) - Input.WorldSpacePos.xz * WorldSpaceToTerrain0To1 );

				float3 DetailDiffuse = Input.DetailDiffuse;
				float4 DetailMaterial = Input.DetailMaterial;

				float2 ColorMapCoords = Input.WorldSpacePos.xz * WorldSpaceToTerrain0To1;

				float3 ColorMap = Input.ColorMap;
				float3 FlatMap = Input.FlatMap;

				float3 Normal = Input.Normal;
				
				DetailDiffuse = ApplyDynamicMasksDiffuse( DetailDiffuse, Normal, ColorMapCoords );

				float3 Diffuse = GetOverlay( DetailDiffuse.rgb, ColorMap, ( 1 - DetailMaterial.r ) * COLORMAP_OVERLAY_STRENGTH );
				float3 ReorientedNormal = Normal;

				#ifdef TERRAIN_COLOR_OVERLAY
					float3 BorderColor;
					float BorderPreLightingBlend;
					float BorderPostLightingBlend;
					GetBorderColorAndBlendGame( Input.WorldSpacePos.xz, FlatMap, BorderColor, BorderPreLightingBlend, BorderPostLightingBlend );

					Diffuse = lerp( Diffuse, BorderColor, BorderPreLightingBlend );

					#ifdef TERRAIN_FLAT_MAP_LERP
						float3 FlatColor;
						GetBorderColorAndBlendGameLerp( Input.WorldSpacePos.xz, FlatMap, FlatColor, BorderPreLightingBlend, BorderPostLightingBlend, FlatMapLerp );
						
						FlatMap = lerp( FlatMap, FlatColor, saturate( BorderPreLightingBlend + BorderPostLightingBlend ) );
					#endif 
				#endif

				//float ShadowTerm = CalculateShadow( Input.ShadowProj, ShadowMap );
				float ShadowTerm = 1.0;

				SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse, ReorientedNormal, DetailMaterial.a, DetailMaterial.g, DetailMaterial.b );
				SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowTerm );

				float3 FinalColor = CalculateSunLightingLowSpec( MaterialProps, LightingProps );

				#ifndef UNDERWATER
					FinalColor = ApplyFogOfWar( FinalColor, Input.WorldSpacePos, FogOfWarAlpha );
					FinalColor = ApplyDistanceFog( FinalColor, Input.WorldSpacePos );
				#endif

				#ifdef TERRAIN_COLOR_OVERLAY
					FinalColor.rgb = lerp( FinalColor.rgb, BorderColor, BorderPostLightingBlend );
				#endif

				#ifdef TERRAIN_COLOR_OVERLAY
					ApplyHighlightColor( FinalColor.rgb, ColorMapCoords );
				#endif

				#ifdef TERRAIN_FLAT_MAP_LERP
					FinalColor = lerp( FinalColor, FlatMap, FlatMapLerp );
				#endif

				float Alpha = 1.0;
				#ifdef UNDERWATER
					Alpha = CompressWorldSpace( Input.WorldSpacePos );
				#endif

				#ifdef TERRAIN_DEBUG
					TerrainDebug( FinalColor, Input.WorldSpacePos );
				#endif

				DebugReturn( FinalColor, MaterialProps, LightingProps, EnvironmentMap );
				return float4( FinalColor, Alpha );
			}
		]]
	}

	MainCode PixelShaderFlatMap
	{
		Input = "VS_OUTPUT_PDX_TERRAIN"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				clip( vec2(1.0) - Input.WorldSpacePos.xz * WorldSpaceToTerrain0To1 );

				float2 ColorMapCoords = Input.WorldSpacePos.xz * WorldSpaceToTerrain0To1;
				float3 FlatMap = PdxTex2D( FlatMapTexture, float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y ) ).rgb;

				#ifdef TERRAIN_COLOR_OVERLAY
					float3 BorderColor;
					float BorderPreLightingBlend;
					float BorderPostLightingBlend;
					
					GetBorderColorAndBlendGameLerp( Input.WorldSpacePos.xz, FlatMap, BorderColor, BorderPreLightingBlend, BorderPostLightingBlend, 1.0f );
					
					FlatMap = lerp( FlatMap, BorderColor, saturate( BorderPreLightingBlend + BorderPostLightingBlend ) );
				#endif

				float3 FinalColor = FlatMap;

				#ifdef TERRAIN_COLOR_OVERLAY
					ApplyHighlightColor( FinalColor, ColorMapCoords, 0.5 );
				#endif

				#ifdef TERRAIN_DEBUG
					TerrainDebug( FinalColor, Input.WorldSpacePos );
				#endif

				// FIXME: Temp
				float GrayscaleValue = saturate(0.33*FinalColor.r + 0.33*FinalColor.g + 0.33*FinalColor.b);
				FinalColor = (GrayscaleValue, GrayscaleValue, GrayscaleValue);
				// END FIXME

				//DebugReturn( FinalColor, lightingProperties, ShadowTerm );
				return float4( FinalColor, 1 );
			}
		]]
	}
}


Effect PdxTerrain
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"

	#Defines = { "PDX_HACK_ToSpecularLightDir WaterToSunDir" }
}

Effect PdxTerrainLowSpec
{
	VertexShader = "VertexShaderLowSpec"
	PixelShader = "PixelShaderLowSpec"

	#Defines = { "PDX_HACK_ToSpecularLightDir WaterToSunDir" }
}

Effect PdxTerrainSkirt
{
	VertexShader = "VertexShaderSkirt"
	PixelShader = "PixelShader"

	#Defines = { "PDX_HACK_ToSpecularLightDir WaterToSunDir" }
}

Effect PdxTerrainLowSpecSkirt
{
	VertexShader = "VertexShaderLowSpecSkirt"
	PixelShader = "PixelShaderLowSpec"

	#Defines = { "PDX_HACK_ToSpecularLightDir WaterToSunDir" }
}

Effect PdxTerrainFlat
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderFlatMap"

	Defines = { "TERRAIN_FLAT_MAP" }
}

Effect PdxTerrainFlatSkirt
{
	VertexShader = "VertexShaderSkirt"
	PixelShader = "PixelShaderFlatMap"

	Defines = { "TERRAIN_FLAT_MAP" }
}

# Low Spec flat map the same as regular effect
Effect PdxTerrainFlatLowSpec
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderFlatMap"

	Defines = { "TERRAIN_FLAT_MAP" }
}

Effect PdxTerrainFlatLowSpecSkirt
{
	VertexShader = "VertexShaderSkirt"
	PixelShader = "PixelShaderFlatMap"

	Defines = { "TERRAIN_FLAT_MAP" }
}
