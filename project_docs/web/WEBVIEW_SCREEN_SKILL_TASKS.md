# 通用 WebView 容器 Skill 与任务清单

## 1. 文档目标
- 本文件不是某个具体页面或文件名的说明书，而是一份可跨项目复用的 WebView 容器开发与排查 Skill。
- 适用于 Flutter 项目中承载 H5、处理 JS Bridge、分发原生能力、管理回退链路的页面。
- 使用时应先按“功能定位规则”找到项目中的对应实现，再套用本清单。

## 2. 功能定位规则
不要先找固定文件名，先按职责定位代码。

### 2.1 WebView 容器页
满足任一条件即可视为候选：
- 页面中直接创建 `InAppWebView`、`WebViewWidget`、`WebView` 等浏览器组件。
- 页面接收 `url`、`title`、`initialUrl`、`html` 等参数。
- 页面处理 `onLoadStart`、`onLoadStop`、`shouldOverrideUrlLoading`、`onWebViewCreated`。

建议搜索关键词：
- `InAppWebView`
- `WebViewController`
- `shouldOverrideUrlLoading`
- `onWebViewCreated`
- `initialUrlRequest`

### 2.2 Web 与原生桥接入口
满足任一条件即可视为候选：
- 注册 JavaScript handler。
- 调用 `evaluateJavascript`、`runJavaScript`、`postMessage`。
- 存在 `action`、`callbackId`、`bridge`、`handlerName` 等协议字段。

建议搜索关键词：
- `addJavaScriptHandler`
- `removeJavaScriptHandler`
- `evaluateJavascript`
- `callbackId`
- `action`
- `postMessage`

### 2.3 站内导航分发器
满足任一条件即可视为候选：
- 接收 H5 返回的 scheme 或 URL 并做页面跳转。
- 提供 `toWeb`、`openWeb`、`openScheme`、`handleScheme`、`backToHome` 之类方法。

建议搜索关键词：
- `toScheme`
- `openWeb`
- `toWeb`
- `backToHome`
- `Navigator.push`
- `pushAndRemoveUntil`

### 2.4 公参与签名构建器
满足任一条件即可视为候选：
- 给 H5 回传 app 侧公共参数。
- 对请求 path、时间戳、签名字段进行统一封装。

建议搜索关键词：
- `buildCommonParams`
- `signature`
- `sign`
- `commonParams`
- `timestamp`

### 2.5 业务动作处理器
满足任一条件即可视为候选：
- 根据 H5 的 action 调 API、调原生、调页面跳转。
- 存在“重试订单、换卡、评分、回首页、关闭页、外跳浏览器”等行为分支。

建议搜索关键词：
- `requestAppReview`
- `launchUrl`
- `retry`
- `fetchUserCardList`
- `report`
- `back`

## 3. Skill 适用范围
- H5 与 App 桥接联调
- WebView 页面开发或重构
- H5 打开原生页面问题排查
- 回退、挽留、跳首页、外链打开问题修复
- H5 请求签名公参联调
- WebView 权限、证书、混合内容、安全策略治理

## 4. WebView 容器应承担的标准职责

### 4.1 页面装载职责
- 接收并加载目标 URL 或 HTML。
- 展示标题。
- 管理 loading、error、empty 状态。
- 处理非标准 scheme 与外部链接。

### 4.2 生命周期职责
- 在页面可见时启用桥接。
- 在页面不可见或 App 退后台时禁用桥接。
- 避免重复注册 handler。
- 页面销毁时释放控制器相关资源。

### 4.3 回退职责
- 优先处理 Web 历史返回。
- 无历史时退出当前页面。
- 如业务要求存在挽留页、支付页、申请页，需先执行业务拦截再决定是否退出。

### 4.4 桥接职责
- 接收 H5 传入的 action。
- 解析 payload、callbackId、data。
- 将 action 映射到原生能力。
- 对可回传场景通过 JS 回调结果给 H5。

### 4.5 安全职责
- 限制允许的 scheme。
- 明确权限请求策略。
- 明确证书校验策略。
- 明确 mixed content 策略。
- 明确调试能力是否仅在 debug 环境开启。

## 5. 通用桥接动作分类
不要依赖具体 action 名称，优先按功能分类。

### 5.1 导航类
- 打开站内页面
- 打开新的 Web 页面
- 关闭当前页面
- 返回首页
- 返回上一页

### 5.2 系统能力类
- 打开外部浏览器
- 请求应用评分
- 打开拨号、短信、邮箱
- 请求系统权限

### 5.3 业务流程类
- 重试订单
- 变更绑卡/收款账户
- 发起申请
- 查询订单状态
- 打开产品详情

### 5.4 数据交换类
- 请求公共参数
- 请求签名结果
- 请求 token / session 信息
- 回传埋点结果

### 5.5 埋点与风控类
- 曝光埋点
- 点击埋点
- 风控上报
- 定位相关辅助上报

## 6. 通用实现要求

### 6.1 修改原则
1. 不先改字符串常量，先确认协议归属和调用方。
2. 不先改导航出口，先梳理当前回退栈和业务回流路径。
3. 不在 WebView 页面直接堆积过多业务分支，优先抽 action 分发层。
4. 所有 API 行为必须有 loading、异常提示、空结果处理。
5. 所有高风险动作应有埋点或日志，便于线上追查。

