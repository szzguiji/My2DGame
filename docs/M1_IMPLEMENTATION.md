# M1 实现与试玩说明

工程：`D:\My2DGame\project.godot\project.godot`。引擎：Godot 4.7.2 stable mono，使用 GDScript。F5 启动 `res://scenes/test_room/TestRoom.tscn`。

## 范围与规格处理

已读取根目录 AGENTS.md、TASK_001.md，以及 docs 下 01、02_Godot、03 的当前 v2.0 Word 文档。没有 Unity 工程或另一套实现。

M1 机制与默认数值一致，无规则冲突。01 内嵌旧蓝图仍写“36 m / 1 unit ≈ 1 m”，以当前 v2.0 正文的 DU 和 Godot 1 DU = 32 px 为准；蓝图只作布局参考。02 的完整场景树包含后续战斗组件及 B–E 区，本任务按 M1 范围只实现 A 区、玩家实体碰撞、占位视觉和镜头。没有 Hitbox/Hurtbox、生命、攻击、Dash、敌人、危险区或自动死亡重置。

03 的最小镜头要求比 TASK 的基础跟随更具体，因此包含房间边界、轻微水平 Look Ahead 和平滑跟随。平滑速度、Look Ahead、镜头纵向偏移及平台具体坐标未指定，使用可调初值；这些仍需人工试玩。A 区为验证下落限速提供 12 DU 落差和承接地面，没有伤害。数字测试点与 R 只进行开发传送，不是存档或检查点系统。

## 文件与职责

以下路径除 README、此说明外均相对于实际 Godot 工程根目录。

| 文件 | 职责 |
| --- | --- |
| `project.godot` | 主场景、输入映射、视口、物理插值、碰撞层名称 |
| `data/design_units.gd` | 唯一 DU 与像素换算 |
| `data/player_tuning.gd` / `.tres` | Inspector 可调参数、只读重力和起跳速度推导 |
| `scenes/player/Player.tscn` | CharacterBody2D、实体形状、占位 Sprite、Movement、Camera2D |
| `scripts/player/player_controller.gd` | 输入边沿采样、薄协调器、独立 Action 状态、开发重置 |
| `scripts/player/player_movement.gd` | 水平速度、跳跃、Grounded/Airborne、Coyote/Buffer 计时器、下落限速 |
| `scripts/player/player_visual.gd` | 只改变占位朝向和空中颜色，不翻转碰撞体 |
| `scripts/player/player_follow_camera.gd` | 物理帧平滑跟随、Look Ahead、传送后镜头重置 |
| `art_placeholder/player.svg` | 灰盒玩家占位图，无正式美术依赖 |
| `scenes/test_room/TestRoom.tscn` | A 区实体布局、标注、测试起点、必要 debug HUD |
| `scenes/test_room/GrayboxPlatform.tscn` / `scripts/test_room/graybox_platform.gd` | DU 尺寸的 Inspector 灰盒平台，自动生成一致的形状和画面 |
| `scripts/test_room/test_room.gd` | Debug 输入、DU 网格、状态与速度读数 |
| `tests/m1_movement_test.gd` | 真实 Godot 物理碰撞及输入集成回归检查 |
| 仓库根目录 `README.md` / `docs/M1_IMPLEMENTATION.md` | 运行入口、文件清单、试玩与调参说明 |

Godot 为新脚本和占位图生成 `.uid` / `.import` 文件；这些是资源元数据。原有 `addons/godot_ai` 未修改；其工具仅用于同步打开的编辑器设置及验证运行。

## 参数与架构

在 FileSystem 点击 `res://data/player_tuning.tres`，直接修改 Inspector 并保存，然后 F5。运行时可在 Remote 的 Player 上展开 tuning 修改并即时观察；Remote 修改用于临时比较，最终值需写回本地资源。

| 参数 | 起始值 | 单位 |
| --- | --- | --- |
| max_speed | 7.0 | DU/s |
| ground_acceleration / ground_deceleration | 55 / 70 | DU/s² |
| air_acceleration | 40 | DU/s² |
| jump_height / time_to_apex | 3.25 / 0.36 | DU / s |
| fall_multiplier | 1.5 | 上升重力的倍率 |
| jump_release_multiplier | 0.55 | 松键后当前上升速度的一次性倍率 |
| max_fall_speed | 22 | DU/s |
| coyote_time / jump_buffer | 0.10 / 0.10 | s；设计建议范围 0.08–0.12 |
| camera_follow_speed / camera_look_ahead_speed | 12 / 8 | 平滑响应速度，s⁻¹ |
| camera_look_ahead / camera_vertical_offset | 0.65 / -1.0 | DU |

跳跃公式：`g = 2h / t²`、`v = g × t`、`g_fall = g × fall_multiplier`。初始上升重力约 50.1543 DU/s²，起跳速度约 18.0556 DU/s；转换为像素后约 1604.94 px/s² 和 577.78 px/s。没有独立可编辑 gravity / jump force。每个物理帧重算派生值，因此修改高度或时间后不会留下旧重力。

输入边沿在 `_unhandled_input` 采样；物理帧消费输入，更新显式计时器和 `move_and_slide()`。上升松键只裁切一次，Buffer 中先按再松也保留短跳意图。起跳同时消费 Buffer 和 Coyote，按住不重复起跳。Buffer 在落地帧消费，下一物理帧开始上移。

Locomotion 与 Action 分层，M1 的 Action 始终为 None；后续枚举只定义名称，没有动作玩法。高优先级动作以后必须由协调器显式接入。运动和表现分开；朝向立即变化，水平速度通过加速度反转。

