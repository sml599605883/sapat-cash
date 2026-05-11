# Json 工具说明文档

本文档用于说明 `Json` 包装器的作用、功能、使用场景和边界要求。本文档不绑定具体文件名，后续如需在别的项目中重建同类能力，AI 可以自由命名实现，但必须保持相同的取值语义、容错行为和链式访问方式。

## 1. 核心作用

- 将任意动态 JSON 数据包装成一个统一访问器。
- 提供安全的链式取值能力，减少大量 `null`、类型判断和 `as` 转换代码。
- 统一处理 `Map`、`List`、`String`、`num`、`bool` 和 `null`。
- 作为项目中模型解析、接口响应读取和动态字段访问的基础工具。

## 2. 主要能力

### 2.1 构造与解析

- 支持直接包装任意 `dynamic` 对象。
- 支持从 JSON 字符串解析。
- 支持从字节数组解析。
- 解析失败时不会抛出异常到外层，而是退化为 `null` 状态。

### 2.2 类型访问

- 支持通过 `mapValue`、`listValue`、`boolValue`、`numValue`、`intValue`、`doubleValue`、`stringValue` 获取非空值。
- 支持通过 `mapOrNull`、`listOrNull`、`boolOrNull`、`numOrNull`、`intOrNull`、`doubleOrNull`、`stringOrNull` 获取可空值。
- 支持 `exists()` 与 `isNull()` 判断对象是否存在。

### 2.3 索引访问

- 支持使用 `json['key']` 访问对象字段。
- 支持使用 `json[index]` 访问列表元素。
- 索引访问返回的仍然是 `Json` 包装器，便于继续链式访问。

### 2.4 可变写入

- 支持通过 `[]=` 修改 map 或 list 的值。
- 如果当前对象类型与写入 key 类型不匹配，会重建为对应的 map 或 list。
- 支持删除 map key 或 list index。

### 2.5 序列化

- 支持 `rawString()` 输出 JSON 字符串。
- 支持 `prettyPrint` 格式化输出。
- `toString()` 等价于 `rawString()`。

## 3. 类型转换规则

- `boolValue`
  - `bool` 原值直接返回
  - `num` 按是否为 0 转换
  - `String` 识别 `true`、`y`、`t`、`yes`、`1`
  - 其他情况返回 `false`
- `numValue`
  - `String` 优先尝试 `int`，再尝试 `double`
  - `bool` 转为 `1` 或 `0`
  - 其他情况返回 `0`
- `intValue`
  - 基于 `numValue.toInt()`
- `doubleValue`
  - 基于 `numValue.toDouble()`
- `stringValue`
  - `String` 原样返回
  - `num` 和 `bool` 转字符串
  - 其他情况返回空串

## 4. 适合使用的场景

- 接口响应解析。
- 动态 JSON 结构读取。
- 字段可能缺失、类型不稳定或层级不固定的模型转换。
- 页面层从 `states` 中读取跳转地址、状态码、按钮列表、文案等动态字段。
- 需要同时兼容 `Map`、`List`、标量值和 `null` 的场景。

## 5. 项目中的典型使用点

### 5.1 网络响应壳

- 统一响应模型会把 `states` 包装成 `Json`，用于后续链式读取。
- 当响应不是标准对象时，会通过 `Json` 的容错逻辑降级处理。

### 5.2 业务模型解析

- 首页、银行卡、认证、城市、订单、弹窗、上传结果等模型都依赖 `Json` 读取动态字段。
- 常见模式是 `json['field'].stringValue.trim()`、`json['list'].listValue`、`json['flag'].intValue`。

### 5.3 页面与路由逻辑

- 页面和路由辅助层会直接从 `response.states` 读取跳转链接、状态码、按钮参数、弹窗内容。
- 这类逻辑依赖 `Json` 的安全默认值，避免某个字段缺失直接崩溃。

### 5.4 Report 与工具类

- `rawString()` 会被用于把 payload 转成 JSON 再加密或上报。
- 设备信息上报的空 payload 也依赖 `Json(<String, dynamic>{}).rawString()` 生成空 JSON 字符串。

## 6. 使用原则

- 只在动态 JSON 或协议不稳定的数据上使用，不要替代强类型模型。
- 不要把业务规则塞进 `Json` 本身，它只负责包装、读取和容错。
- 需要强校验的关键字段仍应由业务层判断是否为空或是否符合枚举。
- 如果能确定结构稳定，优先用强类型模型，`Json` 只作为输入层和过渡层。

## 7. 约束与注意事项

- `mapValue` 和 `listValue` 都是非空返回，空结构会退化成空集合。
- 类型不匹配时通常不会抛异常，而是返回安全默认值。
- `Json` 不做深层 schema 校验。
- `parse` / `parseBytes` 解析失败时会退化为 `null`，不要把它当成必然有效的反序列化器。
- `rawString()` 依赖底层对象可序列化，不能用来替代任意复杂对象的自定义编码器。

## 8. 适配建议

- 如果后续 AI 需要重建同类工具，必须保留：
  - 动态包装
  - 链式索引
  - 安全默认值
  - JSON 字符串/字节解析
  - 原对象序列化
- 如果项目未来要换成强类型 JSON 工具，也应先保留一层兼容包装，避免大范围改动现有模型和页面逻辑。