### 6.2 协议设计原则
1. handler 名称集中声明。
2. action 名称集中声明。
3. callback 协议固定结构。
4. data payload 要有明确字段契约。
5. 桥接异常要返回可识别失败结果，避免 H5 静默卡死。

### 6.3 金融项目附加要求
1. 涉及订单、授信、放款、提现、绑卡时，跳转链路必须可追踪。
2. 所有关键操作建议接入埋点与崩溃捕获。
3. 涉及金额、账期、应还日等数据，不在 WebView 壳层做浮点运算。
4. 涉及权限请求时，必须校验商店隐私政策要求。

## 7. 开发任务清单

### 7.1 接入前梳理
- [ ] 找到实际的 WebView 容器页。
- [ ] 找到桥接 handler 注册位置。
- [ ] 找到站内导航分发器。
- [ ] 找到公参/签名构建器。
- [ ] 找到业务 action 的主要处理代码。

### 7.2 协议梳理
- [ ] 列出当前所有 action。
- [ ] 标记哪些 action 需要 native 回调。
- [ ] 标记哪些 action 会跳页面。
- [ ] 标记哪些 action 会调 API。
- [ ] 标记哪些 action 属于高风险动作。

### 7.3 稳定性治理
- [ ] 确认 loading 在成功、失败、取消、超时场景都能关闭。
- [ ] 确认页面返回时不会遗漏挽留、支付确认、申请确认等业务拦截。
- [ ] 确认前后台切换不会重复注册 bridge。
- [ ] 确认非法 scheme、空 URL、异常 URL 有兜底。
- [ ] 确认 API 异常时 H5 和用户侧都有明确反馈。

### 7.4 安全与合规治理
- [ ] 确认证书信任策略是否合理。
- [ ] 确认权限授权是否按资源粒度控制。
- [ ] 确认 mixed content 是否可以关闭或按环境控制。
- [ ] 确认调试能力不会泄露到生产环境。
- [ ] 确认 H5 可调用的原生能力范围最小化。

### 7.5 可维护性治理
- [ ] 将 handler/action 常量集中化。
- [ ] 将桥接生命周期管理从页面 UI 中剥离。
- [ ] 将 action 分发从 UI 层剥离。
- [ ] 将导航守卫从业务 action 中剥离。
- [ ] 为关键桥接能力补最小测试集。

## 8. 测试清单

### 8.1 页面基础行为
- [ ] 页面初次打开可正常加载。
- [ ] 标题更新正常。
- [ ] loading 显示与关闭正常。
- [ ] 加载失败时有用户可见反馈。

### 8.2 返回行为
- [ ] 有 Web 历史时优先回退 Web。
- [ ] 无 Web 历史时退出页面。
- [ ] 命中特殊业务页时先走业务拦截。

### 8.3 桥接行为
- [ ] H5 调原生 action 可正确命中。
- [ ] 无效 action 不导致崩溃。
- [ ] 需要 callback 的 action 可正确回传。
- [ ] App 退后台再回来后，桥接仍处于正确状态。

### 8.4 导航行为
- [ ] 站内 scheme 跳转正常。
- [ ] 外链使用系统能力正常打开。
- [ ] 关闭页、回首页、打开详情页链路正常。

### 8.5 业务行为
- [ ] 重试类动作在成功/失败时反馈一致。
- [ ] 账户切换类动作在不同数据条件下分流正确。
- [ ] 公参签名类动作回传结构稳定。
- [ ] 埋点动作不影响主流程且结果可追踪。

## 9. 推荐输出物
当你为某个项目落这份 Skill 时，建议至少产出以下内容：

1. 功能映射表
   - WebView 容器页在哪里
   - handler 注册在哪里
   - 导航分发器在哪里
   - 公参构建器在哪里
   - 业务 action 在哪里处理
2. action 清单
   - action 名
   - 功能分类
   - 输入字段
   - 输出字段
   - 跳转/API/回调/埋点依赖
3. 风险清单
   - 安全
   - 合规
   - 稳定性
   - 可维护性
4. 测试清单
   - 手工回归项
   - 可自动化项

## 10. 当前项目映射示例
以下内容仅作为“如何落地到当前项目”的示例，不是复用前提。

### 10.1 当前项目中的功能映射
- WebView 容器页：
  - `lib/screens/web/webview_screen.dart`
- 站内导航分发器：
  - `lib/utils/nav_helper.dart`
- 公参构建器：
  - `lib/network/api_manager.dart`
- 相关业务 API：
  - `lib/network/api_endpoints.dart`

### 10.2 当前项目中的桥接功能示例
- 风控埋点
- 外跳浏览器
- 站内 scheme 跳转
- 关闭当前 Web 页
- 返回首页
- 请求应用评分
- 重试订单
- 更换收款账户
- 请求签名公参

### 10.3 当前项目中的已知风险示例
- 证书校验策略偏宽松
- 权限授权策略偏宽松
- mixed content 常开
- action 字符串硬编码
- 加载失败路径显式收口不足

## 11. 维护规则
- 新项目复用时，先更新“功能映射表”，不要先替换成新文件名。
- 新增 action 时，先补 action 清单，再补测试清单。
- 修改回退、首页、订单、绑卡、申请等高风险链路时，必须补回归项。
