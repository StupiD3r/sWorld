Shader "Custom/OceanPlanet"
{
    Properties
    {
        _Color ("Ocean Color", Color) = (0.043, 0.239, 0.569, 1)
        _WaveSpeed ("Wave Speed", Float) = 0.5
        _WaveScale ("Wave Scale", Float) = 2.0
        _WaveHeight ("Wave Height", Float) = 0.02
        _Smoothness ("Smoothness", Range(0,1)) = 0.95
        _Metallic ("Metallic", Range(0,1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float3 worldNormal;
            INTERNAL_DATA
        };

        fixed4 _Color;
        float _WaveSpeed;
        float _WaveScale;
        float _WaveHeight;
        half _Smoothness;
        half _Metallic;

        float2 Unity_GradientNoise_Dir(float2 p)
        {
            float x = sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453;
            return normalize(float2(x - floor(x), frac(x)) - 0.5);
        }

        float Unity_GradientNoise(float2 p)
        {
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.worldPos.xz * _WaveScale * 0.1;
            float time = _Time.y * _WaveSpeed;
            
            float wave1 = Unity_GradientNoise(uv + float2(time * 0.1, 0));
            float wave2 = Unity_GradientNoise(uv * 1.5 + float2(0, time * 0.15));
            float wave3 = Unity_GradientNoise(uv * 0.5 - float2(time * 0.08, time * 0.05));
            
            float combinedWave = (wave1 + wave2 * 0.5 + wave3 * 0.25) / 1.75;
            
            float3 worldNormal = WorldNormalVector(IN, float3(0, 1, 0));
            float fresnel = pow(1.0 - saturate(dot(normalize(IN.worldPos - _WorldSpaceCameraPos), worldNormal)), 3.0);
            
            fixed4 oceanColor = _Color;
            float depthVariation = combinedWave * 0.15;
            oceanColor.rgb += depthVariation;
            oceanColor.rgb += fresnel * 0.3;
            
            o.Albedo = oceanColor.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
