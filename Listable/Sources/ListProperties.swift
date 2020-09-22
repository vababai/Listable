//
//  ListProperties.swift
//  Listable
//
//  Created by Kyle Van Essen on 11/9/19.
//

import Foundation


///
/// The `ListProperties` object describes all of the given values needed to configure
/// and display a list on screen. It is usually used in declarative APIs which deal in descriptions of views
/// (eg, Blueprint, SwiftUI, `ListViewController`) in place of referencing and managing a view directly.
///
/// For example, in `BlueprintLists`, you create a Listable `List` element like so:
/// ```
/// List { list in
///     list.appearance = .myAppearance
///     list.layout = .myLayout
///
///     list("first section") { section in
///         section += MyItem()
///         section += MyItem()
///     }
/// }
/// ```
/// In this example, the `list` parameter to the trailing closure is a `ListProperties` object.
///
/// Other Uses
/// ----------
/// You may even find using `ListProperties` useful if you do have a reference to the underlying `ListView`
/// instance (eg in your own `UIViewController`).
///
/// In these cases, you can apply `ListProperties` to a `ListView` by calling one of the
/// available `func configure(with:)` methods. Having a separate method which describes and provides
/// all the properties to configure your `ListView` allows for a more singular flow of data through your application,
/// and eases in testibility.
public struct ListProperties
{
    //
    // MARK: Animated Changes
    //
    
    /// If the changes applied should be animated or not.
    /// Defaults to `true` if `ListProperties` is created inside an existing `UIView` animation block.
    public var animatesChanges : Bool
    
    //
    // MARK: List Content
    //
    
    /// The content displayed by the list.
    /// Note that you do not need to reference `list.content` to add sections to the content.
    /// `ListProperties` has helper methods which allow directly adding sections to the `list`:
    /// ```
    /// let list : ListProperties = ...
    ///
    /// list("section one") { section in
    ///
    /// }
    ///
    /// list += Section("section two") { section in
    ///
    /// }
    /// ```
    public var content : Content

    //
    // MARK: Layout & Appearance
    //
    
    /// The layout type to use with the list. Defaults to `.list()`, aka a list
    /// with no spacing and full width headers, footers, and content.
    ///
    /// If you would like to change the layout to either a new type, or provide
    /// a `list` with different configuration options, assign it here.
    ///
    /// ```
    /// list.layout = .list {
    ///     $0.stickySectionHeaders = true
    ///
    ///     $0.layout.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    ///     $0.layout.itemSpacing = 10.0
    /// }
    /// ```
    public var layout : LayoutDescription
    
    /// The appearance to use with the list.
    public var appearance : Appearance
    
    /// The scroll insets to apply to the list view.
    public var scrollInsets : ScrollInsets
    
    //
    // MARK: Behaviour
    //
    
    /// The various behaviour options to apply to the list, which affect how the user
    /// will interact with the list view. This includes keyboard dismissal, selection mode,
    /// underflow behaviour, etc.
    ///
    /// Note that some of the parameters within `Behavior` are not authoritative;
    /// they may be overridden by the provided `layout`. For example, even if your
    /// `behavior` disables scroll view paging, the `.paged` layout will enable it.
    public var behavior : Behavior
    
    //
    // MARK: Reading State & Performing Actions
    //
    
    /// The state reader to use with your list. A `ListStateObserver`
    /// allows for observing changes to the list as they happen,
    /// either due to user interaction, content update, view hierarchy changes, etc.
    /// See the `ListStateObserver` type for more.
    public var stateObserver : ListStateObserver
    
    /// The actions instance to use to control the list, eg to scroll to a given
    /// row or enable interactive view transitions. See the `ListActions` type
    /// for more information.
    ///
    /// Note that you can only associate one `ListActions` with a list at a given time.
    /// When a new instance is provided, the old one becomes a no-op instance; calling
    /// methods on it will have no effect.
    ///
    public var actions : ListActions?
    
    /// The auto scroll action to apply to the list. This allows you to
    /// scroll to a given item on insert depending on the current state
    /// of the view.
    public var autoScrollAction : AutoScrollAction
    
    //
    // MARK: Identifiers
    //
    
    /// The accessibility identifier assigned to the inner `UICollectionView`.
    public var accessibilityIdentifier: String?
    
    /// The debugging identifier assigned to the list. Used for `os_signpost` integration
    /// you can observe through Instruments.app.
    public var debuggingIdentifier: String?
    
    //
    // MARK: Initialization
    //

    public typealias Build = (inout ListProperties) -> ()
    
    /// An instance of `ListProperties` with sensible default values.
    public static func `default`(with builder : Build = { _ in }) -> Self {
        Self(
            animatesChanges: UIView.inheritedAnimationDuration > 0.0,
            layout: .list(),
            appearance: .init(),
            scrollInsets: .init(),
            behavior: .init(),
            autoScrollAction: .none,
            accessibilityIdentifier: nil,
            debuggingIdentifier: nil,
            build: builder
        )
    }
    
    /// Create a new instance of `ListProperties` with the provided values.
    public init(
        animatesChanges: Bool,
        layout : LayoutDescription,
        appearance : Appearance,
        scrollInsets : ScrollInsets,
        behavior : Behavior,
        autoScrollAction : AutoScrollAction,
        accessibilityIdentifier: String?,
        debuggingIdentifier: String?,
        build : Build
    ) {
        self.animatesChanges = animatesChanges
        self.layout = layout
        self.appearance = appearance
        self.scrollInsets = scrollInsets
        self.behavior = behavior
        self.autoScrollAction = autoScrollAction
        self.accessibilityIdentifier = accessibilityIdentifier
        self.debuggingIdentifier = debuggingIdentifier
        
        self.content = Content()
        self.stateObserver = ListStateObserver()

        build(&self)
    }
    
    //
    // MARK: Mutating Content
    //
    
    /// Updates the `ListProperties` object with the changes in the provided builder.
    public mutating func modify(using builder : Build) {
        builder(&self)
    }
    
    /// Creates a new `ListProperties` object modified by the changes in the provided builder.
    public func modified(using builder : Build) -> ListProperties {
        var copy = self
        builder(&copy)
        return copy
    }
    
    /// Adds a new section to the `content`.
    public mutating func add(_ section : Section)
    {
        self.content.sections.append(section)
    }
    
    /// Adds a new section to the `content`.
    public static func += (lhs : inout ListProperties, rhs : Section)
    {
        lhs.add(rhs)
    }
    
    /// Adds a list of new sections to the `content`.
    public static func += (lhs : inout ListProperties, rhs : [Section])
    {
        lhs.content.sections += rhs
    }
    
    /// Allows streamlined creation of sections when building a list.
    ///
    /// Example
    /// -------
    /// ```
    /// listView.configure { list in
    ///     list("section-id") { section in
    ///         ...
    ///     }
    /// }
    /// ```
    public mutating func callAsFunction<Identifier:Hashable>(_ identifier : Identifier, build : Section.Build)
    {
        self += Section(identifier, build: build)
    }
}

