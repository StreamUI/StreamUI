
# StreamUI [BETA!]

[![Discord](https://img.shields.io/discord/1071029581009657896?style=flat&logo=discord&logoColor=fff&color=404eed)](https://discord.gg/NpHj7brca4)
<!--[![CI](https://github.com/pointfreeco/swift-clocks/workflows/CI/badge.svg)](https://github.com/pointfreeco/swift-clocks/actions?query=workflow%3ACI)-->
<!--[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-clocks%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-clocks)-->
<!--[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-clocks%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-clocks)-->
<!--![ChatGPT](https://img.shields.io/badge/chatGPT-74aa9c?style=for-the-badge&logo=openai&logoColor=white)-->
<!--![X](https://img.shields.io/badge/X-%23000000.svg?style=for-the-badge&logo=X&logoColor=white)-->

🎥 Make videos programmatically with SwiftUI (and even stream them live to Youtube, Twitch, or more). I am still actively developing this and testing it so please give feedback!


## Why create videos in SwiftUI?

- **Leverage Swifts power**: Use (almost) all Swift and SwiftUI has to offer
- **Leverage programming**: Use variables, functions, APIs, remote events, access your database, pull images, videos & audio from remote sources and incorporate all of that into dynamic videos


## What is StreamUI?

StreamUI is a library designed for SwiftUI that enables developers to create dynamic videos programmatically. It goes beyond traditional video generation tools like Remotion, offering real-time video rendering and live streaming capabilities. Ideal for applications ranging from faceless Tiktok/Youtube shorts videos to live event broadcasting, and much more. StreamUI lets you create video templates in SwiftUI and render them with dynamic inputs.

* **Real-Time Video Rendering**
<br> Generate and manipulate video content on the fly using Swift code. This feature allows for the seamless integration of animations, text overlays, and media, adapting dynamically to user interactions 
or external data.

* **Live Streaming**
<br> Broadcast live video streams directly from your application. This functionality is perfect for apps that require sharing events as they happen, such as live tutorials, gaming sessions, or interactive webinars.

* **Dynamic video generation**
<br> Generate dynamic videos. Pull in data from your database, react to outside events, generate batches of videos in different sizes, AB test videos in bulk. You can do it all. 

## Requirements
If people want support for < less please open a ticket. 

* **Xcode 15+**
* **Swift 5.10**
* **MacOS Sonoma**


## Get started

* **Download the starter:**
* 
```
git clone https://github.com/StreamUI/streamui-starter
```
* **Or start from scratch**

```
.package(url: "https://github.com/StreamUI/StreamUI.git", from: "0.1.0"),
```

```
.product(name: "StreamUI", package: "StreamUI"),
```

* **Make sure target is MacOS**
* **Create a recorder**

```
        let recorder = createStreamUIRecorder(
            fps: 30,
            width: 1080,
            height: 1920,
            displayScale: 2.0,
            captureDuration: .seconds(30),
            saveVideoFile: true,
             livestreamSettings: [
                .init(rtmpConnection: "rtmp://localhost/live", streamKey: "streamKey")
            ]
        ) {
			YourSwiftUIViewThatWillBeRecordedHere()
        }
```
* **Start recording**

```
recorder.startRecording()
```

* **Video will automatically stop recording after specified time**


## Supported SwiftUI Views

Please note. As it is written now we are at the whims of `ImageRenderer`, which comes with this warning

> ImageRenderer output only includes views that SwiftUI renders, such as text, images, shapes, and composite views of these types. It does not render views provided by native platform frameworks (AppKit and UIKit) such as web views, media players, and some controls. For these views, ImageRenderer displays a placeholder image, similar to the behavior of drawingGroup(opaque:colorMode:).


- [x] Images
- [x] Shapes (Rectangle, Circle, Ellipse, Capsule)
- [x] Path
- [x] Divider
- [x] Canvas
- [x] Grid
- [x] HStack, ZStack, VStack
- [x] LinearGradient
- [-] VideoPlayer (Only with StreamUI custom `StreamingVideoPlayer`. WIP)
- [-] Audio (StreamUI has a custom audio player that works. WIP -> Expect issues)
- [-] Animations (They work, but seem to need to be based off the frame count / shared clock. See examples)
- [-] ActivityIndicator (I created a custom `StreamingActivityIndicator` you can use)
- [ ] Button
- [ ] Map
- [ ] ScrollView
- [ ] Link
- [ ] Slider
- [ ] Toggle
- [ ] TextField
- [ ] Stepper
- [ ] Picker
- [ ] Gauge
- [ ] Menu


## Todo

- [ ] Video should be able to stream audio
- [ ] Advanced Video controls 
- [ ] Better audio functionality


## Comparison

[You can see code here comparing creation of a video with the different libraries](http://github.com)


The biggest differences between StreamUI and Revideo & Remotion:

* **React/JS vs SwiftUI**. Remotion uses React and Revideo uses generator functions. As a previous React lover, I strongly believe SwiftUI is the greater UI framework. Further, you can use any Swift library to help you out whereas with React and rendering videos in the browser canvas you are limited on what NPM modules you can use. 
* **Livestreaming capability**. Neither Remotion or Revideo support live streaming or plan to ([as far as we can tell](https://www.remotion.dev/docs/miscellaneous/live-streaming)). For them, supporting live streaming would be a massize change. For StreamUI with how it's built, adding live streaming was incredibly simple. 
* **Realtime rendering**. StreamUI can achieve > 100fps on SwiftUI views. Remotion/Revideo utilize the browsers canvas to generate images and encourage parallelizing your video rendering using serverless functions. I have seen estimates of 1 frame taking seconds/minutes to render. However, I believe Revideo does have some impressive optimizations achieving faster than real time rendering. [See Here](https://x.com/MatternJustus/status/1805679156560036237). However, one thing I personally didn't like when using remotion was that everything has to be built relative to the frame number so that the parallelization can do its thing. It's akward but makes sense of course, but StreamUI doesn't have that requirement as frames are added to the video in realtime on the device it's being run. Potentially in the future we could do parallelization to get faster than real time rendering if desired



## Inspired By
 
* **[Remotion](https://www.remotion.dev)** 
* **[Revideo](https://re.video)** 
* **Google Stadia**
* **[Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)** 
