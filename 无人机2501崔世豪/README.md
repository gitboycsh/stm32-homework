# 第 7 周 一页记录

> **姓名**：无人机2501 崔世豪　|　**周期**：2026/10/10（周六）　|　**工程**：first work2.0
> **芯片**：STM32F103C8T6（LQFP48）　|　**Git 提交号**：`83fa082`（`T1: 让板载 LED 按 1000ms 闪烁，并记录时钟树三格数`）

---

| 栏 | 内容 |
| :--- | :--- |
| **做什么** | 这周我让板载 LED（PC13）按 **1000 毫秒** 闪烁，并读出了 CubeMX 时钟树上的**三格数**：SYSCLK = 72 MHz、HCLK = 72 MHz、PCLK1 = 36 MHz。 |
| **怎么做** | ① 在 CubeMX 里把 PC13 配成 `GPIO_Output`，User Label 填 `LED111`，初始电平 High（板载 LED 低电平点亮）；② 时钟页确认 HSE 8 MHz → PLL ×9 → SYSCLK 72 MHz；③ `GENERATE CODE` 生成工程；④ 在 `main.c` 的 `while(1)` 里写 `HAL_GPIO_TogglePin(LED111_GPIO_Port, LED111_Pin)` + `HAL_Delay(1000)`；⑤ 编译（`Ctrl+B`）→ 烧录 → 观察 LED。<br><br>**卡最久的地方（约 3 小时）**：<br>• **卡点 1 — 编译 27 个错误**：工程把 `Drivers/CMSIS` 下整个 DSP / NN / RTOS2 库都当源码编译了，报 `os_tick.h`、`arm_math.h` 找不到。查清后把 8 个无关目录移出工程（备份在 `_cmsis_backup`），剩余只留 `CMSIS/Device` 和 `CMSIS/Include`，编译即 0 错误。<br>• **卡点 2 — 改了 `HAL_Delay` 但闪灯频率没变**：原因是只编译没烧录，芯片里仍是旧程序。回读芯片 Flash 反汇编，看到指令是 `mov.w r0, #500`（旧），而新固件是 `#1000`，确认是"没烧进去"而不是"改了没用"。<br>• **卡点 3 — CubeIDE 的烧录按钮弹 ST-Link 固件升级窗**：CubeIDE 自带升级工具（`STLinkUpgrade.jar`）比本机 ST-Link 硬件（FW `V2J37S7`）旧，工具内置文案为 `STLink hardware probably too recent for this upgrade version`，读不出固件版本 → 误判"需要升级"→ 调试会话无法启动。最终改用 `STM32_Programmer_CLI` 烧录，并写成 `flash.bat` 一键"编译 + 烧录 + 复位"。 |
| **证据** | **① 三格数具体数值**：`SYSCLK = 72 MHz`（系统时钟）、`HCLK = 72 MHz`（AHB 总线）、`PCLK1 = 36 MHz`（APB1 总线）。<br>**② 时钟链路**：HSE 外部晶振 8 MHz → ÷1 → PLL ×9 → PLLCLK 72 MHz → 选作 SYSCLK → AHB ÷1 → HCLK 72 MHz → APB1 ÷2 → PCLK1 36 MHz。<br>**③ 附带读数**：PCLK2 = 72 MHz；**APB1 定时器时钟 = 72 MHz**（不是 36 —— APB 预分频 >1 时定时器时钟自动 ×2）。<br>**④ 实验对照**：AHB Prescaler 由 ÷1 改为 ÷2 后，HCLK 72 → 36 MHz，同样的 `HAL_Delay(1000)` 实际延时由约 1 秒变为约 2 秒，LED 明显变慢（已改回 ÷1）。<br>**⑤ 视频/照片**：见 `evidence/` 目录 —— `01_led_1000ms.mp4`（1000 毫秒闪烁）、`02_led_100ms.mp4`（100 毫秒闪烁，快慢对比）、`03_clock_tree.png`（CubeMX 时钟树截图，含三格数）。<br>**⑥ Git 提交号**：`83fa082`（提交信息：`T1: 让板载 LED 按 1000ms 闪烁，并记录时钟树三格数`）。 |
| **下一步** | • **还没搞懂**：APB1 定时器时钟那个"×2"规则的硬件实现细节 —— 为什么预分频 >1 才触发倍频，预分频 =1 时为什么不倍频。<br>• **下周想确认**：串口波特率与时钟的定量关系（72 MHz / 36 MHz 下 `BRR` 寄存器怎么算），并实测 UART 在时钟配错时是否必然乱码。<br>• **待办**：把 CubeIDE 的调试功能修好（当前只能用命令行烧录，无法打断点单步），办法是换一根固件较旧的 ST-Link，或用 CubeProgrammer 重新刷写固件后验证。 |

---

## 附：本周关键数据速查

| 项目 | 配置 |
| :--- | :--- |
| 芯片型号 | STM32F103C8T6（LQFP48，64 KB Flash） |
| 外部晶振 | HSE 8 MHz |
| SYSCLK | 72 MHz |
| HCLK | 72 MHz |
| PCLK1（APB1） | 36 MHz |
| PCLK2（APB2） | 72 MHz |
| APB1 定时器时钟 | 72 MHz（⚠️ 非 36） |
| Flash 等待周期 | 2（`FLASH_LATENCY_2`） |
| LED 引脚 | PC13（CubeMX 宏：`LED111_Pin` / `LED111_GPIO_Port`） |
| 调试接口 | SWD（PA13 = SWDIO，PA14 = SWCLK） |
| 烧录方式 | `flash.bat`（调用 `STM32_Programmer_CLI`，绕过 CubeIDE 固件检测） |

## 附：注意事项（本周踩坑总结）

1. **改完代码必须"编译 + 烧录"两步**。只按 `Ctrl+B` 只是编译，芯片里跑的仍是旧程序 —— 这是本周最大的时间浪费来源。
2. **串口乱码第一反应查时钟，不是查线**。波特率是从时钟算出来的。
3. **不要背时钟数字**。不同型号上限不同（如 STM32F407 的 SYSCLK 是 168 MHz），要会看时钟树。
4. **工程名不要带空格**。`first work2.0` 里的空格会导致 `makefile` 中 `arm-none-eabi-size $(EXECUTABLES)` 未加引号而报错，出现"假 Build Failed"。
