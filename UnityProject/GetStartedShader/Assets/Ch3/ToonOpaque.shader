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
        _OutlineWidth("Outline Width", Range(0.0, 10.0)) = 1.0
        _OutlineColor("Outline Color", Color) = (0.2, 0.2, 0.2, 1.0)
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
                "LightMode"="SRPDefaultUnlit"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
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
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
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

                half3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // ambient lighting
                float4 SHCoeffcients[7];
                SHCoeffcients[0] = unity_SHAr;
                SHCoeffcients[1] = unity_SHAg;
                SHCoeffcients[2] = unity_SHAb;
                SHCoeffcients[3] = unity_SHBr;
                SHCoeffcients[4] = unity_SHBg;
                SHCoeffcients[5] = unity_SHBb;
                SHCoeffcients[6] = unity_SHC;
                // 受光照方向影响的环境光
                half3 ambient = SampleSH9(SHCoeffcients, normalDir);
                // 如果不需要计算光照方向，比如卡通渲染，就不用计算法线， 可以直接给一个固定值
                half3 ambientNoDir = SampleSH9(SHCoeffcients, half3(0.0, 1.0, 0.0));
                // 也可以用下面这个 不收法线影响似乎可以用下面这个直接获取环境光 但是颜色会偏暗
                half3 ambientNoDir1 = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                // Diffuse lighting
                half nl = dot(worldLightDir, normalDir); // Range[-1, 1]
                half3 diff = nl > _ShadowThreshold ? 1.0 : _ShadowColor.rgb;

                // Specular lighting
                half nh = dot(normalDir, halfDir);
                half3 spec = pow (max(nh, 1e-5), _SpecularPower) > _SpecularThreshold ? _SpecularColor.rgb : 0.0;

                Light mainLight = GetMainLight();
                half3 lightColor = mainLight.color;
                half3 col = ambientNoDir * albedo.rgb + (diff + spec) * albedo * lightColor;
                return half4(col, 1.0);;
            }
            ENDHLSL
        }

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            
            Cull Front
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;

            float _OutlineWidth;
            half4 _OutlineColor;

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
                // float3 worldNormal : TEXCOORD1;
                // float3 worldPos : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;

                float3 viewPos = TransformWorldToView(TransformObjectToWorld(v.vertex.xyz));
                float3 viewNormal = mul((float3x3) UNITY_MATRIX_MV, v.normal);
                viewNormal.z = -0.5;
                viewPos = viewPos + normalize(viewNormal) * _OutlineWidth * 0.002;
                o.vertex = mul(UNITY_MATRIX_P, float4(viewPos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                
                half3 col = albedo * _OutlineColor.rgb;
                return half4(col, 1.0);;
            }
            ENDHLSL
        }
    }
}
