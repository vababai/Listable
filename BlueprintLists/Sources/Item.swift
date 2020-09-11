//
//  Item.swift
//  BlueprintLists
//
//  Created by Kyle Van Essen on 9/10/20.
//

import Listable


public extension Item
{
    static func element<Content>(
        _ content : Content,
        
        identifier : @escaping (Content) -> AnyHashable,
        
        isEquivalent : @escaping (Content, Content) -> Bool,
        
        element : @escaping (Content, ApplyItemContentInfo) -> Element,
        background : @escaping (Content, ApplyItemContentInfo) -> Element? = { _, _ in nil },
        selectedBackground : @escaping (Content, ApplyItemContentInfo) -> Element? = { _, _ in nil },
        
        configure : (inout Item<BlueprintItemContentWrapper<Content>>) -> () = { _ in }
        
    ) -> Item<BlueprintItemContentWrapper<Content>>
    {
        Item<BlueprintItemContentWrapper<Content>>(
            BlueprintItemContentWrapper<Content>(
                content: content,
                identifierProvider: identifier,
                isEquivalent: isEquivalent,
                element: element,
                background: background,
                selectedBackground: selectedBackground
                
            ),
            build: configure
        )
    }
}


public struct BlueprintItemContentWrapper<Content> : BlueprintItemContent
{
    public var content : Content

    var identifierProvider : (Content) -> AnyHashable
    var isEquivalent : (Content, Content) -> Bool
    var element : (Content, ApplyItemContentInfo) -> Element
    var background : (Content, ApplyItemContentInfo) -> Element?
    var selectedBackground : (Content, ApplyItemContentInfo) -> Element?
    
    public var identifier: Identifier<Self> {
        .init(self.identifierProvider(self.content))
    }
    
    public func isEquivalent(to other: Self) -> Bool {
        self.isEquivalent(self.content, other.content)
    }
    
    public func element(with info: ApplyItemContentInfo) -> Element {
        self.element(self.content, info)
    }
    
    public func backgroundElement(with info: ApplyItemContentInfo) -> Element? {
        self.background(self.content, info)
    }
    
    public func selectedBackgroundElement(with info: ApplyItemContentInfo) -> Element? {
        self.selectedBackground(self.content, info)
    }
}
