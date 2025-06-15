<template>
  <el-card class="gesture-help">
    <h3>手势功能说明</h3>
    <el-table :data="gestureList" style="width: 100%">
      <el-table-column prop="id" label="ID" width="50" />
      <el-table-column prop="desc" label="功能" />
      <el-table-column prop="gesture" label="手势描述" />
    </el-table>
  </el-card>
</template>

<script setup>
const gestureList = [
  { id: 1, desc: '播放/暂停', gesture: '右手五指合拢，掌心面向镜头' },
  { id: 2, desc: '静音与解除', gesture: '右手食指竖着放到嘴唇中间' },
  { id: 3, desc: '全屏切换', gesture: '右手五指张开，掌心面向镜头' },
  { id: 4, desc: '上一个视频', gesture: '右手竖大拇指，手背向镜头' },
  { id: 5, desc: '下一个视频', gesture: '右手倒竖大拇指，手心向镜头' },
  { id: 6, desc: '播放模式切换', gesture: '右手比ok的手势，手心向镜头' },
  { id: 7, desc: '手势说明栏', gesture: '右手单竖一根右手食指' }
]
</script>

<style>
.gesture-help {
  margin: 20px;
}
</style>
