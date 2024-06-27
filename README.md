
# 〜StreamUI [BETA!]

[![Team Chat](https://design.vapor.codes/images/discordchat.svg)](https://discord.gg/NpHj7brca4)
[![MIT License](https://design.vapor.codes/images/mitlicense.svg)](LICENSE)
[![Swift 5.10+](https://design.vapor.codes/images/swift510up.svg)](https://swift.org)


<!--[![Discord](https://img.shields.io/discord/1071029581009657896?style=flat&logo=discord&logoColor=fff&color=404eed)](https://discord.gg/NpHj7brca4)-->
<!--[![CI](https://github.com/pointfreeco/swift-clocks/workflows/CI/badge.svg)](https://github.com/pointfreeco/swift-clocks/actions?query=workflow%3ACI)-->
<!--[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-clocks%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-clocks)-->
<!--[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-clocks%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-clocks)-->
<!--![ChatGPT](https://img.shields.io/badge/chatGPT-74aa9c?style=for-the-badge&logo=openai&logoColor=white)-->
<!--![X](https://img.shields.io/badge/X-%23000000.svg?style=for-the-badge&logo=X&logoColor=white)-->

🎥 Make videos programmatically with SwiftUI (and even stream them live to Youtube, Twitch, or more). I am still actively developing this and testing it so please give feedback!

## What is StreamUI?

StreamUI is a library designed for SwiftUI that enables developers to create dynamic videos programmatically. It goes beyond traditional video generation tools like Remotion, offering real-time video rendering and live streaming capabilities. Ideal for applications ranging from faceless Tiktok/Youtube shorts videos to live event broadcasting, and much more. StreamUI lets you create video templates in SwiftUI and render them with dynamic inputs.

* **Real-Time Video Rendering**
<br> Generate and manipulate video content on the fly using Swift code. This feature allows for the seamless integration of animations, text overlays, and media, adapting dynamically to user interactions 
or external data.

* **Live Streaming**
<br> Broadcast live video streams directly from your application. This functionality is perfect for apps that require sharing events as they happen, such as live tutorials, gaming sessions, or interactive webinars.

* **Dynamic video generation**
<br> Generate dynamic videos. Pull in data from your database, react to outside events, generate batches of videos in different sizes, AB test videos in bulk. You can do it all. 


| | Why StreamUI & why create videos with SwiftUI? |
|-------|------------------------------------------------|
| 📡 | The only programatically generated video library that supports Live streaming capabilities to platforms like YouTube and Twitch |
| 🔄 | Videos are rendered in Real-time instead of requiring you to render on serverless functions in a parellel manner |
| 💻 | Leverage Swift's power and SwiftUI's declarative syntax |
| 🎨 | Create reusable video templates with SwiftUI |
| 🔧 | Highly customizable and extensible. Use variables, functions, API calls, remote events, access your database, pull in remote images/audio/video and incorporate any of those into dynamically generated videos |
| 📊 | Generate batches of videos with different params, sizes or more variables for A/B testing |

## Requirements
If people want support for < less please open a ticket. 

* **Xcode 15+**
* **Swift 5.10**
* **MacOS Sonoma**


## Get started

* **Download the starter:**
	* 
	`git clone https://github.com/StreamUI/streamui-	starter`
* **Or start from scratch, and create a Package.swift file**

	```swift
	
	// swift-tools-version:5.10
	
	import PackageDescription
	
	let package = Package(
	    name: "MyNewExecutable",
	    platforms: [
	        .macOS(.v14),
	    ],
	    dependencies: [
	        .package(url: "https://github.com/StreamUI/StreamUI.git", from: "0.1.0"),
	    ],
	    targets: [
	        .executableTarget(
	            name: "MyNewExecutable",
	            dependencies: [
	                .product(name: "StreamUI", package: "StreamUI"),
	            ]
	        ),
	    ]
	)
	```

* **Make sure target is MacOS**
* **Simple Example**

```swift
import StreamUI
import SwiftUI

public struct SwiftUIVideoExample: View {
    @Environment(\.recorder) private var recorder

    @State private var currentImageIndex = 0

    let imageUrls = [
        "https://sample-videos.com/img/Sample-jpg-image-5mb.jpg",
        "https://mogged-pullzone.b-cdn.net/people/8336bde2-3d36-41c3-a8ad-9c9d5413eff6.jpg?class=mobile",
        "https://mogged-pullzone.b-cdn.net/people/0880cf5d-10d1-49b2-b468-e84d19f5bdca.jpg",
        "https://mogged-pullzone.b-cdn.net/people/08c08ae7-732e-4966-917f-f94174daa024.jpg",
        "https://mogged-pullzone.b-cdn.net/people/0a4f6fc6-bc77-4b4a-9dfb-c690b5931625.jpg"
    ]

    public init() {}
    public var body: some View {
        VStack {
            StreamingImage(url: URL(string: imageUrls[currentImageIndex])!, scaleType: .fill)
                .frame(width: 1080, height: 1920)
                .id(currentImageIndex)
        }
        .onAppear(perform: startTimer)
    }

    private func startTimer() {
        Task {
            while true {
                try await recorder?.controlledClock.clock.sleep(for: .milliseconds(1000))
                currentImageIndex = (currentImageIndex + 1) % imageUrls.count
            }
        }
    }
}


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
	SwiftUIVideoExample()
}

recorder.startRecording()

try await Task.sleep(for: .seconds(5))
recorder.pauseRecording()
try await Task.sleep(for: .seconds(10))
recorder.resumeRecording()

// Wait for the recording to complete
await recorder.waitForRecordingCompletion()
```

* **swift run** or build xcode

* **Video will automatically stop recording after the  specified time and if specified will start live streaming!**


## Supported SwiftUI Views

Please note. As it is written now we are at the whims of `ImageRenderer`, which comes with this warning

> ImageRenderer output only includes views that SwiftUI renders, such as text, images, shapes, and composite views of these types. It does not render views provided by native platform frameworks (AppKit and UIKit) such as web views, media players, and some controls. For these views, ImageRenderer displays a placeholder image, similar to the behavior of drawingGroup(opaque:colorMode:).


| Feature                  | Status                                                                                   |
|--------------------------|------------------------------------------------------------------------------------------|
| Images                   | ✅                                                                                        |
| Shapes                   | ✅ (Rectangle, Circle, Ellipse, Capsule, ...)                                                  |
| Path                     | ✅                                                                                        |
| Divider                  | ✅                                                                                        |
| Canvas                   | ✅                                                                                        |
| Grid                     | ✅                                                                                        |
| HStack                   | ✅                                                                                        |
| ZStack                   | ✅                                                                                        |
| VStack                   | ✅                                                                                        |
| LinearGradient           | ✅                                                                                        |
| Animations               | ✅ (They work, but seem to need to be based off the frame count / shared clock. See examples) |
| VideoPlayer              | 🚧 (Only with StreamUI custom `StreamingVideoPlayer`. WIP)                                |
| Audio                    | 🚧 (StreamUI has a custom audio player that works. WIP -> Expect issues)                  |
| ActivityIndicator        | 🚧 (I created a custom `StreamingActivityIndicator` you can use)                          |
| Button                   | ❌                                                                                        |
| Map                      | ❌                                                                                        |
| ScrollView               | ❌                                                                                        |
| Link                     | ❌                                                                                        |
| Slider                   | ❌                                                                                        |
| Toggle                   | ❌                                                                                        |
| TextField                | ❌                                                                                        |
| Stepper                  | ❌                                                                                        |
| Picker                   | ❌                                                                                        |
| Gauge                    | ❌                                                                                        |
| Menu                     | ❌                                                                                        |
| SpriteKit                | ❌                                                                                        |
| SceneKit                 | ❌                                                                                        |

## Properties

| name                           | Description  |
---------------------------------|----------------
setHContentHugging               | Adjusts the priority for a view to resist growing beyond its intrinsic size horizontally.
setVContentHugging               | Adjusts the priority for a view to resist growing beyond its intrinsic size vertically.
setHContentCompressionResistance | Adjusts the priority for a view to resist shrinking below its intrinsic size horizontally.
setVContentCompressionResistance | Adjusts the priority for a view to resist shrinking below its intrinsic size vertically.
makeRatio                        | Sets the aspect ratio constraint for the view's size.
cornerRadius                     | Applies a corner radius to the view to create rounded corners.
border                           | Adds a border with specified color and width to the view.
background                       | Sets the background color of the view.
makeContentMode                  | Sets the content mode of the view.
frame                            | Positions the view within a specified frame size.
padding                          | Adds padding around specific edges of the view.
allowsHitTesting                 | Enables or disables the view's interaction with touch events.
masksToBounds                    | Clips the view's sublayers to its boundaries.
accessibilityIdentifier          | Assigns an identifier used to find this view in tests.
overlay                          | Places specified views in front of the view.
background                       | Layers the views that you specify behind this view.
center                           | Centers the view within a new parent view.
tint                             | Applies a tint color to the view.
opacity                          | Sets the transparency level of the view.
scaleEffect                      | Scales the view by specified factors along the x and y axes.
rotationEffect                   | Rotates the view by a specified angle around a given anchor point.


## Todo

- [ ] Video should be able to stream audio
- [ ] Advanced Video controls 
- [ ] Better audio functionality
- [ ] Video lengths get messed up when audio is involved. Duration gets 2x longer. I currently trim the video to expected duration but it seems hacky


## Comparison

[You can see code here comparing creation of a video with the different libraries](https://github.com/StreamUI/streamui-vs-remotion-vs-revideo)


The biggest differences between StreamUI and Revideo & Remotion:

* **React/JS vs SwiftUI**. Remotion uses React and Revideo uses generator functions. As a previous React lover, I strongly believe SwiftUI is the greater UI framework. Further, you can use any Swift library to help you out whereas with React and rendering videos in the browser canvas you are limited on what NPM modules you can use. 
* **Livestreaming capability**. Neither Remotion or Revideo support live streaming or plan to ([as far as we can tell](https://www.remotion.dev/docs/miscellaneous/live-streaming)). For them, supporting live streaming would be a massize change. For StreamUI with how it's built, adding live streaming was incredibly simple. 
* **Realtime rendering**. StreamUI can achieve > 100fps on SwiftUI views. Remotion/Revideo utilize the browsers canvas to generate images and encourage parallelizing your video rendering using serverless functions. I have seen estimates of 1 frame taking seconds/minutes to render. However, I believe Revideo does have some impressive optimizations achieving faster than real time rendering. [See Here](https://x.com/MatternJustus/status/1805679156560036237). However, one thing I personally didn't like when using remotion was that everything has to be built relative to the frame number so that the parallelization can do its thing. It's akward but makes sense of course, but StreamUI doesn't have that requirement as frames are added to the video in realtime on the device it's being run. Potentially in the future we could do parallelization to get faster than real time rendering if desired
* **Browser vs Native**. In remotion I was getting a lot of these depending on the NPM package I wanted to use. Maybe there is a way to work around it?
`ERROR in ./node_modules/dotenv/lib/main.js 2:13-28
Module not found: Error: Can't resolve 'path' in '/remotion/node_modules/dotenv/lib'
BREAKING CHANGE: webpack < 5 used to include polyfills for node.js core modules by default.
This is no longer the case. Verify if you need this module and configure a polyfill for it.`


## Contributing
This is an open-source project, contributions are welcome! The goal of StreamUI is to be the most powerful library for programatically creating and streaming videos. Please open tickets, submit PRs or [join the Discord](https://discord.gg/NpHj7brca4)


## Inspired By
 
* **[Remotion](https://www.remotion.dev)** 
* **[Revideo](https://re.video)** 
* **Google Stadia**
* **[Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)** 
