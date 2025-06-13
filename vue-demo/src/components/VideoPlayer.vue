<script setup>
import { ref, onMounted, nextTick, onBeforeUnmount } from 'vue'
import ControlBar from './ControlBar.vue'
import axios from 'axios'

const props = defineProps({
  showHelp: Boolean
})
const emit = defineEmits(['update:showHelp'])

const videoList = ref([])
const currentIndex = ref(0)
const currentVideoSrc = ref('')
const videoElement = ref(null)

const isPlaying = ref(false)
const isMuted = ref(false)
const volume = ref(50)
const brightness = ref(100)
const playbackRate = ref(1.0)
const playMode = ref('loop') // 'single', 'loop', 'shuffle'
let previousVolume = 50

// 摄像头相关
const cameraVideo = ref(null)
const isCameraOn = ref(false)
let cameraStream = null
const gestureCanvas = document.createElement('canvas')

let gestureInterval = null

onMounted(() => {
  // 初始视频列表
  videoList.value = ['sample1.mp4', 'sample2.mp4']
  if (videoList.value.length) selectVideo(0)

  nextTick(() => {
    if (videoElement.value) {
      videoElement.value.addEventListener('ended', handleEnded)
    }
  })
})

onBeforeUnmount(() => {
  stopGestureRecognition()
  stopCamera()
})

