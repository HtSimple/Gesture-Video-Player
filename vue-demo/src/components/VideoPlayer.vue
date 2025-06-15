<script setup>
// 导入Vue组合式API所需的响应式工具和生命周期钩子
import { ref, onMounted, nextTick, onBeforeUnmount, reactive } from 'vue'
import ControlBar from './ControlBar.vue' // 导入自定义控制栏组件
import axios from 'axios' // 导入HTTP请求库

// 定义组件属性（父组件可通过showHelp控制是否显示帮助信息）
const props = defineProps({
  showHelp: Boolean
})
// 定义组件事件（用于通知父组件更新showHelp状态）
const emit = defineEmits(['update:showHelp'])

// ----------------------- 视频播放核心状态 -----------------------
const videoList = ref([]) // 存储视频文件列表的响应式数据
const currentIndex = ref(0) // 当前播放视频的索引
const currentVideoSrc = ref('') // 当前视频的源地址
const videoElement = ref(null) // 视频DOM元素的引用

// ----------------------- 播放控制状态 -----------------------
const isPlaying = ref(false) // 视频是否正在播放
const isMuted = ref(false) // 是否静音
const volume = ref(50) // 音量大小（0-100）
const brightness = ref(100) // 亮度调节（0-100）
const playbackRate = ref(1.0) // 播放速率
const playMode = ref('loop') // 播放模式（单曲循环/列表循环/随机播放）
let previousVolume = 50 // 静音前的音量备份

// ----------------------- 摄像头与手势识别状态 -----------------------
const cameraVideo = ref(null) // 摄像头视频DOM元素的引用
const isCameraOn = ref(false) // 摄像头是否开启
let cameraStream = null // 摄像头媒体流对象
const gestureCanvas = document.createElement('canvas') // 手势识别用的画布元素

let gestureInterval = null // 手势识别定时器

// ----------------------- 全屏状态管理 -----------------------
const isFullscreen = ref(false) // 是否处于全屏模式

// ----------------------- 手势指令防抖控制 -----------------------
const gestureControl = reactive({
  lastCommand: '', // 上一次识别的手势指令
  lastTime: 0, // 上一次指令的时间戳
  debounceTime: 3000 // 防抖时间（3秒内相同指令不重复执行）
})

// ----------------------- 生命周期钩子 -----------------------
// 组件挂载后执行初始化操作
onMounted(() => {
  // 初始化视频列表
  videoList.value = []
  // 若列表有视频，自动选择第一个播放
  if (videoList.value.length) selectVideo(0)

  nextTick(() => {
    if (videoElement.value) {
      // 监听视频播放结束事件
      videoElement.value.addEventListener('ended', handleEnded)
      
      // 监听全屏状态变化（兼容不同浏览器的全屏API）
      document.addEventListener('fullscreenchange', handleFullscreenChange)
      document.addEventListener('webkitfullscreenchange', handleFullscreenChange)
      document.addEventListener('mozfullscreenchange', handleFullscreenChange)
      document.addEventListener('MSFullscreenChange', handleFullscreenChange)
    }
  })
})

// 组件卸载前执行资源释放操作
onBeforeUnmount(() => {
  stopGestureRecognition() // 停止手势识别
  stopCamera() // 停止摄像头
  
  // 移除全屏状态监听
  document.removeEventListener('fullscreenchange', handleFullscreenChange)
  document.removeEventListener('webkitfullscreenchange', handleFullscreenChange)
  document.removeEventListener('mozfullscreenchange', handleFullscreenChange)
  document.removeEventListener('MSFullscreenChange', handleFullscreenChange)
  
  // 释放所有视频的Object URL资源（避免内存泄漏）
  videoList.value.forEach(item => {
    if (item?.url) {
      URL.revokeObjectURL(item.url)
    }
  })
})

