import AppKit

@MainActor
enum BeaconMenuIcon {
    static func image(active: Bool, tint: NSColor? = nil) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            defer { context.restoreGState() }

            let foreground = tint ?? NSColor.black
            foreground.setStroke()
            foreground.setFill()

            let rays = NSBezierPath()
            rays.lineWidth = 1.5
            rays.lineCapStyle = .round
            rays.move(to: NSPoint(x: 4.4, y: 6.1))
            rays.line(to: NSPoint(x: 1.5, y: 4.9))
            rays.move(to: NSPoint(x: 13.6, y: 6.1))
            rays.line(to: NSPoint(x: 16.5, y: 4.9))
            rays.stroke()

            let roof = NSBezierPath()
            roof.lineWidth = 1.5
            roof.lineJoinStyle = .round
            roof.move(to: NSPoint(x: 4.7, y: 7.1))
            roof.line(to: NSPoint(x: 6.5, y: 5.2))
            roof.line(to: NSPoint(x: 11.5, y: 5.2))
            roof.line(to: NSPoint(x: 13.3, y: 7.1))
            roof.close()

            let lamp = NSBezierPath(roundedRect: NSRect(x: 5.7, y: 7.0, width: 6.6, height: 3.3), xRadius: 0.8, yRadius: 0.8)
            let tower = NSBezierPath()
            tower.lineWidth = 1.5
            tower.lineJoinStyle = .round
            tower.move(to: NSPoint(x: 6.6, y: 10.3))
            tower.line(to: NSPoint(x: 5.1, y: 15.8))
            tower.line(to: NSPoint(x: 12.9, y: 15.8))
            tower.line(to: NSPoint(x: 11.4, y: 10.3))
            tower.close()

            let water = NSBezierPath()
            water.lineWidth = 1.4
            water.lineCapStyle = .round
            water.move(to: NSPoint(x: 2.8, y: 17.0))
            water.curve(to: NSPoint(x: 15.2, y: 17.0), controlPoint1: NSPoint(x: 6.0, y: 16.3), controlPoint2: NSPoint(x: 12.0, y: 17.7))

            if active {
                rays.lineWidth = 2.0
                rays.stroke()
                roof.fill()
                lamp.fill()
                tower.fill()
                water.stroke()
                let window = NSBezierPath(roundedRect: NSRect(x: 8.0, y: 7.8, width: 2.0, height: 1.8), xRadius: 0.8, yRadius: 0.8)
                NSColor.white.withAlphaComponent(tint == nil ? 1 : 0.9).setFill()
                window.fill()
            } else {
                roof.stroke()
                lamp.stroke()
                tower.stroke()
                water.stroke()
                let window = NSBezierPath(ovalIn: NSRect(x: 8.05, y: 7.7, width: 1.9, height: 1.9))
                window.fill()
            }
            return true
        }
        image.isTemplate = tint == nil
        return image
    }
}
