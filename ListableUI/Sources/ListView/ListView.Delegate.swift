//
//  ListView.Delegate.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 11/19/19.
//


extension ListView
{
    final class Delegate : NSObject, UICollectionViewDelegate, CollectionViewLayoutDelegate
    {
        unowned var view : ListView!
        unowned var presentationState : PresentationState!
        
        private let itemMeasurementCache = ReusableViewCache()
        private let headerFooterMeasurementCache = ReusableViewCache()
        
        private let headerFooterViewCache = ReusableViewCache()
        
        func didChangeContent() {
            self.scrollToTopRevertOffset = nil
        }
        
        // MARK: UICollectionViewDelegate
        
        func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
        {
            guard view.behavior.selectionMode != .none else { return false }
            
            let item = self.presentationState.item(at: indexPath)
            
            return item.anyModel.selectionStyle.isSelectable
        }
        
        func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.applyToVisibleCell(with: self.view.environment)
        }
        
        func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.applyToVisibleCell(with: self.view.environment)
        }
        
        func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
        {
            guard view.behavior.selectionMode != .none else { return false }
            
            let item = self.presentationState.item(at: indexPath)
            
            return item.anyModel.selectionStyle.isSelectable
        }
        
        func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
        {
            return true
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.set(isSelected: true, performCallbacks: true)
            item.applyToVisibleCell(with: self.view.environment)
            
            self.performOnSelectChanged()
            
            if item.anyModel.selectionStyle == .tappable {
                item.set(isSelected: false, performCallbacks: true)
                collectionView.deselectItem(at: indexPath, animated: true)
                item.applyToVisibleCell(with: self.view.environment)
                
                self.performOnSelectChanged()
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.set(isSelected: false, performCallbacks: true)
            item.applyToVisibleCell(with: self.view.environment)
            
            self.performOnSelectChanged()
        }
        
        private var oldSelectedItems : Set<AnyIdentifier> = []
        
        private func performOnSelectChanged() {
            
            let old = self.oldSelectedItems
            
            let new = Set(self.presentationState.selectedItems.map(\.anyModel.identifier))
            
            guard old != new else {
                return
            }
            
            self.oldSelectedItems = new
            
            ListStateObserver.perform(self.view.stateObserver.onSelectionChanged, "Selection Changed", with: self.view) {
                ListStateObserver.SelectionChanged(
                    actions: $0,
                    positionInfo: self.view.scrollPositionInfo,
                    old: old,
                    new: new
                )
            }
        }
        
        private var displayedItems : [ObjectIdentifier:AnyPresentationItemState] = [:]
        
        func collectionView(
            _ collectionView: UICollectionView,
            willDisplay cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
            )
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.willDisplay(cell: cell, in: collectionView, for: indexPath)
            
            self.displayedItems[ObjectIdentifier(cell)] = item
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            didEndDisplaying cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
            )
        {
            guard let item = self.displayedItems.removeValue(forKey: ObjectIdentifier(cell)) else {
                return
            }
            
            item.didEndDisplay()
        }
        
        private var displayedSupplementaryItems : [ObjectIdentifier:PresentationState.HeaderFooterViewStatePair] = [:]
        
        func collectionView(
            _ collectionView: UICollectionView,
            willDisplaySupplementaryView anyView: UICollectionReusableView,
            forElementKind kindString: String,
            at indexPath: IndexPath
            )
        {
            let container = anyView as! SupplementaryContainerView
            let kind = SupplementaryKind(rawValue: kindString)!
            
            let headerFooter : PresentationState.HeaderFooterViewStatePair = {
                switch kind {
                case .listHeader: return self.presentationState.header
                case .listFooter: return self.presentationState.footer
                case .sectionHeader: return self.presentationState.sections[indexPath.section].header
                case .sectionFooter: return self.presentationState.sections[indexPath.section].footer
                case .overscrollFooter: return self.presentationState.overscrollFooter
                }
            }()
            
            headerFooter.willDisplay(view: container)
            
            self.displayedSupplementaryItems[ObjectIdentifier(view)] = headerFooter
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            didEndDisplayingSupplementaryView view: UICollectionReusableView,
            forElementOfKind elementKind: String,
            at indexPath: IndexPath
            )
        {
            guard let headerFooter = self.displayedSupplementaryItems.removeValue(forKey: ObjectIdentifier(view)) else {
                return
            }
            
            headerFooter.didEndDisplay()
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
            toProposedIndexPath proposedIndexPath: IndexPath
            ) -> IndexPath
        {
            
            if originalIndexPath != proposedIndexPath {
                // TODO: Validate
                // let item = self.presentationState.item(at: originalIndexPath)
                
                if originalIndexPath.section == proposedIndexPath.section {
                    self.view.storage.moveItem(from: originalIndexPath, to: proposedIndexPath)
                    
                    return proposedIndexPath
                } else {
                    return originalIndexPath
                }
            } else {
                return proposedIndexPath
            }
        }
        
        // MARK: CollectionViewLayoutDelegate
        
        func listViewLayoutUpdatedItemPositions(_ collectionView : UICollectionView)
        {
            self.view.setPresentationStateItemPositions()
        }
        
        func listLayoutContent(
            defaults: ListLayoutDefaults
        ) -> ListLayoutContent
        {
            self.presentationState.toListLayoutContent(
                defaults: defaults,
                environment: self.view.environment
            )
        }

        // MARK: UIScrollViewDelegate
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
        {
            // Notify swipe actions to close.

            NotificationCenter.default.post(Notification(name: .closeSwipeActions, object: self))
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
        {
            self.view.updatePresentationState(for: .didEndDecelerating)
        }
        
        private var scrollToTopRevertOffset : CGPoint? = nil
        private var scrollingToTop : Bool = false
                
        func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool
        {
            switch view.behavior.scrollsToTop {
            case .disabled: break
                
            case .enabled(let reverts):
                if let revert = self.scrollToTopRevertOffset {
                    scrollView.isUserInteractionEnabled = false
                    
                    self.scrollToTopRevertOffset = nil
                     
                    self.view.revertScrollToTopForStatusBarTap(with: revert) { finished in
                        scrollView.isUserInteractionEnabled = true
                        self.view.updatePresentationState(for: .scrolledToTop)
                    }
                } else {
                    if reverts {
                        self.scrollToTopRevertOffset = scrollView.contentOffset
                    } else {
                        self.scrollToTopRevertOffset = nil
                    }
                    
                    scrollView.isUserInteractionEnabled = false
                    self.scrollingToTop = true
                    
                    self.view.scrollToTopForStatusBarTap { finished in
                        scrollView.isUserInteractionEnabled = true
                        self.scrollingToTop = false
                        
                        self.view.updatePresentationState(for: .scrolledToTop)
                    }
                }
            }
            
            return false
        }
        
        func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
        {
            fatalError("Should never occur. `scrollViewShouldScrollToTop(_:)` should always return false.")
        }
        
        private var lastPosition : CGFloat = 0.0
        
        func scrollViewDidScroll(_ scrollView: UIScrollView)
        {
            if self.scrollingToTop == false {
                self.scrollToTopRevertOffset = nil
            }
            
            guard scrollView.bounds.size.height > 0 else { return }
                        
            SignpostLogger.log(.begin, log: .scrollView, name: "scrollViewDidScroll", for: self.view)
            
            defer {
                SignpostLogger.log(.end, log: .scrollView, name: "scrollViewDidScroll", for: self.view)
            }
            
            // Updating Paged Content
            
            let scrollingDown = self.lastPosition < scrollView.contentOffset.y
            
            self.lastPosition = scrollView.contentOffset.y
            
            if scrollingDown {
                self.view.updatePresentationState(for: .scrolledDown)
            }
            
            ListStateObserver.perform(self.view.stateObserver.onDidScroll, "Did Scroll", with: self.view) {
                ListStateObserver.DidScroll(
                    actions: $0,
                    positionInfo: self.view.scrollPositionInfo
                )
            }
        }
    }
}