// ----------------------- 视频播放控制函数 -----------------------
// 选择并播放指定索引的视频（异步函数，处理视频加载和播放）
async function selectVideo(index) {
  currentIndex.value = index
  const videoItem = videoList.value[index]
  
  // 首次加载时为视频文件创建Object URL
  if (!videoItem.url) {
    videoItem.url = URL.createObjectURL(videoItem.file)
  }
  
  currentVideoSrc.value = videoItem.url
  
  // 等待DOM更新后设置视频源
  await nextTick()
  
  if (videoElement.value) {
    try {
      // 设置视频基础属性（音量、静音状态、播放速率）
      videoElement.value.volume = volume.value / 100
      videoElement.value.muted = isMuted.value
      videoElement.value.playbackRate = playbackRate.value
      
      // 尝试播放视频（处理浏览器自动播放限制）
      await videoElement.value.play()
      isPlaying.value = true
    } catch (error) {
      console.error('播放失败:', error)
      alert(`视频播放失败: ${error.message}`)
    }
  }
}

// 播放上一个视频（索引减1，若当前为第一个则不执行）
function prevVideo() {
  if (currentIndex.value > 0) selectVideo(currentIndex.value - 1)
}

// 播放下一个视频（索引加1，若当前为最后一个则不执行）
function nextVideo() {
  if (currentIndex.value < videoList.value.length - 1) selectVideo(currentIndex.value + 1)
}

// 视频时间回退（秒数为负则向前跳转）
function seekBackward(seconds) {
  if (videoElement.value) {
    videoElement.value.currentTime = Math.max(0, videoElement.value.currentTime - seconds)
  }
}

// 视频时间前进（不超过视频总时长）
function seekForward(seconds) {
  if (videoElement.value) {
    videoElement.value.currentTime = Math.min(videoElement.value.duration, videoElement.value.currentTime + seconds)
  }
}

// 切换视频播放/暂停状态
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

// 切换静音状态（记录静音前音量，便于恢复）
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

// 调整视频音量（同步更新静音状态）
function changeVolume(val) {
  volume.value = val
  isMuted.value = val === 0

  if (videoElement.value) {
    videoElement.value.volume = val / 100
    videoElement.value.muted = isMuted.value
  }
}

// 调整视频亮度（通过CSS滤镜实现）
function changeBrightness(val) {
  brightness.value = val
}

// 调整视频播放速率
function changeRate(val) {
  playbackRate.value = val
  if (videoElement.value) {
    videoElement.value.playbackRate = val
  }
}

// 切换全屏模式（兼容不同浏览器的全屏API）
function toggleFullscreen() {
  if (!videoElement.value) return
  
  if (!isFullscreen.value) {
    // 进入全屏
    if (videoElement.value.requestFullscreen) {
      videoElement.value.requestFullscreen()
    } else if (videoElement.value.webkitRequestFullscreen) { // Chrome/Safari/Edge
      videoElement.value.webkitRequestFullscreen()
    } else if (videoElement.value.mozRequestFullScreen) { // Firefox
      videoElement.value.mozRequestFullScreen()
    } else if (videoElement.value.msRequestFullscreen) { // IE/Edge
      videoElement.value.msRequestFullscreen()
    } else {
      console.error('浏览器不支持全屏API')
    }
  } else {
    // 退出全屏
    if (document.exitFullscreen) {
      document.exitFullscreen()
    } else if (document.webkitExitFullscreen) {
      document.webkitExitFullscreen()
    } else if (document.mozCancelFullScreen) {
      document.mozCancelFullScreen()
    } else if (document.msExitFullscreen) {
      document.msExitFullscreen()
    } else {
      console.error('浏览器不支持退出全屏')
    }
  }
}

// 监听全屏状态变化并更新组件状态
function handleFullscreenChange() {
  // 检测当前是否处于全屏状态（兼容不同浏览器）
  isFullscreen.value = !!(document.fullscreenElement || 
                          document.webkitFullscreenElement || 
                          document.mozFullScreenElement || 
                          document.msFullscreenElement);
  console.log(`当前全屏状态: ${isFullscreen.value}`)
}

