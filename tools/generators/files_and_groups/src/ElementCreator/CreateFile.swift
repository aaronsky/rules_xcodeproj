import PBXProj

extension ElementCreator {
    struct CreateFile {
        private let collectBazelPaths: CollectBazelPaths
        private let createFileElement: CreateFileElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            collectBazelPaths: CollectBazelPaths,
            createFileElement: CreateFileElement,
            callable: @escaping Callable
        ) {
            self.collectBazelPaths = collectBazelPaths
            self.createFileElement = createFileElement

            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            bazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            identifierForBazelPaths: String? = nil,
            createIdentifier: ElementCreator.CreateIdentifier
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*node:*/ node,
                /*bazelPath:*/ bazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*identifierForBazelPaths:*/ identifierForBazelPaths,
                /*collectBazelPaths:*/ collectBazelPaths,
                /*createFileElement:*/ createFileElement,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateFile.Callable

extension ElementCreator.CreateFile {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ identifierForBazelPaths: String?,
        _ collectBazelPaths: ElementCreator.CollectBazelPaths,
        _ createFileElement: ElementCreator.CreateFileElement,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for node: PathTreeNode,
        bazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        identifierForBazelPaths: String?,
        collectBazelPaths: ElementCreator.CollectBazelPaths,
        createFileElement: ElementCreator.CreateFileElement,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> GroupChild.ElementAndChildren {
        let (
            element,
            resolvedRepository
        ) = createFileElement(
            name: node.name,
            nameNeedsPBXProjEscaping: node.nameNeedsPBXProjEscaping,
            ext: node.extension(),
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            createIdentifier: createIdentifier
        )

        let bazelPaths = collectBazelPaths(
            node: node,
            bazelPath: bazelPath
        )

        let identifierForBazelPaths =
            identifierForBazelPaths ?? element.object.identifier

        return GroupChild.ElementAndChildren(
            element: element,
            transitiveObjects: [element.object],
            bazelPathAndIdentifiers:
                bazelPaths.map { ($0, identifierForBazelPaths) },
            knownRegions: [],
            resolvedRepositories: resolvedRepository.map { [$0] } ?? []
        )
    }
}

private extension PathTreeNode {
    func `extension`() -> String? {
        guard let extIndex = name.lastIndex(of: ".") else {
            return nil
        }
        return String(name[name.index(after: extIndex)..<name.endIndex])
    }
}