function selectVideo(index) {
  currentIndex.value = index
  currentVideoSrc.value = `/videos/${videoList.value[index]}`

  nextTick(() => {
    if (videoElement.value) {
      videoElement.value.volume = volume.value / 100
      videoElement.value.muted = isMuted.value
      videoElement.value.playbackRate = playbackRate.value
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

function seekBackward(seconds) {
  if (videoElement.value) {
    videoElement.value.currentTime = Math.max(0, videoElement.value.currentTime - seconds)
  }
}

function seekForward(seconds) {
  if (videoElement.value) {
    videoElement.value.currentTime = Math.min(videoElement.value.duration, videoElement.value.currentTime + seconds)
  }
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

function changeBrightness(val) {
  brightness.value = val
}

function changeRate(val) {
  playbackRate.value = val
  if (videoElement.value) {
    videoElement.value.playbackRate = val
  }
}

function enterFullscreen() {
  videoElement.value?.requestFullscreen?.()
}

function togglePlayMode() {
  const modes = ['loop', 'single', 'shuffle']
  const current = modes.indexOf(playMode.value)
  playMode.value = modes[(current + 1) % modes.length]
}

function handleEnded() {
  if (!videoElement.value) return

  if (playMode.value === 'single') {
    videoElement.value.currentTime = 0
    videoElement.value.play()
  } else if (playMode.value === 'loop') {
    if (currentIndex.value < videoList.value.length - 1) {
      selectVideo(currentIndex.value + 1)
    } else {
      selectVideo(0)
    }
  } else if (playMode.value === 'shuffle') {
    let next
    do {
      next = Math.floor(Math.random() * videoList.value.length)
    } while (next === currentIndex.value && videoList.value.length > 1)
    selectVideo(next)
  }
}

// === 摄像头控制 ===

async function startCamera() {
  try {
    cameraStream = await navigator.mediaDevices.getUserMedia({ video: true })
    if (cameraVideo.value) {
      cameraVideo.value.srcObject = cameraStream
      isCameraOn.value = true
      startGestureRecognition()
    }
  } catch (err) {
    alert('无法打开摄像头，请检查权限')
    isCameraOn.value = false
  }
}

function stopCamera() {
  if (cameraStream) {
    cameraStream.getTracks().forEach(track => track.stop())
    cameraStream = null
  }
  isCameraOn.value = false
  stopGestureRecognition()
}

function toggleCamera() {
  if (isCameraOn.value) {
    stopCamera()
  } else {
    startCamera()
  }
}

// === 手势识别，基于摄像头画面 ===

function startGestureRecognition() {
  stopGestureRecognition()
  if (!isCameraOn.value) return

  gestureInterval = setInterval(async () => {
    if (!cameraVideo.value || cameraVideo.value.readyState < 2) return

    const ctx = gestureCanvas.getContext('2d')
    gestureCanvas.width = cameraVideo.value.videoWidth
    gestureCanvas.height = cameraVideo.value.videoHeight
    ctx.drawImage(cameraVideo.value, 0, 0, gestureCanvas.width, gestureCanvas.height)

    gestureCanvas.toBlob(async (blob) => {
      if (!blob) return
      const formData = new FormData()
      formData.append('image', blob, 'frame.jpg')

      try {
        const res = await axios.post('/api/gesture/recognize', formData)
        handleGestureCommand(res.data.command)
      } catch (err) {
        console.error('识别失败:', err)
      }
    }, 'image/jpeg', 0.8)
  }, 500)
}

function stopGestureRecognition() {
  if (gestureInterval) clearInterval(gestureInterval)
}

// 手势命令处理保持不变
function handleGestureCommand(cmd) {
  switch (cmd) {
    case 'play':
      if (videoElement.value?.paused) togglePlay()
      break
    case 'pause':
      if (!videoElement.value?.paused) togglePlay()
      break
    case 'next':
      nextVideo()
      break
    case 'prev':
      prevVideo()
      break
    case 'mute':
      if (!isMuted.value) toggleMute()
      break
    case 'unmute':
      if (isMuted.value) toggleMute()
      break
    case 'vol_up':
      changeVolume(Math.min(100, volume.value + 10))
      break
    case 'vol_down':
      changeVolume(Math.max(0, volume.value - 10))
      break
    case 'seek_forward':
      seekForward(10)
      break
    case 'seek_backward':
      seekBackward(10)
      break
    case 'mode':
      togglePlayMode()
      break
    default:
      console.log('未识别指令:', cmd)
  }
}

// ===== 新增函数 =====

// 处理用户选择文件夹（文件）事件
function handleFolderSelect(event) {
  const files = event.target.files
  if (!files.length) return

  // 过滤出所有mp4文件，取文件名
  const mp4Files = []
  for (let i = 0; i < files.length; i++) {
    const file = files[i]
    if (file.type === 'video/mp4' || file.name.toLowerCase().endsWith('.mp4')) {
      mp4Files.push(file.name)
    }
  }

  if (mp4Files.length === 0) {
    alert('所选文件夹中没有 MP4 文件')
    return
  }

  videoList.value = mp4Files
  selectVideo(0)
}

</script>

<template>
  <div class="video-player">
    <div class="video-list" :class="{ shifted: showHelp }">
      <h3 style="display: flex; align-items: center; justify-content: space-between;">
        视频目录
        <label
          style="font-size: 12px; cursor: pointer; color: #409eff; border: 1px solid #409eff; padding: 2px 6px; border-radius: 4px;"
          title="选择本地文件夹"
        >
          选择文件夹
          <input
            type="file"
            webkitdirectory
            directory
            multiple
            style="display: none"
            @change="handleFolderSelect"
            accept="video/mp4"
          />
        </label>
      </h3>
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

    <div class="video-area">
      <video
        ref="videoElement"
        :src="currentVideoSrc"
        controls
        :style="{ width: '100%', maxHeight: '600px', filter: `brightness(${brightness}%)` }"
      ></video>

      <ControlBar
        :isPlaying="isPlaying"
        :isMuted="isMuted"
        :volume="volume"
        :brightness="brightness"
        :playbackRate="playbackRate"
        :disablePrev="currentIndex === 0"
        :disableNext="currentIndex === videoList.length - 1"
        :showGestureHelp="showHelp"
        :playMode="playMode"
        @update:showGestureHelp="emit('update:showHelp', $event)"
        @prev="prevVideo"
        @next="nextVideo"
        @togglePlay="togglePlay"
        @mute="toggleMute"
        @volumeChange="changeVolume"
        @brightnessChange="changeBrightness"
        @rateChange="changeRate"
        @fullscreen="enterFullscreen"
        @seekForward="seekForward"
        @seekBackward="seekBackward"
        @modeToggle="togglePlayMode"
      />

      <!-- 新增摄像头控制 -->
      <div style="margin-top: 20px;">
        <button @click="toggleCamera">
          {{ isCameraOn ? '关闭摄像头' : '开启摄像头' }}
        </button>
        <br />
        <video
          ref="cameraVideo"
          autoplay
          muted
          playsinline
          style="width: 320px; height: 240px; background: #000; margin-top: 10px;"
          v-show="isCameraOn"
        ></video>
      </div>
    </div>
  </div>
</template>


<style scoped>
.video-player {
  display: flex;
  flex-direction: row;
}

.video-list {
  position: absolute;
  top: 50px;
  left: -50px;
  width: 180px;
  height: 700px;
  background-color: #eaf4fc;
  padding: 20px 15px;
  border-right: 1px solid #d0e3f1;
  border-radius: 10px 0 0 10px;
  box-shadow: 2px 4px 10px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
  transition: transform 0.3s ease;
  z-index: 10;
}

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