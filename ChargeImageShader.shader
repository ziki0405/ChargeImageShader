Shader "UI/ChargeImageShader"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _BaseColor ("Base Color", Color) = (1,1,1,1)    // 新增底色
        _FillAmount ("Fill Amount", Range(0, 1)) = 0.5
        _FillColor ("Fill Color", Color) = (0.5, 0.5, 0.5, 0.5)
        [Toggle] _Clockwise ("Clockwise Fill", Float) = 1

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _BaseColor;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;

            float _FillAmount;
            fixed4 _FillColor;
            float _Clockwise;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                // 采样原始纹理
                half4 texColor = tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd;

                // 先用BaseColor混合原始纹理 → 这样整个底色可调
                texColor.rgb *= _BaseColor.rgb;
                texColor.a *= _BaseColor.a;

                // 再乘以顶点Tint
                half4 color = texColor * IN.color;

                // UV中心化 → 计算角度
                float2 uv = IN.texcoord - 0.5;
                float angle = atan2(uv.y, uv.x);

                // 把 12点方向作为起点 (减去90度)
                angle -= 3.14159 * 0.5;

                // 保证角度在0~2PI正范围
                angle = fmod(angle + 2.0 * 3.14159, 2.0 * 3.14159);

                // 归一化到0~1
                angle = angle / (2.0 * 3.14159);

                // 顺时针反转
                if (_Clockwise > 0.5)
                {
                    angle = 1.0 - angle;
                }

                // 如果角度大于填充量，替换成FillColor
                if (angle > _FillAmount)
                {
                    color.rgb = lerp(color.rgb, _FillColor.rgb, _FillColor.a);
                }

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }
        ENDCG
        }
    }
}
