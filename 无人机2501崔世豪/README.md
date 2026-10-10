# 第 7 周 一页记录

> **姓名**：无人机2501 崔世豪　|　**周期**：2026/10/10（周六）　|　**工程**：first work2.0
> **芯片**：STM32F103C8T6（LQFP48）　|　**Git 提交号**：`bf8176b`（`chore: 提交脚本支持自动检测代理`）
>
> 注：Git 提交号无法写进它自己那次提交（哈希自引用），因此本记录中的提交号指向**包含本次周报内容的那一次提交**（见下方提交历史）。

---

| 栏 | 内容 |
| :--- | :--- |
| **做什么** | 这周我让板载 LED（PC13）按 **500 毫秒** 闪烁，并读出了 CubeMX 时钟树上的**三格数**：SYSCLK = 72 MHz、HCLK = 72 MHz、PCLK1 = 36 MHz。 |
| **怎么做** | ① 在 CubeMX 里把 PC13 配成 `GPIO_Output`，User Label 填 `LED111`，初始电平 High（板载 LED 低电平点亮）；<br>② 时钟页确认 HSE 8 MHz → PLL ×9 → SYSCLK 72 MHz；<br>③ `GENERATE CODE` 生成工程；<br>④ 在 `main.c` 的 `while(1)` 里写 `HAL_GPIO_TogglePin(LED111_GPIO_Port, LED111_Pin)` + `HAL_Delay(500)` 并加上了中文注释；<br>⑤ 编译 → 烧录 → 观察 LED。<br><br>**卡最久的地方**：<br>• **卡点 1 — 改了 `HAL_Delay` 但闪灯频率没变**：原因是只编译没烧录，芯片里仍是旧程序。<br>• **卡点 2 — CubeIDE 的烧录按钮弹 ST-Link 固件升级窗**：CubeIDE 自带升级工具（`STLinkUpgrade.jar`）比本机 ST-Link 硬件（FW `V2J37S7`）旧，工具内置文案为 `STLink hardware probably too recent for this upgrade version`，读不出固件版本 → 误判"需要升级"→ 调试会话无法启动。最终改用 `STM32_Programmer_CLI` 烧录，并写成 `flash.bat` 一键"编译 + 烧录 + 复位"。 |
| **证据** | **① 三格数具体数值**：`SYSCLK = 72 MHz`（系统时钟）、`HCLK = 72 MHz`（AHB 总线）、`PCLK1 = 36 MHz`（APB1 总线）。<br>**② 时钟链路**：HSE 外部晶振 8 MHz → ÷1 → PLL ×9 → PLLCLK 72 MHz → 选作 SYSCLK → AHB ÷1 → HCLK 72 MHz → APB1 ÷2 → PCLK1 36 MHz。<br>**③ 附带读数**：PCLK2 = 72 MHz；**APB1 定时器时钟 = 72 MHz**（不是 36 —— APB 预分频 >1 时定时器时钟自动 ×2）。<br>**④ 实验对照**：AHB Prescaler 由 ÷1 改为 ÷2 后，HCLK 72 → 36 MHz，同样的 `HAL_Delay(500)` 实际延时由约 0.5 秒变为约 1 秒，LED 明显变慢。
| **下一步** | 把 CubeIDE 的调试功能修好（当前只能用命令行烧录，无法打断点单步），办法是换一根固件较旧的 ST-Link，或用 CubeProgrammer 重新刷写固件后验证。 |
| **怎么把"连不上"救回来的** | 踩了 3 次坑，原因都不一样。**关键结论：软件报错 ≠ 硬件坏了**（3 次里 2 次是软件误判）。做法：把报错发给 AI（DeepSeekharness）一步步引导排查。<br><br>**① 点烧录就弹 ST-Link 固件升级窗，烧不进去**<br>原因：CubeIDE 那个升级小工具太老，不认识我的固件（`V2J37S7` 比工具还新），读不出版本就误判"该升级"，把烧录拦住了。<br>查：命令行一问就清楚 —— `--list` 读出固件 `V2J37S7`，`-c port=SWD` 读出芯片 `Device ID 0x410`、供电 `3.29V`，硬件全正常。<br>解：不用那个按钮，改成命令行烧，做成 `flash.bat` 一键搞定。<br><br>**② 设备管理器冒出黄叹号"未知 USB 设备"，错误代码 43**<br>原因：**那玩意儿根本不是 ST-Link**。ST-Link 编号是 `0483` 开头，它是 `0000`（没编号的野设备）。是我把下载器和供电的USB同时接到了电脑上，所以导致识别错误。<br>解：拔掉它；ST-Link 从前面板换到主机后面板 USB 口。<br><br>**③ 代码改了、提示烧录成功，可灯没变**<br>原因：**新程序没进芯片**，板上还是旧的。<br>查：读回芯片内容对比 —— 芯片里是 `mov.w r0, #1000`，新固件是 `#500`，确认"没烧进去"。<br>解：重烧 + 回读校验，确认变成 `#500`。
