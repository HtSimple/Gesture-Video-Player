<template>
  <div class="control-bar-wrapper">
    <!-- 手势说明按钮（右上角） -->
    <el-button class="gesture-help-btn" @click="$emit('update:showGestureHelp', !showGestureHelp)">
      {{ showGestureHelp ? '隐藏手势说明' : '显示手势说明' }}
    </el-button>

    <!-- 控制按钮区域 -->
    <div class="control-bar">
      <!-- 第一行按钮 -->
      <div class="button-row">
        <el-button :disabled="disablePrev" @click="$emit('prev')">上一个</el-button>
        <el-button @click="$emit('seekBackward', 5)">快退5秒</el-button>
        <el-button @click="$emit('togglePlay')">{{ isPlaying ? '暂停' : '播放' }}</el-button>
        <el-button @click="$emit('seekForward', 5)">快进5秒</el-button>
        <el-button :disabled="disableNext" @click="$emit('next')">下一个</el-button>
      </div>

      <!-- 第二行按钮 -->
      <div class="button-row">
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
            style="width: 120px"
          />
        </div>

        <!-- 亮度调节 -->
        <div class="brightness-control">
          <div class="volume-label">亮度调节</div>
          <el-slider
            class="brightness-slider"
            :min="50"
            :max="150"
            :step="10"
            :model-value="brightness"
            @update:modelValue="$emit('brightnessChange', $event)"
            style="width: 120px"
          />
        </div>

        <!-- 倍速选择 -->
        <div class="speed-control">
          <div class="volume-label">倍速播放</div>
          <el-select
            :model-value="playbackRate"
            @update:modelValue="$emit('rateChange', $event)"
            placeholder="倍速"
            style="width: 100px"
          >
            <el-option v-for="rate in rateOptions" :key="rate" :label="`${rate}x`" :value="rate" />
          </el-select>
        </div>

        <el-button @click="$emit('fullscreen')">全屏</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  isPlaying: Boolean,
  isMuted: Boolean,
  volume: Number,
  brightness: Number,
  playbackRate: Number,
  disablePrev: Boolean,
  disableNext: Boolean,
  showGestureHelp: Boolean,
})

const rateOptions = [0.5, 1, 1.5, 2]
</script>

<style scoped>
.control-bar-wrapper {
  position: relative;
  width: 100%;
}

.control-bar {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
}

.button-row {
  display: flex;
  justify-content: center;
  gap: 10px;
  flex-wrap: wrap;
}

.gesture-help-btn {
  position: fixed;
  top: 50px;
  right: 200px;
  z-index: 999;
}

.volume-control,
.brightness-control,
.speed-control {
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