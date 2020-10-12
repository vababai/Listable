//
//  HeaderFooter.swift
//  BlueprintUILists
//
//  Created by Kyle Van Essen on 10/9/20.
//

import Listable


extension HeaderFooter
{
    public init<Represented>(
        _ representing : Represented,
        
        isEquivalent : @escaping (Represented, Represented) -> Bool,
        
        element : @escaping (Represented) -> Element,
        background : @escaping (Represented) -> Element? = { _ in nil },
        pressedBackground : @escaping (Represented) -> Element? = { _ in nil },
        
        configure : (inout HeaderFooter<BlueprintHeaderFooterContentWrapper<Represented>>) -> () = { _ in }
        
    ) where Content == BlueprintHeaderFooterContentWrapper<Represented>
    {
        self.init(
            BlueprintHeaderFooterContentWrapper<Represented>(
                representing: representing,
                isEquivalentProvider: isEquivalent,
                elementProvider: element,
                backgroundProvider: background,
                pressedBackgroundProvider: pressedBackground
            ),
            build: configure
        )
    }
    
    public init<Represented>(
        _ representing : Represented,
        
        identifier : @escaping (Represented) -> AnyHashable,
                
        element : @escaping (Represented) -> Element,
        background : @escaping (Represented) -> Element? = { _ in nil },
        selectedBackground : @escaping (Represented) -> Element? = { _ in nil },
        
        configure : (inout HeaderFooter<BlueprintHeaderFooterContentWrapper<Represented>>) -> () = { _ in }
        
    ) where Content == BlueprintHeaderFooterContentWrapper<Represented>, Represented:Equatable
    {
        self.init(
            BlueprintHeaderFooterContentWrapper<Represented>(
                representing: representing,
                isEquivalentProvider: { $0 == $1 },
                elementProvider: element,
                backgroundProvider: background,
                pressedBackgroundProvider: selectedBackground
            ),
            build: configure
        )
    }
}


public struct BlueprintHeaderFooterContentWrapper<Represented> : BlueprintHeaderFooterContent
{
    public var representing : Represented

    var isEquivalentProvider : (Represented, Represented) -> Bool
    var elementProvider : (Represented) -> Element
    var backgroundProvider : (Represented) -> Element?
    var pressedBackgroundProvider : (Represented) -> Element?
    
    public func isEquivalent(to other: Self) -> Bool {
        self.isEquivalentProvider(self.representing, other.representing)
    }
    
    public var elementRepresentation : Element {
        self.elementProvider(self.representing)
    }
    
    public var background : Element? {
        self.backgroundProvider(self.representing)
    }
    
    public var pressedBackground : Element? {
        self.pressedBackgroundProvider(self.representing)
    }
}
