<script setup>
import { ref, onMounted, nextTick } from 'vue'
import ControlBar from './ControlBar.vue'

const props = defineProps({
  showHelp: Boolean // 来自父组件
})
const emit = defineEmits(['update:showHelp'])

const videoList = ref([])
const currentIndex = ref(0)
const currentVideoSrc = ref('')
const videoElement = ref(null)

const isPlaying = ref(false)
const isMuted = ref(false)
const volume = ref(50)
let previousVolume = 50 // 保存静音前音量

onMounted(() => {
  videoList.value = ['sample1.mp4', 'sample2.mp4']
  if (videoList.value.length) selectVideo(0)
})

function selectVideo(index) {
  currentIndex.value = index
  currentVideoSrc.value = `/videos/${videoList.value[index]}`

  nextTick(() => {
    if (videoElement.value) {
      videoElement.value.volume = volume.value / 100
      videoElement.value.muted = isMuted.value
      videoElement.value.play()
      isPlaying.value = true
    }
  })
}

function prevVideo() {
  if (currentIndex.value > 0) selectVideo(currentIndex.value - 1)
}

function nextVideo() {
  if (currentIndex.value < videoList.value.length - 1) selectVideo(currentIndex.value + 1)
}

function togglePlay() {
  if (!videoElement.value) return
  if (videoElement.value.paused) {
    videoElement.value.play()
    isPlaying.value = true
  } else {
    videoElement.value.pause()
    isPlaying.value = false
  }
}

function toggleMute() {
  if (!isMuted.value) {
    previousVolume = volume.value
    volume.value = 0
  } else {
    volume.value = previousVolume
  }

  isMuted.value = !isMuted.value

  if (videoElement.value) {
    videoElement.value.muted = isMuted.value
    videoElement.value.volume = volume.value / 100
  }
}

function changeVolume(val) {
  volume.value = val
  isMuted.value = val === 0

  if (videoElement.value) {
    videoElement.value.volume = val / 100
    videoElement.value.muted = isMuted.value
  }
}

function enterFullscreen() {
  videoElement.value?.requestFullscreen?.()
}
</script>

<template>
  <div class="video-player">
    <!-- 视频列表 -->
    <div class="video-list" :class="{ shifted: showHelp }">
      <h3>视频目录</h3>
      <ul>
        <li
          v-for="(video, idx) in videoList"
          :key="idx"
          :class="{ active: idx === currentIndex }"
          @click="selectVideo(idx)"
        >
          {{ video }}
        </li>
      </ul>
    </div>

    <!-- 视频区域 -->
    <div class="video-area">
      <video
        ref="videoElement"
        :src="currentVideoSrc"
        controls
        style="width: 100%; max-height: 500px"
      ></video>

      <!-- 控制条 -->
      <ControlBar
        :isPlaying="isPlaying"
        :isMuted="isMuted"
        :volume="volume"
        :disablePrev="currentIndex === 0"
        :disableNext="currentIndex === videoList.length - 1"
        :showGestureHelp="showHelp"
        @update:showGestureHelp="emit('update:showHelp', $event)"
        @prev="prevVideo"
        @next="nextVideo"
        @togglePlay="togglePlay"
        @mute="toggleMute"
        @volumeChange="changeVolume"
        @fullscreen="enterFullscreen"
      />
    </div>
  </div>
</template>

<style scoped>
.video-player {
  display: flex;
  flex-direction: row;
}

/* 视频列表样式 */
.video-list {
  position: absolute;
  top: 50px;
  left: -50px;
  width: 180px;
  height: 700px;
  background-color: #eaf4fc; /* 浅蓝色背景 */
  padding: 20px 15px;
  border-right: 1px solid #d0e3f1;
  border-radius: 10px 0 0 10px;
  box-shadow: 2px 4px 10px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
  transition: transform 0.3s ease;
  z-index: 10;
}

/* 被推移时的隐藏状态 */
.video-list.shifted {
  transform: translateX(-200px);
}

.video-list h3 {
  font-size: 16px;
  margin-bottom: 12px;
  color: #409eff;
  border-bottom: 1px solid #d0e3f1;
  padding-bottom: 6px;
}

.video-list ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.video-list li {
  padding: 8px 10px;
  margin-bottom: 6px;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.2s, color 0.2s;
  color: #333;
}

.video-list li:hover {
  background-color: #d0eaff;
  color: #000;
}

.video-list li.active {
  background-color: #409eff;
  color: #fff;
  font-weight: bold;
}

.video-area {
  flex: 1;
  padding: 20px;
}
</style>