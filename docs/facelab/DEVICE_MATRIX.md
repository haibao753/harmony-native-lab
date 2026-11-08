# FaceLab 设备兼容性记录

最后核对：2026-11-08。

| 项目 | 已知信息 | 状态 |
|---|---|---|
| 目标设备 | MatePad Pro 13.2（2023） | 用户提供 |
| 系统版本 | HarmonyOS 7.0.0.111 SP8 | 用户提供 |
| Compile SDK | 26.0.0 | 用户提供 |
| AR Engine FACE | 需要在真机运行时探测 | 未验证 |
| AR Engine DEPTH | 需要在真机运行时探测 | 未验证 |
| dToF 原始数据访问 | 不能由硬件规格推断普通应用可访问 | 不作假设 |
| 模拟器 | AR Engine 文档说明不支持 | 不适用 |

## 官方支持列表核对

华为当前公开的 HarmonyOS AR Engine 支持机型列表中，列出了 **MatePad Pro 13.2 英寸 2025 全系列（全特性支持）**，但没有列出 MatePad Pro 13.2 英寸 2023 款。

因此：
- 不把 2023 款标记为官方支持。
- 不因设备有前置 dToF 或系统为 HarmonyOS 7 就推断 FACE 能力可用。
- 以应用内 `arViewController.isARTypeSupported(ARENGINE_FEATURE_TYPE_FACE)` 的真机结果作为第一手证据。
- 若返回不支持或错误码 801，记录系统版本、设备型号和错误码，不反复假设升级 SDK 就能解决。

## 测试记录

| 日期 | 系统 | FACE | DEPTH | 备注 |
|---|---|---|---|---|
| 待测 | 7.0.0.111 SP8 | 待测 | 待测 | 首次真机验证 |

## 来源
- [AR Engine 支持机型列表（华为开发者联盟）](https://developer.huawei.com/consumer/cn/forum/topic/0208215774177333398)
- [AR Engine 开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arengine-preparations/)
