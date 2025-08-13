Shader "Examples/HelloWorld"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
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
            // HLSL code goes here
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                return o;
            }

            float4 _BaseColor;

            float4 frag(v2f i) : SV_Target
            {
                return _BaseColor;
            }
            ENDHLSL
        }
    }
    
    Fallback "Unlit/Color"
}
