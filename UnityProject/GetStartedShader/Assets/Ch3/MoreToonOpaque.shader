Shader "GetStartedShader/MoreToonOpaque"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _GradientMap("Gradient Map", 2D) = "white" {}
        
        _ShadowColor1stTex("Shadow Color 1st Texture", 2D) = "white" {}
        _ShadowColor1st("Shadow Color 1st", Color) = (1.0, 1.0, 1.0, 1.0)
        _ShadowColor2ndTex("Shadow Color 2nd Texture", 2D) = "white" {}
        _ShadowColor2nd("Shadow Color 2nd", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [HDR] _SpecularColor("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPower("Specular Power", float) = 20.0
        
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
            sampler2D _GradientMap;

            sampler2D _ShadowColor1stTex;
            half4 _ShadowColor1st;
            sampler2D _ShadowColor2ndTex;
            half4 _ShadowColor2nd;

            half4 _SpecularColor;
            half _SpecularPower;

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
                half2 diffGradient = tex2D(_GradientMap, float2(nl * 0.5 + 0.5, 0.5)).rg; // nl > _ShadowThreshold ? 1.0 : _ShadowColor.rgb;
                half3 diffAlbedo = lerp(albedo.rgb, tex2D(_ShadowColor1stTex, i.uv) * _ShadowColor1st.rgb, diffGradient.x);
                diffAlbedo = lerp(diffAlbedo, tex2D(_ShadowColor2ndTex, i.uv) * _ShadowColor2nd.rgb, diffGradient.y);
                half3 diff = diffAlbedo;

                // Specular lighting
                half nh = dot(normalDir, halfDir);
                half specGradient = tex2D(_GradientMap, float2(pow(max(nh, 1e-5), _SpecularPower), 0.5)).b;
                half3 spec = specGradient * albedo.rgb * _SpecularColor.rgb;

                // Combine all
                Light mainLight = GetMainLight();
                half3 lightColor = mainLight.color;
                half3 col = ambientNoDir * albedo.rgb + (diff + spec) * lightColor;
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
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;

                float3 viewPos = TransformWorldToView(TransformObjectToWorld(v.vertex));
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
