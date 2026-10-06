# My2DGame

Godot 4.7.2 的 M1 移动灰盒原型。实际工程文件位于 `project.godot/project.godot`。

用 Godot 导入该文件后按 **F5** 启动 `TestRoom.tscn`。A/D 或方向键移动，Space 跳跃，R 回到出生点；数字 1–5 切换开发测试起点。支持手柄左摇杆及 A/Cross 跳跃。

参数唯一来源：`project.godot/data/player_tuning.tres`，在 Inspector 编辑。DU 换算集中于 `data/design_units.gd`：**1 DU = 32 px**。重力和起跳速度由跳高及跳顶时间推导。

详细文件职责、测试命令、手动试玩步骤和调参记录见 [M1 说明](docs/M1_IMPLEMENTATION.md)。当前只实现 M1，未进入 M2。
