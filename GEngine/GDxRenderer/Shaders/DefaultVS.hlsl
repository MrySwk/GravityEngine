struct Light
{
	float3 Strength;
	float FalloffStart; // point/spot light only
	float3 Direction;   // directional/spot light only
	float FalloffEnd;   // point/spot light only
	float3 Position;    // point light only
	float SpotPower;    // spot light only
};

struct VertexInput
{
	float3 pos		: POSITION;
	float2 uv		: TEXCOORD;
	float3 normal	: NORMAL;
	float3 tangent	: TANGENT;
};

struct VertexOutput
{
	float4 pos			: SV_POSITION;
	float2 uv			: TEXCOORD;
	float3 normal		: NORMAL;
	float3 tangent		: TANGENT;
	float3 worldPos		: POSITION0;
	float4 ssaoPos		: POSITION1;
	float linearZ : LINEARZ;
	float4 shadowPos	: SHADOWPOS;
};

/*
cbuffer ConstantBuffer : register(b0)
{
	float4x4 worldViewProjection;
	float4x4 world;
	float4x4 view;
	float4x4 projection;
	float4x4 shadowView;
	float4x4 shadowProjection;
	float2	 uvScale;
};
cbuffer PerFrame : register(b1)
{
	float nearZ;
	float farZ;
	float2 lightPerspectiveValues;
};
*/

// Constant data that varies per frame.

cbuffer cbPerObject : register(b0)
{
	float4x4 gWorld;
	float4x4 gTexTransform;
	uint gMaterialIndex;
	uint gObjPad0;
	uint gObjPad1;
	uint gObjPad2;
};

// Constant data that varies per material.
cbuffer cbPass : register(b1)
{
	float4x4 gView;
	float4x4 gInvView;
	float4x4 gProj;
	float4x4 gInvProj;
	float4x4 gViewProj;
	float4x4 gInvViewProj;
	float4x4 gViewProjTex;
	float4x4 gShadowTransform;
	float3 gEyePosW;
	float cbPerObjectPad1;
	float2 gRenderTargetSize;
	float2 gInvRenderTargetSize;
	float gNearZ;
	float gFarZ;
	float gTotalTime;
	float gDeltaTime;
	float4 gAmbientLight;

	// Indices [0, NUM_DIR_LIGHTS) are directional lights;
	// indices [NUM_DIR_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHTS) are point lights;
	// indices [NUM_DIR_LIGHTS+NUM_POINT_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHT+NUM_SPOT_LIGHTS)
	// are spot lights for a maximum of MaxLights per object.
	Light gLights[16];
};

float2 ProjectionConstants(float gNearZ, float gFarZ)
{
	float2 projectionConstants;
	projectionConstants.x = gFarZ / (gFarZ - gNearZ);
	projectionConstants.y = (-gFarZ * gNearZ) / (gFarZ - gNearZ);
	return projectionConstants;
}

float LinearZ(float4 outPosition)
{
	float2 projectionConstants = ProjectionConstants(gNearZ, gFarZ);
	float depth = outPosition.z / outPosition.w;
	float linearZ = projectionConstants.y / (depth - projectionConstants.x);
	return linearZ;
}

VertexOutput main(VertexInput input)
{
	VertexOutput output;
	//float4x4 shadowVP = mul(mul(world, shadowView), shadowProjection);

	// Fetch the material data.
	//MaterialData matData = gMaterialData[gMaterialIndex];

	// Transform to world space.
	//float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
	//vout.PosW = posW.xyz;

	// Assumes nonuniform scaling; otherwise, need to use inverse-transpose of world matrix.
	//vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);

	//vout.TangentW = mul(vin.TangentU, (float3x3)gWorld);

	// Transform to homogeneous clip space.
	//vout.PosH = mul(posW, gViewProj);

	// Generate projective tex-coords to project SSAO map onto scene.
	//vout.SsaoPosH = mul(posW, gViewProjTex);

	//output.pos = mul(float4(input.pos, 1.0f), worldViewProjection);
	float4 worldPos = mul(float4(input.pos, 1.0f), gWorld);
	output.pos = mul(worldPos, gViewProj);
	//input.uv.x = uvScale.x * input.uv.x;
	//input.uv.y = uvScale.y * input.uv.y;
	output.uv = input.uv;
	output.normal = normalize(mul(input.normal, (float3x3)gWorld));
	output.tangent = normalize(mul(input.tangent, (float3x3)gWorld));
	output.worldPos = mul(float4(input.pos, 1.0f), gWorld).xyz;
	output.linearZ = LinearZ(output.pos);
	//output.shadowPos = mul(float4(input.pos, 1.0f), shadowVP);
	output.shadowPos = mul(float4(input.pos, 1.0f), gShadowTransform);
	output.ssaoPos = mul(worldPos, gViewProjTex);
	return output;
}