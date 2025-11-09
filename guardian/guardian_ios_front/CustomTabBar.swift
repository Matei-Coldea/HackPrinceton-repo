import SwiftUI

struct CustomTabBar<TabItemView: View>: UIViewRepresentable {
    // explicit associated type
    typealias UIViewType = UISegmentedControl

    var size: CGSize
    var activeTint: Color = .blue
    var barTint: Color = .gray.opacity(0.15)
    @Binding var activeTab: CustomTab

    @ViewBuilder var tabItemView: (CustomTab) -> TabItemView

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let items = CustomTab.allCases.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        
        for (index, tab) in CustomTab.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))
            
            renderer.scale = 2
            let image = renderer.uiImage
            
            control.setImage(image, forSegmentAt: index)
        }
        
        
        DispatchQueue.main.async{
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last{
                    subview.alpha = 0
                }
            }
        }
        
        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(Color(red: 0.22, green: 0.69, blue: 0.0))
        ], for: .selected)
        
        // Set initial selected index based on activeTab
        if let index = CustomTab.allCases.firstIndex(of: activeTab) {
            control.selectedSegmentIndex = index
        }
        
        control.addTarget(context.coordinator,
                          action: #selector(context.coordinator.tabSelected(_:)),
                          for: .valueChanged)
        
        
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        // Update the selected segment when activeTab changes
        if let index = CustomTab.allCases.firstIndex(of: activeTab) {
            if uiView.selectedSegmentIndex != index {
                uiView.selectedSegmentIndex = index
            }
        }
        
        // Update images if needed (in case tabItemView changed)
        for (index, tab) in CustomTab.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))
            renderer.scale = 2
            if let image = renderer.uiImage {
                uiView.setImage(image, forSegmentAt: index)
            }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return size
    }
    
    class Coordinator: NSObject {
        var parent: CustomTabBar

        init(parent: CustomTabBar) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            parent.activeTab = CustomTab.allCases[control.selectedSegmentIndex]
        }
    }
}

// Convenience initializer for converting SwiftUI Color -> UIColor
#Preview{
    Tabb()
}
