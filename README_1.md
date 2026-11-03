# 复利 · 投资交易日志 —— 前后端分离实现

对应此前的高保真原型（首页仪表盘 / 交易记录 / 记一笔交易 / 持仓管理 / 数据分析）。

```
invest-app/
├── backend/     Spring Boot 3 + JPA，Java 17
└── frontend/    Flutter（Android/iOS 同一套代码）
```

## 后端（backend/）

- 技术栈：Spring Boot 3.3 + Spring Data JPA + MySQL（生产）/ H2（本地开发，内嵌，MySQL 兼容模式）。
- 目录结构按 entity / repository / service / controller / dto 分层，见每个类的注释。
- 本地直接跑，不需要装数据库：

  ```bash
  cd backend
  mvn spring-boot:run
  ```

  启动后自动用内嵌 H2 建表（`src/main/resources/schema.sql`）并灌入和原型一致的示例数据
  （`seed-data.sql`：3 个账户、10 笔交易、10 条持仓、30 天资金快照）。
  访问 `http://localhost:8080/api/dashboard/summary?period=month` 应该能看到首页数据。

- 接生产 MySQL：用 `sql/schema.sql` 在 MySQL 里建库建表，启动时加
  `--spring.profiles.active=mysql`，并设置 `DB_HOST/DB_NAME/DB_USER/DB_PASSWORD` 环境变量
  （见 `application.yml`）。

- 核心接口（都是 `{code, message, data}` 统一响应壳）：

  | 方法 | 路径 | 对应页面 |
  |---|---|---|
  | GET | `/api/dashboard/summary?period=month` | 首页仪表盘 |
  | GET | `/api/trades?type=STOCK&page=0&size=20` | 交易记录列表 |
  | POST/PUT/DELETE | `/api/trades[/​{id}]` | 记一笔交易（新增/编辑/删除） |
  | GET | `/api/positions?type=FUTURE` | 持仓管理 |
  | GET | `/api/analytics/summary?range=year` | 数据分析 |
  | GET | `/api/accounts`、`/api/tags` | 表单里的账户/标签下拉 |
  | POST | `/api/admin/snapshot/run` | 手动触发一次"今日资金快照"，本地联调用 |

### 已知简化（接生产前请再评估，代码里也有对应注释）

1. **未接入登录鉴权**：`CurrentUserProvider` 把所有请求都当成同一个用户处理，接 JWT 后只改这一个类。
2. **持仓聚合是全量重算**：每次交易新增/编辑/删除后，`PositionService.recomputeAll` 把该用户的
   持仓表清空、按时间顺序重放全部交易重新生成——简单但正确，数据量大了之后可以优化成增量更新。
3. **期权没有区分开仓/平仓标记位**：买入按"开多头仓位"处理，卖出按"开空头（义务）仓位"处理，
   没有"卖出以平掉已买入仓位"这种场景，见 `PositionService`/`AnalyticsService` 类注释。
4. **持仓当前价需要手动维护**：`currentPrice` 没有接行情数据源，新开仓时默认等于成本价，
   浮动盈亏从 0 开始，后续需要人工更新或自己接一个行情定时任务。
5. **平均持仓天数**是简化版 FIFO 撮合算出来的（`AnalyticsService.averageHoldingDays`），不是严谨的
   多批次期货保证金/期权行权处理。
6. 本会话所在的沙箱网络策略不允许访问 Maven 中央仓库，因此这份后端代码**没有跑通实际的
   `mvn compile`**——是我逐文件手工过了一遍语法、字段名、Repository 方法名和实体字段的对应关系，
   但落地前建议你本地跑一次 `mvn spring-boot:run` 确认。

## 前端（frontend/）

- 技术栈：Flutter（Dart），跨平台一套代码见上一轮的框架选型说明。
- 核心是"前后端分离 + 本地数据库缓存最新接口返回数据"这条链路：
  - `lib/network/api_client.dart`：统一的 Dio 封装，解包 `{code,message,data}`，区分"网络层失败"
    和"后端业务错误"。
  - `lib/local/api_cache_db.dart`：本地 SQLite（sqflite）缓存表，只有一张 `api_cache(cache_key,
    payload, updated_at)`，按接口名+参数当 key，把每个接口最近一次成功返回的原始 JSON 存下来。
  - `lib/repository/*.dart`：每个页面一个 Repository，统一走 `fetchWithCache`（见
    `cache_helper.dart`）——**先请求后端，成功就覆盖本地缓存；请求失败且是网络问题就退回读本地
    缓存**，页面上会有一个"离线缓存 · 更新于 14:32"的小角标（`widgets/cache_badge.dart`），不会
    悄悄地把旧数据当新数据展示。
  - 新增/编辑/删除交易是写操作，没有做离线兜底——断网时会明确提示保存失败，而不是假装成功
    （要支持离线记账需要额外做一个本地待同步队列，当前版本没做）。
- 页面对应原型的 5 个核心页面：`lib/pages/{home,trades,add_trade,positions,analytics}_page.dart`，
  底部导航在 `lib/main.dart`。
- 资金曲线、回撤区间用 `lib/widgets/equity_chart.dart` 里的 `CustomPainter` 画，和原型 SVG 版本
  是同一套贝塞尔平滑算法，方便你对照着改。

### 本地运行

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # Android 模拟器访问宿主机后端
# 真机/iOS 模拟器把 API_BASE_URL 换成你电脑的局域网 IP，例如 http://192.168.1.10:8080
```

### 已知限制

- 本会话的沙箱环境没有装 Flutter SDK，**这份前端代码没有跑过 `flutter analyze` / `flutter run`
  实际验证**——是手工过的语法（null-safety、record 类型、泛型协变等容易踩坑的点都特别检查过），
  建议拿到本地后先 `flutter pub get && flutter analyze` 过一遍再跑。
- 标签自动补全（`repository/tag_repository.dart`）已经写好但还没接到"记一笔交易"页面上，目前
  加标签是一个简单的输入框弹窗；接现有标签列表只是把这个 Repository 接进 `_promptAddTag` 的事。
