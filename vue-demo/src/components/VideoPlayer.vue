<script setup>
import { ref, onMounted, nextTick, watch } from 'vue'
import axios from 'axios'
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
  isMuted.value = !isMuted.value
  if (videoElement.value) videoElement.value.muted = isMuted.value
}

function changeVolume(val) {
  volume.value = val
  if (videoElement.value) videoElement.value.volume = val / 100
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

      <!-- 控制条，带有 showHelp 控制 -->
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
  left: -20px;
  width: 123px;
  height: 700px;
  background-color: #f5f5f5;
  padding: 15px;
  border-right: 1px solid #ddd;
  overflow-y: auto;
  transition: transform 0.3s ease;
}
.video-list.shifted {
  transform: translateX(-200px); /* 向左推移防止遮挡 */
}

.video-list ul {
  list-style: none;
  padding: 0;
}
.video-list li {
  padding: 6px 0;
  cursor: pointer;
}
.video-list li.active {
  font-weight: bold;
  color: #409eff;
}

.video-area {
  flex: 1;
  padding: 20px;
}
</style>