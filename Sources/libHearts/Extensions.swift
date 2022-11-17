import Foundation

extension Collection {
    func inGroupsOf(_ size: Int) -> any Sequence<any Sequence<Element>> {
        var groups = Array<Array<Element>>()
        for (n, i) in enumerated() {
            if n % size == 0 { groups.append([]) }
            groups[groups.endIndex.advanced(by: -1)].append(i)
        }
        
        return groups.map { $0 as any Sequence<Element> } as any Sequence<any Sequence<Element>>
    }
}