垂直位移使用恒加速度积分，并在跳顶、达到下落上限时分段；交给 CharacterBody2D 的是该帧平均速度，碰撞后恢复逻辑速度。这避免普通 Euler 积分导致 60 Hz 跳高偏低，保持 3.15 DU 平台可达。地面和顶棚碰撞会正确清理垂直速度。

BodyCollider 为 0.7 × 1.6 DU，视觉约 1.8 DU 高。PlayerBody 层值 2，mask=5（World + EnemyBody）；World 层值 1，mask=0。八个规格碰撞层已命名，M1 不创建伤害检测区域。场景位置显示为像素；换算为 DU 时除以 32。平台 `size_du` 为 DU，平台原点是左上角；Player 原点是脚底。

## 手动试玩步骤

先运行 F5，点击游戏视口取得输入焦点。A/D、左右方向键或手柄左摇杆移动；Space 或 A/Cross 跳跃。R 回到出生点；数字 1–5 直达开发测试起点。

1. **数字 1：跑、停、转向。** 在 7 DU 平地按住右键，观察 vx 平滑达到 7；松键观察停止；满速时按左键，朝向立即改变，速度连续反向。来回重复，检查是否自然、容易停在指定点。
2. **原地短跳与全跳。** 短按 Space 与持续按住比较高度。默认提前约 0.05 s 松键的自动测试短跳约 1.57 DU，全跳约 3.25 DU。观察跳顶是否清楚、下落是否果断。空中左右调整，感受修正幅度。
3. **数字 2：Coyote。** 从短间隙左侧跑向右侧，等脚底完全离开边缘后立即按 Space（约 0.10 s 内），HUD 的 last jump 应为 coyote。离边后等约 0.15 s 再按，应不能起跳。跳起后连按，确认没有空中追加跳。
4. **数字 3：标准平台与 Buffer。** 原地按住 Space，升到高处再按右键，落上 2.25 DU 平台。走出平台边缘，靠近下方地面前约 0.05–0.08 s 按 Space，落地应立即准备再次起跳，HUD 显示 landing_buffer。分别保持按住和提前松开，验证全跳/短跳。再从高处掉落时提前超过 0.10 s 按一次，确认落地不会延迟起跳。
5. **数字 4：近极限平台。** 在平台左侧先原地全跳，约 0.25 s 后向右修正，落上 3.15 DU 平台。短跳应上不去。此处容错较小，是检查跳高和空中修正的测试，不保证每次随意输入都成功。
6. **长间隙。** 从 3.15 DU 平台下方的地面向右起跳，跨越 3.5 DU 间隙；对比满速起跳与低速起跳、提前松键及空中修正的落点。
7. **数字 5：下落。** 向右走出边缘，观察 vy 增加并稳定在 22 DU/s，随后落在 12 DU 下方的无伤害承接地面。用 R 或数字键重试，检查传送不会继承 Buffer、速度或旧地面状态。
8. **持续 5 分钟。** 跑停转向、短/长跳、边缘跳和落地 Buffer 混合操作。留意碰撞卡住、误起跳、镜头抖动、明显跟随延迟。程序测试不能代替这一轮主观手感判断。

## 自动验证

PowerShell（已有 Godot 可执行文件；可根据安装位置替换）：

```powershell
& 'D:\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe' --headless --path 'D:\My2DGame\project.godot' --editor --quit
& 'D:\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe' --headless --path 'D:\My2DGame\project.godot' --script res://tests/m1_movement_test.gd
& 'D:\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe' --headless --path 'D:\My2DGame\project.godot' --quit-after 120
```

本次自动回归结果为 **46 项检查、0 失败**，覆盖实际输入事件到控制器、实体碰撞、加减速、反向、空中控制、窗口内/外 Coyote、有效/过期 Buffer、提前松键的 Buffer、防止空中追加跳与按住连跳、限速、顶棚、开发重置、镜头跟随以及真实标准/近极限平台可达性。

跳跃实测：30 Hz 为 3.2506 DU / 0.3667 s，60 Hz 为 3.2505 DU / 0.3667 s，120 Hz 为 3.2521 DU / 0.3583 s。60 Hz 下约 0.05 s 松键的短跳为 1.5709 DU。微小误差来自物理离散采样和碰撞安全间距，跳顶时间在一个物理帧内。

本次验证还从已打开的 Godot 编辑器启动主场景、发送运行时输入并查看 framebuffer；编辑器和游戏日志检查无本次脚本错误，headless 主场景 120 帧启动检查退出码为 0。沙箱命令运行时将 APPDATA 临时重定向到 `.godot/validation_user`，日志写到 `.godot/m1_*.log`，以免触碰用户全局编辑器设置。命令执行中 Godot 打印了系统根证书读取失败，未影响本地运行和物理验证；该环境告警的原因未进一步诊断。

## M1 后续调参

每轮只改 1–2 个参数，房间尺度先保持不变。先评估加速/减速和转向，再评估跳高/跳顶时间，再评估下落倍率、松键倍率及空中修正；Coyote/Buffer 在 0.08–0.12 s 内比较；最后评估镜头平滑和 Look Ahead。不要将重力或起跳速度作为第二套自由参数。

| 日期/参数 | 改前问题 | 修改值 | 改后感受 | 是否保留 |
| --- | --- | --- | --- | --- |
| | | | | |

当前不含斜坡、移动平台、墙跳或二段跳。主观重量、精确度、镜头舒适度尚需人工试玩；实体手柄也需人工确认。M1 完成后停止，未实现 M2。
