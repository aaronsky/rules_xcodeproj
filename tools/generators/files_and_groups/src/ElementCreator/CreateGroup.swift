import PBXProj

extension ElementCreator {
    struct CreateGroup {
        private let createGroupElement: CreateGroupElement
        private let createGroupChildElements:
            CreateGroupChildElements

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createGroupChildElements:
                CreateGroupChildElements,
            createGroupElement: CreateGroupElement,
            callable: @escaping Callable
        ) {
            self.createGroupChildElements = createGroupChildElements
            self.createGroupElement = createGroupElement

            self.callable = callable
        }

        func callAsFunction(
            for groupNode: PathTreeNode.Group,
            name: String,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            createGroupChild: CreateGroupChild
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*groupNode:*/ groupNode,
                /*name:*/ name,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createGroupElement:*/ createGroupElement
            )
        }
    }
}

// MARK: - CreateGroup.Callable

extension ElementCreator.CreateGroup {
    typealias Callable = (
        _ groupNode: PathTreeNode.Group,
        _ name: String,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createGroupElement: ElementCreator.CreateGroupElement
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for groupNode: PathTreeNode.Group,
        name: String,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createGroupElement: ElementCreator.CreateGroupElement
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = BazelPath(parent: parentBazelPath, path: name)

        let groupChildren = groupNode.children.map { node in
            return createGroupChild(
                for: node,
                parentBazelPath: bazelPath,
                specialRootGroupType: specialRootGroupType
            )
        }

        let children = createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren
        )

        let (
            group,
            resolvedRepository
        ) = createGroupElement(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: children.elements.map(\.object.identifier)
        )

        return GroupChild.ElementAndChildren(
            bazelPath: bazelPath,
            element: group,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: resolvedRepository,
            children: children
        )
    }
}
