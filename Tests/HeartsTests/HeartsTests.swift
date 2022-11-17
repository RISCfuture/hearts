import XCTest
import Nimble
import Quick
@testable import libHearts

final class EmojiArtSpec: QuickSpec {
    var image: CIImage {
        let url = Bundle.module.url(forResource: "basic", withExtension: "png")!
        return .init(contentsOf: url)!
    }
    
    var transparentImage: CIImage {
        let url = Bundle.module.url(forResource: "transparent", withExtension: "png")!
        return .init(contentsOf: url)!
    }
    
    private func result(for name: String) -> String {
        let url = Bundle.module.url(forResource: name, withExtension: "txt")!
        let string = try! String(contentsOf: url)
        return string.trimmingCharacters(in: .newlines)
    }
    
    override func spec() {
        describe("process") {
            it("converts an image into emoji-art") {
                let instance = try! EmojiArt()
                let string = try! await instance.process(image: self.image)
                await expect(string).toEventually(equal(self.result(for: "basic")))
            }
            
            it("permits a custom coherency") {
                let instance = try! EmojiArt(coherency: 0.1)
                let string = try! await instance.process(image: self.image)
                await expect(string).toEventually(equal(self.result(for: "coherency")))
            }
            
            it("permits a custom character set") {
                let chars = Set("📕📗📘📙📔📓")
                let instance = try! EmojiArt(characters: chars)
                let string = try! await instance.process(image: self.image)
                await expect(string).toEventually(equal(self.result(for: "chars")))
            }
            
            it("permits a custom group") {
                let instance = try! EmojiArt(group: "hearts")
                let string = try! await instance.process(image: self.image)
                await expect(string).toEventually(equal(self.result(for: "group")))
            }
            
            it("permits a custom background color") {
                let instance = try! EmojiArt()
                let stringBlack = try! await instance.process(image: self.transparentImage)
                await expect(stringBlack).toEventually(equal(self.result(for: "transparent-black")))
                
                instance.backgroundColor = try! .init(red: 1, green: 1, blue: 1)
                let stringWhite = try! await instance.process(image: self.transparentImage)
                await expect(stringWhite).toEventually(equal(self.result(for: "transparent-white")))
            }
        }
    }
}
