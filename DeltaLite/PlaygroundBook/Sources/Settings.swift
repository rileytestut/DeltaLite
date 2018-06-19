//
//  Settings.swift
//  DeltaLite
//
//  Created by Riley Testut on 6/19/18.
//

import UIKit

extension KeyboardGameController.Input: ExpressibleByStringLiteral
{
    public init(stringLiteral value: String)
    {
        self = KeyboardGameController.Input(value)
    }
    
    public init(unicodeScalarLiteral value: String)
    {
        self.init(stringLiteral: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String)
    {
        self.init(stringLiteral: value)
    }
}

public class Settings: Codable
{
    public var inputs = Inputs()
    
    public var gameFilter: Filter?
    
    public static var shared = Settings()
    
    internal lazy var keyboardInputMapping: GameControllerInputMapping = {
        var inputMapping = GameControllerInputMapping(gameControllerInputType: .keyboard)
        inputMapping.set(NESGameInput.a, forControllerInput: self.inputs.a)
        inputMapping.set(NESGameInput.b, forControllerInput: self.inputs.b)
        inputMapping.set(NESGameInput.up, forControllerInput: self.inputs.up)
        inputMapping.set(NESGameInput.down, forControllerInput: self.inputs.down)
        inputMapping.set(NESGameInput.left, forControllerInput: self.inputs.left)
        inputMapping.set(NESGameInput.right, forControllerInput: self.inputs.right)
        inputMapping.set(NESGameInput.start, forControllerInput: self.inputs.start)
        inputMapping.set(NESGameInput.select, forControllerInput: self.inputs.select)
        inputMapping.set(StandardGameControllerInput.menu, forControllerInput: self.inputs.menu)
        
        return inputMapping
    }()
    
    private init()
    {
    }
}

extension Settings
{
    public struct Inputs: Codable
    {
        public var a: KeyboardGameController.Input = "x"
        public var b: KeyboardGameController.Input = "z"
        
        public var up: KeyboardGameController.Input = .up
        public var down: KeyboardGameController.Input = .down
        public var left: KeyboardGameController.Input = .left
        public var right: KeyboardGameController.Input = .right
        
        public var start: KeyboardGameController.Input = .return
        public var select: KeyboardGameController.Input = .tab
        
        public var menu: KeyboardGameController.Input = "p"
        
        fileprivate init()
        {
        }
    }
    
    public enum Filter: Codable
    {
        case blur(radius: Double)
        case sepia(intensity: Double)
        case invert
        case grayscale(intensity: Double)
        case custom(ciFilter: CIFilter)
        
        public var ciFilter: CIFilter {
            switch self
            {
            case .blur(let radius): return CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius": radius])!
            case .sepia(let intensity): return CIFilter(name: "CISepiaTone", withInputParameters: ["inputIntensity": intensity])!
            case .invert: return CIFilter(name: "CIColorInvert")!
            case .grayscale(let intensity): return CIFilter(name: "CIColorMonochrome", withInputParameters: ["inputColor": CIColor(color: .darkGray), "inputIntensity": intensity])!
            case .custom(let ciFilter): return ciFilter
            }
        }
        
        private enum CodingKeys: String, CodingKey
        {
            case type
            case radius
            case intensity
            case ciFilter
        }
        
        public init(from decoder: Decoder) throws
        {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let type = try container.decode(String.self, forKey: .type)
            
            switch type
            {
            case "blur":
                let radius = try container.decode(Double.self, forKey: .radius)
                self = .blur(radius: radius)
                
            case "sepia":
                let intensity = try container.decode(Double.self, forKey: .intensity)
                self = .sepia(intensity: intensity)
                
            case "invert":
                self = .invert
                
            case "grayscale":
                let intensity = try container.decode(Double.self, forKey: .intensity)
                self = .grayscale(intensity: intensity)
                
            case "custom":
                let data = try container.decode(Data.self, forKey: .ciFilter)
                
                guard let ciFilter = NSKeyedUnarchiver.unarchiveObject(with: data) as? CIFilter else {
                    throw DecodingError.dataCorruptedError(forKey: .ciFilter, in: container, debugDescription: "Encoded data is not valid CIFilter.")
                }
                
                self = .custom(ciFilter: ciFilter)
                
            default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unsupported filter type.")
            }
        }
        
        public func encode(to encoder: Encoder) throws
        {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self
            {
            case .blur(let radius):
                try container.encode("blur", forKey: .type)
                try container.encode(radius, forKey: .radius)
                
            case .sepia(let intensity):
                try container.encode("sepia", forKey: .type)
                try container.encode(intensity, forKey: .intensity)
                
            case .invert: try container.encode("invert", forKey: .type)
                
            case .grayscale(let intensity):
                try container.encode("grayscale", forKey: .type)
                try container.encode(intensity, forKey: .intensity)
                
            case .custom(let ciFilter):
                try container.encode("custom", forKey: .type)
                
                let data = NSKeyedArchiver.archivedData(withRootObject: ciFilter)
                try container.encode(data, forKey: .ciFilter)
            }
        }
    }
}

func testFunc()
{
    let settings = Settings.shared
    
    settings.inputs.a = "A"
    settings.inputs.b = "B"
    
    settings.gameFilter = .blur(radius: 10)
    
    do
    {
        let data = try PropertyListEncoder().encode(settings)
        
    }
    catch
    {
        print(error)
    }
}