// 切换播放模式（循环/单曲/随机）
function togglePlayMode() {
  const modes = ['loop', 'single', 'shuffle']
  const current = modes.indexOf(playMode.value)
  playMode.value = modes[(current + 1) % modes.length]
}

// 处理视频播放结束事件（根据不同模式执行相应操作）
function handleEnded() {
  if (!videoElement.value) return

  if (playMode.value === 'single') {
    // 单曲模式：重新从0秒开始播放
    videoElement.value.currentTime = 0
    videoElement.value.play()
  } else if (playMode.value === 'loop') {
    // 列表循环：播放下一个视频（或回到第一个）
    if (currentIndex.value < videoList.value.length - 1) {
      selectVideo(currentIndex.value + 1)
    } else {
      selectVideo(0)
    }
  } else if (playMode.value === 'shuffle') {
    // 随机播放：生成不重复当前视频的随机索引
    let next
    do {
      next = Math.floor(Math.random() * videoList.value.length)
    } while (next === currentIndex.value && videoList.value.length > 1)
    selectVideo(next)
  }
}

// ----------------------- 摄像头控制函数 -----------------------
// 启动摄像头（请求媒体权限并设置视频源）
async function startCamera() {
  try {
    // 请求摄像头访问权限
    cameraStream = await navigator.mediaDevices.getUserMedia({ video: true })
    if (cameraVideo.value) {
      // 设置摄像头视频源为媒体流
      cameraVideo.value.srcObject = cameraStream
      isCameraOn.value = true
      startGestureRecognition() // 启动手势识别
    }
  } catch (err) {
    alert('无法打开摄像头，请检查权限')
    isCameraOn.value = false
  }
}

// 停止摄像头（释放媒体流资源）
function stopCamera() {
  if (cameraStream) {
    // 停止媒体流中的所有轨道
    cameraStream.getTracks().forEach(track => track.stop())
    cameraStream = null
  }
  isCameraOn.value = false
  stopGestureRecognition() // 停止手势识别
}

// 切换摄像头开关状态
function toggleCamera() {
  if (isCameraOn.value) {
    stopCamera()
  } else {
    startCamera()
  }
}

