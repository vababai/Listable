//
//  Item.swift
//  BlueprintUILists
//
//  Created by Kyle Van Essen on 9/10/20.
//

import Listable
import BlueprintUI


extension Item
{
    public init<Represented>(
        _ representing : Represented,
        
        identifier : @escaping (Represented) -> AnyHashable,
        
        isEquivalent : @escaping (Represented, Represented) -> Bool,
        
        element : @escaping (Represented, ApplyItemContentInfo) -> Element,
        background : @escaping (Represented, ApplyItemContentInfo) -> Element? = { _, _ in nil },
        selectedBackground : @escaping (Represented, ApplyItemContentInfo) -> Element? = { _, _ in nil },
        
        configure : (inout Item<BlueprintItemContentWrapper<Represented>>) -> () = { _ in }
        
    ) where Content == BlueprintItemContentWrapper<Represented>
    {
        self.init(
            BlueprintItemContentWrapper<Represented>(
                representing: representing,
                
                identifierProvider: identifier,
                isEquivalentProvider: isEquivalent,
                elementProvider: element,
                backgroundProvider: background,
                selectedBackgroundProvider: selectedBackground
            ),
            build: configure
        )
    }
    
    public init<Represented>(
        _ representing : Represented,
        
        identifier : @escaping (Represented) -> AnyHashable,
                
        element : @escaping (Represented, ApplyItemContentInfo) -> Element,
        background : @escaping (Represented, ApplyItemContentInfo) -> Element? = { _, _ in nil },
        selectedBackground : @escaping (Represented, ApplyItemContentInfo) -> Element? = { _, _ in nil },
        
        configure : (inout Item<BlueprintItemContentWrapper<Represented>>) -> () = { _ in }
        
    ) where Content == BlueprintItemContentWrapper<Represented>, Represented:Equatable
    {
        self.init(
            BlueprintItemContentWrapper<Represented>(
                representing: representing,
                
                identifierProvider: identifier,
                isEquivalentProvider: { $0 == $1 },
                elementProvider: element,
                backgroundProvider: background,
                selectedBackgroundProvider: selectedBackground
            ),
            build: configure
        )
    }
}


public struct BlueprintItemContentWrapper<Represented> : BlueprintItemContent
{
    public var representing : Represented

    var identifierProvider : (Represented) -> AnyHashable
    var isEquivalentProvider : (Represented, Represented) -> Bool
    var elementProvider : (Represented, ApplyItemContentInfo) -> Element
    var backgroundProvider : (Represented, ApplyItemContentInfo) -> Element?
    var selectedBackgroundProvider : (Represented, ApplyItemContentInfo) -> Element?
    
    public var identifier: Identifier<Self> {
        .init(self.identifierProvider(self.representing))
    }
    
    public func isEquivalent(to other: Self) -> Bool {
        self.isEquivalentProvider(self.representing, other.representing)
    }
    
    public func element(with info: ApplyItemContentInfo) -> Element {
        self.elementProvider(self.representing, info)
    }
    
    public func backgroundElement(with info: ApplyItemContentInfo) -> Element? {
        self.backgroundProvider(self.representing, info)
    }
    
    public func selectedBackgroundElement(with info: ApplyItemContentInfo) -> Element? {
        self.selectedBackgroundProvider(self.representing, info)
    }
}
