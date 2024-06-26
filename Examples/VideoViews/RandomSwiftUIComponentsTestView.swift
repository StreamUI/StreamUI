//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import SwiftUI

public struct RandomSwiftUIComponentsTestView: View {
    @State private var toggleState = false
    @State private var sliderValue: Double = 0.5
    @State private var textFieldText = ""
    @State private var pickerSelection = 0

    public init() {}

    public var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Label")
                    Label("This is a label", systemImage: "star")
                }

                Divider()
                Group {
                    Text("Linear Gradient")
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                }

                Divider()

                Group {
                    Text("Button")
                    Button(action: {
                        print("Button tapped")
                    }) {
                        Text("Tap me")
                    }
                }

                Divider()

                Group {
                    Text("Toggle")
                    Toggle(isOn: $toggleState) {
                        Text("Enable feature")
                    }
                }

                Divider()

                Group {
                    Text("Slider")
                    Slider(value: $sliderValue, in: 0...1)
                    Text("Value: \(sliderValue)")
                }

                Divider()

                Group {
                    Text("TextField")
                    TextField("Enter text", text: $textFieldText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Divider()

                Group {
                    Text("Stepper")
                    Stepper(value: $sliderValue, in: 0...10, step: 1) {
                        Text("Value: \(Int(sliderValue))")
                    }
                }

                Divider()

                Group {
                    Text("Picker")
                    Picker("Options", selection: $pickerSelection) {
                        Text("Option 1").tag(0)
                        Text("Option 2").tag(1)
                        Text("Option 3").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Divider()

                Group {
                    Text("ActivityIndicator")
                    ProgressView()
                }

                Divider()

                Group {
                    Text("Shapes")
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green)
                            .frame(width: 50, height: 50)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 50, height: 50)
                        Ellipse()
                            .fill(Color.yellow)
                            .frame(width: 70, height: 50)
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: 70, height: 30)
                    }
                }

                Divider()

                Group {
                    Text("Path")
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 100, y: 100))
                    }
                    .stroke(Color.black, lineWidth: 2)
                }

                Divider()

                Group {
                    Text("Canvas")
                    Canvas { context, size in
                        context.stroke(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .color(.blue), lineWidth: 2)
                    }
                    .frame(height: 100)
                }

                Divider()

                Group {
                    Text("Gauge")
                    Gauge(value: sliderValue, in: 0...1) {
                        Text("Speed")
                    }
                }

                Divider()

                Group {
                    Text("Map")
                    // Replace with actual Map implementation if needed
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 200)
                        .overlay(Text("Map Placeholder").foregroundColor(.white))
                }

                Divider()

                Group {
                    Text("Link")
                    Link("Open Apple", destination: URL(string: "https://www.apple.com")!)
                }

                Divider()

                Group {
                    Text("Toolbar and Menu")
                    Menu("Menu") {
                        Button("Option 1", action: { print("Option 1 selected") })
                        Button("Option 2", action: { print("Option 2 selected") })
                    }
                }

                Divider()

                Group {
                    Text("Grid")
                    Grid {
                        GridRow {
                            Text("Row 1, Col 1")
                            Text("Row 1, Col 2")
                        }
                        GridRow {
                            Text("Row 2, Col 1")
                            Text("Row 2, Col 2")
                        }
                    }
                }
                .foregroundColor(.black)

                Divider()

                Text("WHAT ABOUT THIS")
                    .foregroundColor(.black)

//                Group {
//                    Text("ColorPicker")
//                    ColorPicker("Pick a color", selection: $textFieldText, supportsOpacity: false)
//                }
            }
            .padding()
        }
    }
}
