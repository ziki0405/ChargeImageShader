# ChargeImageShader

**ChargeImageShader** 是一个适用于 **Unity UI (UGUI)** 的环形/扇形填充 Shader，可用于 **技能冷却圈、充能进度条、倒计时遮罩** 等 UI 特效。

---

## Features

- 从 **12 点方向** 开始填充  
- 支持 **顺时针 / 逆时针** 切换  
- 可独立控制 **底色** 和 **填充区域颜色**  
- 兼容 Unity UI **Mask / ClipRect / Stencil**  
- 可动态控制 **_FillAmount** 实现进度动画  


---

## Installation

1. 将 `ChargeImageShader.shader` 放入 `Assets/Shaders/`
2. 在 Unity 中 **右键 → Create → Material**，选择 `Shader > UI > ChargeImageShader`
3. 将材质赋值给目标 **UI Image** 组件

---

## Usage

1. 在 **Image** 组件上使用该 Shader 材质  
2. 调整 **_FillAmount** 观察扇形填充效果  
3. 通过 **_BaseColor** / **_FillColor** 改变底色和填充颜色  
4. **_Clockwise** 控制顺时针 / 逆时针  

### Example Script

```csharp
using UnityEngine;
using UnityEngine.UI;

public class ChargeDemo : MonoBehaviour
{
    public Image chargeImage; // 使用该 Shader 的 Image
    public float chargeTime = 3f;
    private float timer;

    void Update()
    {
        // FillAmount 从 0 到 1 循环
        timer += Time.deltaTime;
        float progress = Mathf.PingPong(timer / chargeTime, 1f);

        // 设置填充量
        chargeImage.material.SetFloat("_FillAmount", progress);

        // 空格切换顺/逆时针
        if (Input.GetKeyDown(KeyCode.Space))
        {
            bool clockwise = chargeImage.material.GetFloat("_Clockwise") > 0.5f;
            chargeImage.material.SetFloat("_Clockwise", clockwise ? 0 : 1);
        }
    }
}
