<template>
  <div class="control-bar-wrapper">
    <!-- 手势说明按钮（右上角） -->
    <el-button class="gesture-help-btn" @click="$emit('update:showGestureHelp', !showGestureHelp)">
      {{ showGestureHelp ? '隐藏手势说明' : '显示手势说明' }}
    </el-button>

    <!-- 控制按钮区域 -->
    <div class="control-bar">
      <!-- 上一个按钮 -->
      <el-button :disabled="disablePrev" @click="$emit('prev')">上一个</el-button>

      <!-- 播放/暂停按钮 -->
      <el-button @click="$emit('togglePlay')">
        {{ isPlaying ? '暂停' : '播放' }}
      </el-button>

      <!-- 下一个按钮 -->
      <el-button :disabled="disableNext" @click="$emit('next')">下一个</el-button>

      <!-- 静音按钮 -->
      <el-button
        :style="{
          backgroundColor: isMuted ? '#409EFF' : '#ffffff',
          color: isMuted ? '#ffffff' : '#000000'
        }"
        @click="$emit('mute')"
      >
        <i
          :class="isMuted ? 'el-icon-volume-off' : 'el-icon-volume-up'"
          style="margin-right: 5px"
        ></i>
        {{ isMuted ? '解除静音' : '静音' }}
      </el-button>

      <!-- 音量调节 -->
      <div class="volume-control">
        <div class="volume-label">音量调节</div>
        <el-slider
          class="volume-slider"
          :min="0"
          :max="100"
          :step="1"
          :model-value="volume"
          @update:modelValue="$emit('volumeChange', $event)"
          style="width: 150px"
        />
      </div>

      <!-- 全屏按钮 -->
      <el-button @click="$emit('fullscreen')">全屏</el-button>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  isPlaying: Boolean,
  isMuted: Boolean,
  volume: Number,
  disablePrev: Boolean,
  disableNext: Boolean,
  showGestureHelp: Boolean,
})
</script>

<style scoped>
.control-bar-wrapper {
  position: relative;
  width: 100%;
}

.control-bar {
  display: flex;
  justify-content: center;
  margin-top: 10px;
  gap: 10px;
  flex-wrap: wrap;
}

.gesture-help-btn {
  position: fixed;
  top: 50px;
  right: 200px;
  z-index: 999;
}

.volume-control {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 10px;
}

.volume-label {
  font-size: 12px;
  color: #666;
  white-space: nowrap;
}
</style>