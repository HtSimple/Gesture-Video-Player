# 项目介绍   
这是一个简单的基于手势识别的视频播放器，前端基于vue3+vite+ts+element-plus实现，后端基于flask实现。项目包含了七种手势识别相应功能，如播放/暂停，静音与解除等。此外，还有基础的视频播放所需功能，如快进，倍速切换等，只不过没有加入相应的手势。项目的具体信息及运行程序如下(按顺序先运行后端，再运行前端)：

## 后端(flask-demo)

###  运行方法(进入flask-demo文件夹)   
1. 将训练好的模型放置到 models 文件夹中
   预加载模型名字为"YOLOv10x_gestures.pt"，详情可见 service/gesture_model.py 中的模型加载代码
2. 首次使用点击 setup.bat 文件，自动创建虚拟环境 myvenv 并运行
3. 之后使用时点击 start.bat 即可（点 setup.bat 也行）   (请不要关闭该cmd窗口)

## 前端(vue-demo)

### 环境准备   
1.下载并安装Node.js    下载地址：https://nodejs.org/zh-cn      
2.在cmd界面输入 Node -v  和   npm -v ,正常应该显示出版本   
3.在vue-demo文件夹进入cmd界面，依次输入
```
npm install -g pnpm   

pnpm install   

pnpm add element-plus vue-router axios
```

###  运行
在vue-demo文件夹进入cmd界面，输入
```
npm run dev
```
然后复制弹出的路径(即http://localhost:5173/)到浏览器打开即可。

