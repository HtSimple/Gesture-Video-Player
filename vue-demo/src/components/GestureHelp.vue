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
  { id: 1, desc: '播放/暂停', gesture: '拳头' },
  { id: 2, desc: '切换倍速', gesture: '向上剪刀手' },
  { id: 3, desc: '音量减', gesture: '加、减、拳头' },
  { id: 3, desc: '音量加', gesture: '加、减、拳头' },
  { id: 3, desc: '静音与解除', gesture: '加、减、拳头' },
  { id: 4, desc: '全屏切换', gesture: '双手展开/并拢' },
  { id: 5, desc: '上一个视频', gesture: '指左/指右' },
  { id: 3, desc: '下一个视频', gesture: '加、减、拳头' },
  { id: 8, desc: '亮度提高', gesture: '上滑/下滑' },
  { id: 3, desc: '亮度降低', gesture: '加、减、拳头' },
  { id: 10, desc: '快进', gesture: '合指滑动' },
  { id: 3, desc: '快退', gesture: '加、减、拳头' },
  { id: 11, desc: '播放模式切换', gesture: '四指张开' },
  { id: 12, desc: '手势说明栏', gesture: '三指张开/并拢' }
]
</script>

<style>
.gesture-help {
  margin: 20px;
}
</style>