// ----------------------- 手势识别函数 -----------------------
// 启动手势识别（定时捕获摄像头画面并发送识别请求）
function startGestureRecognition() {
  stopGestureRecognition() // 先停止已有的识别定时器
  if (!isCameraOn.value) return

  // 每1500ms捕获一次摄像头画面
  gestureInterval = setInterval(async () => {
    if (!cameraVideo.value || cameraVideo.value.readyState < 2) return

    const ctx = gestureCanvas.getContext('2d')
    // 设置画布尺寸与摄像头画面一致
    gestureCanvas.width = cameraVideo.value.videoWidth
    gestureCanvas.height = cameraVideo.value.videoHeight
    // 将摄像头画面绘制到画布上
    ctx.drawImage(cameraVideo.value, 0, 0, gestureCanvas.width, gestureCanvas.height)

    // 将画布内容转换为图片Blob并发送到服务器识别
    gestureCanvas.toBlob(async (blob) => {
      if (!blob) return
      const formData = new FormData()
      formData.append('file', blob, 'frame.jpg') 
      try {
        const res = await axios.post('http://localhost:5000/api/gesture/predict', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        handleGestureCommand(res.data.gesture) // 处理识别到的手势指令
      } catch (err) {
        console.error('识别失败:', err)
      }
    }, 'image/jpeg', 0.8)
  }, 1500)
}

// 停止手势识别（清除定时器）
function stopGestureRecognition() {
  if (gestureInterval) clearInterval(gestureInterval)
}

// 手势命令处理函数（包含防抖逻辑和指令映射）
function handleGestureCommand(cmd) {
  const now = new Date().getTime();
  const { lastCommand, lastTime, debounceTime } = gestureControl;
  
  // 防抖处理：相同指令在debounceTime内不重复执行
  if (cmd.gesture === lastCommand && now - lastTime < debounceTime) {
    console.log(`忽略重复指令: ${cmd.gesture} (${(now - lastTime)/1000}s内)`)
    return;
  }
  
  // 更新最后执行的指令和时间
  gestureControl.lastCommand = cmd.gesture;
  gestureControl.lastTime = now;
  
  // 根据不同手势执行对应的播放器操作
  switch (cmd.gesture) {
    case 'like':
      prevVideo();
      console.log('识别到指令: 上一个视频');
      break;
    case 'dislike':
      nextVideo();
      console.log('识别到指令: 下一个视频');
      break;
    case 'stop':
      togglePlay();
      console.log('识别到指令: 播放/暂停');
      break;
    case 'mute':
      toggleMute();
      console.log('识别到指令: 静音/取消静音');
      break;
    case 'ok':
      togglePlayMode();
      console.log('识别到指令: 播放模式切换');
      break;
    case 'palm':
      toggleFullscreen()
      console.log('识别到指令: 全屏切换，当前状态', isFullscreen.value);
      break;
    case 'one':
      emit('update:showHelp', !props.showHelp); // 通知父组件切换帮助栏显示状态
      console.log('识别到指令: 显示/隐藏手势帮助');
      break;
    default:
      console.log('未识别指令:', cmd.gesture);
  }
}

// ----------------------- 视频文件管理函数 -----------------------
// 处理用户选择文件夹/文件事件（导入本地视频）
async function handleFolderSelect(event) {
  const files = event.target.files
  if (!files.length) return

  // 过滤出视频文件（通过MIME类型或后缀名）
  const videoFiles = Array.from(files).filter(file => 
    file.type.startsWith('video/') || 
    /\.(mp4|webm|ogg|mov|mkv)$/i.test(file.name)
  )

  if (videoFiles.length === 0) {
    alert('所选文件夹中没有视频文件')
    return
  }

  // 创建视频元数据列表（保存文件名、文件对象等信息）
  videoList.value = videoFiles.map(file => ({
    name: file.name,
    file: file,           // 保存原始File对象
    url: null,            // 后续生成Object URL
    type: file.type
  }))
  
  // 选择并播放第一个视频
  if (videoList.value.length > 0) {
    await selectVideo(0)
  }
}
</script>

<template>
  <div class="video-player">
    <!-- 视频列表侧边栏（通过showHelp控制显示/隐藏） -->
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
            accept="video/mp4,video/webm,video/ogg"
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
          {{ video.name }}
        </li>
      </ul>
    </div>

    <!-- 视频播放主区域 -->
    <div class="video-area">
      <video
        ref="videoElement"
        :src="currentVideoSrc"
        controls
        :style="{ width: '100%', maxHeight: '600px', filter: `brightness(${brightness}%)` }"
        @error="console.error('视频加载错误')"
      ></video>

      <!-- 控制栏组件（传递播放状态并监听用户操作） -->
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
        :isFullscreen="isFullscreen"
        @update:showGestureHelp="emit('update:showHelp', $event)"
        @prev="prevVideo"
        @next="nextVideo"
        @togglePlay="togglePlay"
        @mute="toggleMute"
        @volumeChange="changeVolume"
        @brightnessChange="changeBrightness"
        @rateChange="changeRate"
        @fullscreen="toggleFullscreen"
        @seekForward="seekForward"
        @seekBackward="seekBackward"
        @modeToggle="togglePlayMode"
      />

      <!-- 摄像头控制区域（显示/隐藏基于isCameraOn状态） -->
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
  transform: translateX(-200px); /* 隐藏侧边栏的位移量 */
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