Shader "GetStartedShader/ToonOpaque"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ShadowThreshold("Shadow Threshold", Range(-1.0, 1.0)) = 0.0
        _ShadowColor("Shadow Color", Color) = (0.5, 0.5, 0.5, 1.0)
        [HDR] _SpecularColor("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPower("Specular Power", float) = 20.0
        _SpecularThreshold("Specular Threshold", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;

            half _ShadowThreshold;
            half4 _ShadowColor;

            half4 _SpecularColor;
            half _SpecularPower;
            half _SpecularThreshold;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 normalDir = normalize(i.worldNormal);
                half3 worldLightDir = normalize(_MainLightPosition.xyz);    // URP已舍弃UnityWorldspaceLightDir
                
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);   // URP已舍弃UnityWorldSpaceViewDir
                half3 halfDir = normalize(worldLightDir + viewDir);

                half3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;;
                
                half nl = dot(worldLightDir, normalDir);
                half3 diff = nl > _ShadowThreshold ? 1.0 : _ShadowColor.rgb;

                half nh = dot(normalDir, halfDir);
                half3 spec = pow (max(nh, 1e-5), _SpecularPower) > _SpecularThreshold ? _SpecularColor.rgb : 0.0;
                half3 col = (diff + spec) * albedo;
                return half4(col, 1.0);;
            }
            ENDHLSL
        }
    }
}
