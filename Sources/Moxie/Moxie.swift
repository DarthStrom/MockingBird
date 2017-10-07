public class Moxie {

    var stubbings = [String: [String: [Any]]]()
    var invocations = [MockInvocation]()

    public init() {}

    /// Sets a return value for a stubbed function call.
    ///
    /// - Parameters:
    ///     - function:       The name of the stubbed function.
    ///     - whenCalledWith: An array containing the parameters of the stubbed function call.
    ///     - return:         An array containing the values to return when the stubbed function is called.
    ///                             The last value is returned repeatedly therafter.  The default is `[]`.
    public func stub(function: String, whenCalledWith parameters: [Any] = [], return values: [Any] = []) {
        if !values.isEmpty {
            if stubbings[function] == nil {
                stubbings[function] = [getKey(for: parameters): values]
            } else {
                stubbings[function]![getKey(for: parameters)] = values
            }
        }
    }

    /// The value that has been specified for the stubbed function.
    ///
    /// - Parameters:
    ///     - forFunction:    The name of the stubbed function.
    ///     - whenCalledWith: An array containing the parameters of the stubbed function call.
    ///
    /// - Returns: The previously specified value (via `stub`) for the function call or `nil` if none was specified.
    public func value<T>(forFunction function: String, whenCalledWith parameters: [Any] = []) -> T? {
        let values = stubbings[function]?[getKey(for: parameters)] as? [T]
        if let value = values?.first {
            removeSequentialStubbing(forFunction: function, whenCalledWith: parameters)
            return getUnwrappedReturnValue(value: value)
        } else {
            return nil
        }
    }

    /// The number of invocations for the function.
    ///
    /// - Parameters:
    ///     - forFunction: The name of the invoked function.
    ///
    /// - Returns: The number of invocations of the function.
    public func invocations(forFunction function: String) -> Int {
        return invocations.filter({ $0.name == function }).count
    }

    /// Was the function was invoked?
    ///
    /// - Parameters:
    ///     - function: The name of the invoked function.
    ///
    /// - Returns: `true` if the number of invocations is one or more.
    public func invoked(function: String) -> Bool {
        return invocations(forFunction: function) > 0
    }

    /// The parameters for a function invocation.
    ///
    /// - Parameters:
    ///     - forFunction: The name of the invoked function.
    ///     - invocation: The ordinal of the invocation (1-based, default 1)
    /// - Returns: The parameters for the invocaton in an array
    public func parameters(forFunction function: String, invocation: Int = 1) -> [Any?] {
        let matchingInvocations = invocations.filter({ $0.name == function })
        guard invocation > 0 && invocation <= matchingInvocations.count else { return [] }

        return matchingInvocations[invocation - 1].parameters
    }

    /// Records that a function was invoked with the given parameters.
    ///
    /// - Parameters:
    ///     - function:      The name of the invoked function.
    ///     - wasCalledWith: An array containing the parameters of the invoked function.
    public func record(function: String, wasCalledWith parameters: [Any?] = []) {
        invocations.append(MockInvocation(name: function, parameters: parameters))
    }

    /// A description of interactions with the mocked function.
    ///
    /// - Parameter withFunction: The name of the mocked function.
    ///
    /// - Returns: A description of interactions.
    public func interactions(withFunction function: String) -> String {
        return getDescription(for: function)
    }

    // MARK: - private

    private func getKey(for parameters: [Any]) -> String {
        return "\(parameters.description)"
    }

    private func getDescription(for function: String) -> String {
        let stubbingCount = stubbings[function]?.count ?? 0
        let invocationCount = getInvocationCount(for: function)
        var summary = getDescriptionIntro(stubbings: stubbingCount, invocations: invocationCount)
        appendStubbingDescription(appendTo: &summary, function: stubbings[function])
        appendInvocationDescription(appendTo: &summary, function: function)
        return summary
    }

    private func getDescriptionIntro(stubbings: Int, invocations: Int) -> String {
        return "This function has \(stubbings) stubbing\(stubbings == 1 ? "" : "s") and \(invocations) invocation\(invocations == 1 ? "" : "s")."
    }

    private func appendStubbingDescription(appendTo: inout String, function: Dictionary<String, Any>?) {
        if function?.count ?? 0 > 0 {
            let stubbingHeading = "\n\n  Stubbings:"
            let stubbingsList = function?.reduce("") { initial, current in
                return initial + "\n  - When called with `\(current.key)`, then return `\(current.value)`."
                } ?? ""
            appendTo = appendTo + stubbingHeading + stubbingsList
        }
    }

    private func appendInvocationDescription(appendTo: inout String, function: String) {
        let invocations = self.invocations.filter({ $0.name == function })

        if invocations.count > 0 {
            let invocationHeading = "\n\n  Invocations:"
            let invocationsList = invocations.reduce("") { initial, current in
                let parameters = current.parameters.map { parameter -> String in
                    if parameter != nil {
                        return "\(parameter!)"
                    } else {
                        return "nil"
                    }
                }
                return initial + "\n  - Called with `\(parameters)`."
            }
            appendTo = appendTo + invocationHeading + invocationsList
        }
    }

    private func getInvocationCount(for function: String) -> Int {
        return invocations.filter({ $0.name == function }).count
    }

    private func removeSequentialStubbing(forFunction function: String, whenCalledWith parameters: [Any]) {
        if let array = stubbings[function]?[getKey(for: parameters)], array.count > 1 {
            stubbings[function]![getKey(for: parameters)]!.removeFirst()
        }
    }

    private func getUnwrappedReturnValue<T>(value: T) -> T? {
        if unwrap(value) != nil {
            return value
        } else {
            return nil
        }
    }

    private func unwrap(_ any: Any) -> Any? {
        let mirror = Mirror(reflecting: any)
        if mirror.displayStyle != .optional {
            return any
        }

        if mirror.children.count == 0 { return nil }
        let (_, some) = mirror.children.first!
        return some
    }
}
