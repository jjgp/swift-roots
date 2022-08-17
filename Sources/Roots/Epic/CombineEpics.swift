import Combine

public extension Epic {
    static func combine(epics: Self...) -> Self {
        combine(epics: epics)
    }

    static func combine(epics: [Self]) -> Self {
        .init { states, actions in
            Publishers.MergeMany(epics.map { epic in
                epic.createPublisher(states, actions)
            })
        }
    }

    static func combine<Dependencies>(
        dependencies: Dependencies,
        and dependentEpics: DependentEpic<State, Action, Dependencies>...
    ) -> Self {
        combine(dependencies: dependencies, and: dependentEpics)
    }

    static func combine<Dependencies>(
        dependencies: Dependencies,
        and dependentEpics: [DependentEpic<State, Action, Dependencies>]
    ) -> Self {
        combine(epics: dependentEpics.map {
            $0.createEpic(dependencies)
        })
    }
}
